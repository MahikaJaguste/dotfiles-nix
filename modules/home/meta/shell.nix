{ lib, pkgs, ... }:
{
  options.my.shell.path = lib.mkOption {
    description = ''
      Shell used for tmux panes and exported as SHELL inside tmux. Set this to
      a system shell on hosts whose accounts come from NSS modules (sssd,
      LDAP) that Nix glibc cannot load.
    '';
    type = lib.types.str;
    default = "${pkgs.bashInteractive}/bin/bash";
  };
}
