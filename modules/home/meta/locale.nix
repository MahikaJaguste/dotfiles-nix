{ config, lib, pkgs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  options.my.locale.nixArchive.enable = lib.mkOption {
    description = ''
      Expose Nix's glibc locale archive to Nix-built programs. Without this,
      Nix glibc only knows C/C.utf8, so a LANG such as en_US.UTF-8 falls back
      to C and programs that measure multi-byte glyphs (for example tmux with
      powerline separators) misrender them.
    '';
    type = lib.types.bool;
    default = isLinux;
  };

  config = lib.mkIf (config.my.locale.nixArchive.enable && isLinux) {
    home.sessionVariables.LOCALE_ARCHIVE = lib.mkDefault "${pkgs.glibcLocales}/lib/locale/locale-archive";
  };
}
