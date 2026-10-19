{ config, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  loginShell = "${pkgs.bashInteractive}/bin/bash";

  # tmux-sensible sets default-command to
  # `reattach-to-user-namespace -l $SHELL` on macOS, where $SHELL is whatever
  # shell the server was started with. Override it so new panes always use
  # the Nix bash. The wrapper is kept on macOS for clipboard access; the
  # yank plugin also uses it for pbcopy.
  defaultCommand =
    if isDarwin
    then "${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l ${loginShell}"
    else loginShell;
in
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

    # Use the Nix-provided bash for new panes. Without this, tmux caches the
    # login shell the server was started with, so panes can keep opening zsh
    # (or macOS's old bash 3.2) after the account shell changes.
    shell = loginShell;

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
        #
        # The plugin expands most of these options with `set -F` while it
        # loads, so every @catppuccin_* option has to be set *before* the
        # run-shell line Home Manager emits for the plugin. That is what
        # this extraConfig is for.
        plugin = catppuccin;
        extraConfig = ''
          # v2 uses the American spelling. The old @catppuccin_flavour name
          # is silently ignored (the theme still defaults to mocha, but
          # changing flavour later would have no effect).
          set -g @catppuccin_flavor "mocha"

          # Nerd Font icons and powerline separators. The font is installed
          # through Home Manager and configured in Ghostty.
          set -g @catppuccin_window_status_style "rounded"
        '';
      }
    ];

    extraConfig = ''
      # Keep $SHELL consistent inside panes. tmux otherwise inherits the
      # server's environment from whenever it was started. default-command
      # overrides the value sensible.tmux set at server startup.
      set-environment -g SHELL "${loginShell}"
      set -g default-command "${defaultCommand}"

      # Ghostty supports 24-bit colour on both macOS and Linux, so enable it
      # unconditionally. Reset first so repeated `prefix r` reloads do not
      # append duplicate overrides.
      set -gu terminal-overrides
      set -ga terminal-overrides ",*:Tc"

      # Build the status line from Catppuccin modules instead of tmux's
      # default status-right, which shows a truncated pane title and a clock
      # (the text that seems to change at random).
      set -g status-left-length 100
      set -g status-right-length 100
      set -g status-left "#{E:@catppuccin_status_session}"
      set -g status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_date_time}"

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

      # Copy mode (vi): v select, C-v block select. Do not bind `y` here:
      # the yank plugin already binds it to copy into the macOS clipboard,
      # and a later `copy-selection-and-cancel` would override that.
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
    '';
  };
}
