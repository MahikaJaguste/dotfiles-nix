{ config, lib, pkgs, ... }:
{
  options.my.cliTools.enable = lib.mkEnableOption "modern CLI utilities";

  config = lib.mkIf config.my.cliTools.enable {
    home.packages = with pkgs; [
      # Core utilities
      ripgrep
      fd
      fzf
      eza
      bat
      jq
      wget
      curl
      tree
      btop
      unzip
      zip
      git
      gh
    ];
  };
}
