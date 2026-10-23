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
      my = {
        bash.enable = lib.mkDefault true;
        git.enable = lib.mkDefault true;
        cliTools.enable = lib.mkDefault true;
        fonts.enable = lib.mkDefault true;
      };
    }

    # Interactive terminal + editor stack.
    (lib.mkIf (config.my.profile == "full") {
      my = {
        tmux.enable = lib.mkDefault true;
        ghostty.enable = lib.mkDefault true;
        neovim.enable = lib.mkDefault true;
        lazygit.enable = lib.mkDefault true;
        worktrunk.enable = lib.mkDefault true;
        direnv.enable = lib.mkDefault true;
      };
    })
  ];
}
