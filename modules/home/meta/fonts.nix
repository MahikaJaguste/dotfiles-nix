{ config, lib, pkgs, ... }:
{
  options.my.font.mono = lib.mkOption {
    description = "Monospace family used by the terminal and fontconfig.";
    type = lib.types.str;
    default = "JetBrainsMono Nerd Font Mono";
  };

  options.my.fonts.enable = lib.mkEnableOption "Nerd Font and fontconfig defaults";

  config = lib.mkIf config.my.fonts.enable {
    # Home Manager installs this into ~/Library/Fonts on macOS and makes it
    # visible to fontconfig on Linux.
    home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

    fonts.fontconfig = {
      enable = true;
      defaultFonts.monospace = [ config.my.font.mono ];
    };
  };
}
