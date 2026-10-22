{ lib, ... }:
{
  # Shared, always-on settings. Feature modules live next to this one and gate
  # themselves on config.my.<feature>.enable.
  home.stateVersion = lib.mkDefault "24.05";

  programs.home-manager.enable = true;
}
