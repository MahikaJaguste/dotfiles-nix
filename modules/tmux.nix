{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    baseIndex = 1;
    historyLimit = 10000;
    escapeTime = 0;
    terminal = "screen-256color";
    keyMode = "vi";
    extraConfig = ''
      # Sensible splits
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Reload config
      bind r source-file ~/.tmux.conf \; display "Config reloaded!"

      # Status bar
      set -g status-style "bg=colour235,fg=colour136"
      set -g status-left "#[fg=colour235,bg=colour136] #S "
      set -g status-right "#[fg=colour136,bg=colour235] %Y-%m-%d %H:%M "
      set -g status-left-length 30
      set -g status-right-length 50

      # Window status
      setw -g window-status-format " #I:#W "
      setw -g window-status-current-format "#[fg=colour235,bg=colour33] #I:#W "

      # Pane borders
      set -g pane-border-style "fg=colour235"
      set -g pane-active-border-style "fg=colour33"
    '';
  };
}
