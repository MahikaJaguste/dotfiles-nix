{ # `username` is supplied per machine by flake.nix.
  username,
  config,
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  home.stateVersion = "24.05";

  imports = [
    ./modules/tmux.nix
    ./modules/git.nix
    ./modules/bash.nix
    ./modules/lazygit.nix
    ./modules/neovim.nix
    ./modules/ghostty.nix
  ];

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

    # Terminal font with icons for tmux/Catppuccin. Home Manager installs it
    # into ~/Library/Fonts on macOS and makes it visible to fontconfig on
    # Linux.
    nerd-fonts.jetbrains-mono
  ] ++ lib.optionals isDarwin [
    # macOS-specific packages
  ] ++ lib.optionals isLinux [
    # Linux-specific packages
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts.monospace = [ "JetBrainsMono Nerd Font Mono" ];
  };

  programs.home-manager.enable = true;
}
