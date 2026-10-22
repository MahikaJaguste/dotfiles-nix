{
  inputs,
  lib,
  config,
  ...
}:
let
  # Build a home configuration for one machine. Everything that differs per
  # machine — platform, username, profile — lives in the host module.
  mkHome =
    host:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${host.system};

      extraSpecialArgs = {
        inherit (host) username;
        inherit inputs;
      };

      modules = [
        # The LazyVim module is external, so import it explicitly. The home
        # tree only configures programs.lazyvim when my.neovim.enable is set.
        inputs.lazyvim.homeManagerModules.default

        # Every file under modules/home is a module; none are listed by hand.
        (inputs.import-tree ../home)

        # Host identity, injected here so modules/home/ stays user-agnostic.
        ({ pkgs, ... }: {
          home.username = host.username;
          home.homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${host.username}" else "/home/${host.username}";
        })

        # Which subset of the home modules this machine turns on.
        { my.profile = host.profile; }
      ];
    };
in
{
  options.my.hosts = lib.mkOption {
    description = "Machines exposed as flake homeConfigurations.<name>.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          system = lib.mkOption {
            type = lib.types.str;
            example = "aarch64-darwin";
          };
          username = lib.mkOption { type = lib.types.str; };
          profile = lib.mkOption {
            description = "Feature set enabled on this machine.";
            type = lib.types.enum [
              "full"
              "minimal"
            ];
            default = "full";
          };
        };
      }
    );
    default = { };
  };

  config.flake.homeConfigurations = lib.mapAttrs (_: mkHome) config.my.hosts;
}
