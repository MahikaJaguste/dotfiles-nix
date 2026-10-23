{ config, lib, ... }:
{
  options.my.profile = lib.mkOption {
    description = "Which set of features this machine enables.";
    type = lib.types.enum [
      "full"
      "minimal"
    ];
    default = "full";
  };

  config = lib.mkMerge [
    # Every machine gets a shell, git and the CLI toolbox.
    {
      my.bash.enable = lib.mkDefault true;
      my.git.enable = lib.mkDefault true;
      my.cliTools.enable = lib.mkDefault true;
      my.fonts.enable = lib.mkDefault true;
    }

    # Interactive terminal + editor stack.
    (lib.mkIf (config.my.profile == "full") {
      my.tmux.enable = lib.mkDefault true;
      my.ghostty.enable = lib.mkDefault true;
      my.neovim.enable = lib.mkDefault true;
      my.lazygit.enable = lib.mkDefault true;
      my.worktrunk.enable = lib.mkDefault true;
      my.direnv.enable = lib.mkDefault true;
    })
  ];
}
