{ config, lib, ... }:
{
  options.my.lazygit.enable = lib.mkEnableOption "lazygit configuration";

  config = lib.mkIf config.my.lazygit.enable {
    programs.lazygit = {
      enable = true;

      settings = {
        os = {
          # Open files in the running Neovim when lazygit was started from it,
          # otherwise suspend lazygit and start a new Neovim.
          editPreset = "nvim-remote";
        };

        keybinding.universal = {
          # `o` (openFile) launches the default GUI app and cannot suspend the
          # terminal, so it cannot start a TUI. Bind `o` to edit as well, which
          # suspends when needed, and move the OS-open action out of the way.
          edit = [
            "e"
            "o"
          ];
          openFile = "<disabled>";
        };
      };
    };
  };
}
