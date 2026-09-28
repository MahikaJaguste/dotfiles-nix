{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Mahika Jaguste";
    userEmail = "mahika@example.com"; # TODO: replace with real email
    extraConfig = {
      init.defaultBranch = "main";
      color.ui = "auto";
      core.editor = "nvim";
      core.autocrlf = "input";
      pull.rebase = false;
      diff.colorMoved = "default";
    };
    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      lg = "log --oneline --graph --decorate --all";
      last = "log -1 HEAD";
      unstage = "reset HEAD --";
    };
  };
}
