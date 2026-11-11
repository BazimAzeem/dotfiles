#!/usr/bin/env bash
# Takes a fresh Mac (nix-darwin) or Linux machine (standalone Home Manager) from
# nothing to a built config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Which flake.nix username line and flake host label this machine uses.
OS="$(uname -s)"
case "$OS" in
  Darwin) USER_VAR="user"; HOST="mac" ;;
  Linux) USER_VAR="linuxUser"; HOST="linux" ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

# BSD sed (macOS) needs an explicit empty suffix after -i; GNU sed (Linux) must not get one.
sed_inplace() {
  if [ "$OS" = "Darwin" ]; then sed -i '' "$@"; else sed -i "$@"; fi
}

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: personalize the configured username"
# Do this before any sudo call: sudo resets $USER to root, so whoami has to
# run as the real interactive user first.
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE "s/^[[:space:]]*${USER_VAR} = \"([^\"]+)\";.*/\1/p" "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the single \"${USER_VAR} = \" line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's \"${USER_VAR} = \" line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed_inplace -E "s/^([[:space:]]*${USER_VAR} = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the single \"${USER_VAR} = \" line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

# sudo resets PATH to a secure default that excludes /nix/.../bin, so a
# freshly installed `nix` would not be found under sudo even though it's
# on PATH here. Resolve the absolute path first and invoke that instead.
NIX_BIN="$(command -v nix)"

if [ "$OS" = "Darwin" ]; then
  echo "==> Step 4: first darwin-rebuild switch (pinned to nix-darwin-26.05)"
  # darwin-rebuild doesn't exist yet on a fresh machine, so run it straight
  # from the flake this once. After this, rebuild.sh works normally.
  # This fetches the darwin-rebuild tool from the nix-darwin-26.05 release branch,
  # not the exact flake.lock revision. The system config it applies is still pinned
  # by this repo's flake.lock.
  # "mac" is the flake host label - if you renamed it, change it in flake.nix
  # and rebuild.sh too.
  sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake ~/.dotfiles#"$HOST"
else
  echo "==> Step 4: first home-manager switch (pinned to release-26.05)"
  # home-manager doesn't exist yet on a fresh machine, so run it straight from
  # its release branch this once; the config it applies is pinned by flake.lock.
  # It runs as you, no sudo. -b backup moves files already in the way (for example
  # an existing ~/.claude/settings.json or ~/.config/herdr) to <name>.backup.
  # "linux" is the flake host label - if you renamed it, change it in flake.nix
  # and rebuild.sh too.
  "$NIX_BIN" run github:nix-community/home-manager/release-26.05 -- \
    switch --flake ~/.dotfiles#"$HOST" -b backup
fi
# If this still fails with "nix: command not found", open a new terminal
# (Determinate adds nix to new shells' PATH) and re-run ./bootstrap.sh.

echo "==> Done. Use ./rebuild.sh for future changes."
