{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options.my.ghostty.enable = lib.mkEnableOption "Ghostty terminal";

  config = lib.mkIf config.my.ghostty.enable {
    programs.ghostty = {
      enable = true;

      # The pinned nixpkgs builds Ghostty from source for Linux, but ships a
      # prebuilt aarch64-darwin app as `ghostty-bin`.
      package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

      settings = {
        # Bundled with Ghostty; exact Catppuccin Mocha palette and background.
        theme = "Catppuccin Mocha";

        # Installed through modules/home/meta/fonts.nix. The "Mono" variant
        # keeps icon glyphs at a single cell width.
        font-family = config.my.font.mono;
      };

      enableBashIntegration = true;

      # Don't add Ghostty syntax rules to bat unless we start managing bat.
      installBatSyntax = false;
    };

    # Home Manager installs the .app into the Nix store. Symlink it into
    # ~/Applications so it can be launched from Finder/Spotlight without
    # starting it from a terminal first.
    home.file = lib.mkIf isDarwin {
      "Applications/Ghostty.app".source =
        "${pkgs.ghostty-bin}/Applications/Ghostty.app";
    };
  };
}
