{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      # Build a home configuration for one machine. Everything that differs
      # per machine — platform and username — lives in the entry.
      mkHome = { system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit username; };
          modules = [
            ./home.nix
            ({ pkgs, ... }: {
              home.username = username;
              home.homeDirectory =
                if pkgs.stdenv.hostPlatform.isDarwin
                then "/Users/${username}"
                else "/home/${username}";
            })
          ];
        };
    in
    {
      homeConfigurations = {
        # MacBook Pro (Apple Silicon)
        mj = mkHome {
          system = "aarch64-darwin";
          username = "mahikajaguste";
        };

        # Example: add more machines as their own entries.
        # linux-laptop = mkHome {
        #   system = "x86_64-linux";
        #   username = "mahika";
        # };
        # linux-test = mkHome {
        #   system = "x86_64-linux";
        #   username = "mtest";
        # };
      };
    };
}
