{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    mouse = true;
    baseIndex = 1;
    historyLimit = 10000;
    escapeTime = 0;
    terminal = "tmux-256color";
    keyMode = "vi";

    # tmux-sensible defaults, applied at the top so the options below win.
    sensibleOnTop = true;

    # vi-style pane navigation (prefix h/j/k/l) and resize (prefix H/J/K/L).
    customPaneNavigationAndResize = true;

    # Match tmux-sensible: pass focus events through to apps (e.g. neovim)
    # and only resize windows that are actively displayed.
    focusEvents = true;
    aggressiveResize = true;

    plugins = with pkgs.tmuxPlugins; [
      # Copy to the macOS system clipboard from copy mode.
      yank
      {
        # Catppuccin status bar / pane theme.
        plugin = catppuccin;
        extraConfig = "set -g @catppuccin_flavour 'mocha'";
      }
    ];

    extraConfig = ''
      # True color, needed for Catppuccin hex colors.
      set -ga terminal-overrides ",*256col*:Tc"

      # Sensible splits, keeping | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Move between panes without the prefix (Alt-arrows)
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Switch windows without the prefix
      bind -n S-Left previous-window
      bind -n S-Right next-window
      bind -n M-H previous-window
      bind -n M-L next-window

      # Copy mode (vi): v select, C-v block select, y copy + exit
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
    '';
  };
}
