{ config, lib, ... }:
{
  options.my.direnv.enable = lib.mkEnableOption "direnv with nix-direnv";

  config = lib.mkIf config.my.direnv.enable {
    programs.direnv = {
      enable = true;

      # Provides `use flake`, with a persistent evaluation cache.
      nix-direnv.enable = true;

      # The shell tree only manages bash. Its initExtra is merged with the
      # Worktrunk wrapper and the prompt already configured there.
      enableBashIntegration = true;

      # Keep .direnv/ out of repositories without editing each .gitignore.
      enableGitIntegration = true;
    };
  };
}
