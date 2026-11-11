{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  inherit (pkgs.stdenv) isDarwin isLinux;
in

{
  home.username = user;
  home.homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
  ] ++ lib.optionals isDarwin [
    # the font everything renders in (Linux machines are used over SSH from the Mac)
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = isDarwin;
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    # Emacs keys, not vi mode (which zsh picks because EDITOR=nvim). WezTerm maps
    # macOS text navigation (Option/Cmd + arrows/Delete) onto these readline keys.
    defaultKeymap = "emacs";
    # Ctrl+U (Cmd+Delete) deletes to line start like macOS, not the whole line.
    initContent = ''
      bindkey '^U' backward-kill-line

      # Machine-local env and secrets; never tracked in this public repo.
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local
    '';
  };

  # Linux machines run standalone Home Manager on a non-NixOS distro.
  targets.genericLinux = lib.mkIf isLinux {
    enable = true;
    gpu.enable = false;  # headless VM, no GPU drivers to wire up
  };
  programs.home-manager.enable = isLinux;  # the home-manager command rebuild.sh uses
  home.sessionPath = lib.optionals isLinux [ "$HOME/.local/bin" ];  # native claude and herdr installs
  programs.direnv.enable = isLinux;

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "❯";
        error_symbol = "❯";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  # WezTerm runs on the Mac; Linux machines are reached through it over SSH.
  home.file.".config/wezterm" = lib.mkIf isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  };
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/statusline-command.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/statusline-command.sh";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
