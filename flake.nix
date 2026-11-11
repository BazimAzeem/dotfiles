{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Linux machines (standalone Home Manager) use the NixOS release channel,
    # which is built and cached for x86_64-linux.
    nixpkgs-linux.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs, nixpkgs-linux }:
    let
      # The one username line to change if this isn't your machine.
      # bootstrap.sh offers to rewrite this for you if your macOS username differs.
      user = "bazim";
      # The username on Linux machines, which only get home.nix (no nix-darwin).
      # bootstrap.sh offers to rewrite this for you if your Linux username differs.
      linuxUser = "bazeem3_whova_com";
    in
    {
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home.nix;
          }
        ];
      };

      homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs-linux {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = { user = linuxUser; };
        modules = [ ./home.nix ];
      };
    };
}
