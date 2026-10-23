{ config, lib, pkgs, ... }:
let
  cfg = config.my.worktrunk;

  # User-level settings only. Hooks and dev-server URLs belong in each
  # project's .config/wt.toml.
  settings = lib.recursiveUpdate {
    "worktree-path" = cfg.worktreePath;

    # The bash wrapper below already provides shell integration, so do not let
    # the first run offer to edit the generated .bashrc.
    "skip-shell-integration-prompt" = true;

    list.json-schema = 2;

    # Never copy Nix result symlinks or machine-specific virtualenvs into a
    # new worktree. Other ignored files, including node_modules and target,
    # are still copied when a project opts into wt step copy-ignored.
    step."copy-ignored".exclude = [
      "result"
      "result-*"
      ".direnv/"
      ".venv/"
      "venv/"
      ".tox/"
    ];
  } cfg.settings;
in
{
  options.my.worktrunk = {
    enable = lib.mkEnableOption "Worktrunk git worktree manager";

    worktreePath = lib.mkOption {
      description = "Template used for new worktree paths.";
      type = lib.types.str;
      default = "{{ repo_path }}/../{{ repo }}.worktrees/{{ branch | sanitize }}";
    };

    settings = lib.mkOption {
      description = "Additional Worktrunk user configuration.";
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.worktrunk ];

    xdg.configFile."worktrunk/config.toml".source =
      (pkgs.formats.toml { }).generate "worktrunk-config.toml" settings;

    # wt switch only changes directory when the shell wrapper is loaded. Do
    # not run `wt config shell install`: it would edit the generated .bashrc.
    programs.bash.initExtra = lib.mkIf config.my.bash.enable ''
      eval "$(wt config shell init bash)"
    '';
  };
}
