#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
case "$(uname -s)" in
  Darwin) exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac ;;
  Linux) exec home-manager switch --flake ~/.dotfiles#linux ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
