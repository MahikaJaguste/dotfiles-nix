{ config, lib, ... }:
{
  options.my.git.enable = lib.mkEnableOption "git configuration";

  config = lib.mkIf config.my.git.enable {
    programs.git = {
      enable = true;
      settings = {
        user.name = "Mahika Jaguste";
        user.email = "mahika.for.me@gmail.com";
        init.defaultBranch = "main";
        color.ui = "auto";
        core.editor = "nvim";
        core.autocrlf = "input";
        pull.rebase = false;
        diff.colorMoved = "default";
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          lg = "log --oneline --graph --decorate --all";
          last = "log -1 HEAD";
          unstage = "reset HEAD --";
        };
      };
    };
  };
}
