  { user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";          # dark mode
      AppleShowAllExtensions = true;         # file extensions
      InitialKeyRepeat = 15;                 # short delay before repeat
      KeyRepeat = 2;                         # fast key repeat
    };

    dock.tilesize = 40;                    # dock icon size
    dock.show-recents = false;             # recent/suggestions in dock
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.ShowPathbar = true;             # path bar at bottom of windows
    finder.NewWindowTarget = "Home";       # new windows open to Home
    trackpad.Clicking = true;              # tap to click
    menuExtraClock.ShowSeconds = true;     # show seconds in menu bar clock
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;  # take over a pre-existing /opt/homebrew install
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
    ];
    casks = [
      "maccy"
      "wezterm"
      "claude-code"
      "google-chrome"
      "whatsapp"
    ];
  };
}
