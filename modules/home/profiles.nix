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
      my.bash.enable = true;
      my.git.enable = true;
      my.cliTools.enable = true;
      my.fonts.enable = true;
    }

    # Interactive terminal + editor stack.
    (lib.mkIf (config.my.profile == "full") {
      my.tmux.enable = true;
      my.ghostty.enable = true;
      my.neovim.enable = true;
      my.lazygit.enable = true;
    })
  ];
}
