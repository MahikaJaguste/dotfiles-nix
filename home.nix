{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.username = "mahikajaguste";
  home.homeDirectory = if isDarwin then "/Users/mahikajaguste" else "/home/mahikajaguste";
  home.stateVersion = "24.05";

  imports = [
    ./modules/tmux.nix
    ./modules/git.nix
    ./modules/bash.nix
    ./modules/lazygit.nix
    ./modules/neovim.nix
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
  ] ++ lib.optionals isDarwin [
    # macOS-specific packages
  ] ++ lib.optionals isLinux [
    # Linux-specific packages
  ];

  programs.home-manager.enable = true;
}
