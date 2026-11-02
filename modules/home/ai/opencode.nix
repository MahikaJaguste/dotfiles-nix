{ config, lib, pkgs, ... }:
let
  cfg = config.my.opencode;
in
{
  options.my.opencode = {
    enable = lib.mkEnableOption "OpenCode";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.opencode;
      defaultText = lib.literalExpression "pkgs.opencode";
      description = "OpenCode package to install. Set to null to manage the binary outside Home Manager.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages added to OpenCode's PATH, for local MCP servers and tools.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Global OpenCode settings, written to
        {file}`$XDG_CONFIG_HOME/opencode/opencode.json`.

        Use this for scalar and top-level settings such as `model`,
        `default_agent`, `permissions`, `formatter`, and `instructions`.
        Prefer {option}`my.opencode.mcpServers`, {option}`my.opencode.agents`,
        {option}`my.opencode.commands`, and {option}`my.opencode.skills` for
        those resources so another module can add entries without replacing the
        whole attribute set.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        MCP servers merged into `settings.mcp.servers`. Servers are keyed by
        name, so separate modules can contribute independent servers. A module
        in a consuming flake can add a work-only server here without touching
        this repository.
      '';
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Markdown agent definitions, written to
        {file}`$XDG_CONFIG_HOME/opencode/agents/<name>.md`. Use `mode =
        "subagent"` for subagents; omit `mode` for a primary agent.
      '';
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Markdown command templates, written to
        {file}`$XDG_CONFIG_HOME/opencode/commands/<name>.md`.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.either
        (lib.types.attrsOf (lib.types.oneOf [
          lib.types.lines
          lib.types.path
          lib.types.str
        ]))
        lib.types.path;
      default = { };
      description = ''
        Global skills, written to `$XDG_CONFIG_HOME/opencode/skills/`. An
        attribute value may be inline Markdown, a `SKILL.md` path, or a
        directory containing `SKILL.md` plus supporting files. A path may be
        used instead of an attribute set to link a whole skills directory.

        Project skills still belong in the repository under
        `.opencode/skills/`; this option is for skills that should follow the
        user across every project.
      '';
    };

    context = lib.mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
        Global instructions, written to
        {file}`$XDG_CONFIG_HOME/opencode/AGENTS.md`. `lines` values from several
        modules are concatenated, so a consuming flake can append work rules.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Local plugin files or directories linked into
        `$XDG_CONFIG_HOME/opencode/plugins/`. Hooks are implemented by plugins;
        there is no separate hooks configuration key. A plugin directory needs
        an `index.ts` or `index.js` entrypoint.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.package != null) {
      assertion = lib.versionAtLeast cfg.package.version "2.0";
      message = "my.opencode requires OpenCode 2.x. Update nixpkgs or set my.opencode.package to a 2.x build.";
    };

    programs.opencode = {
      enable = true;

      inherit (cfg)
        package
        extraPackages
        agents
        commands
        skills
        context
        ;

      # Keep mcpServers separate from settings until this point so definitions
      # from several modules merge by server name instead of replacing mcp.
      settings = cfg.settings // lib.optionalAttrs (cfg.mcpServers != { }) {
        mcp = (cfg.settings.mcp or { }) // {
          servers = (cfg.settings.mcp.servers or { }) // cfg.mcpServers;
        };
      };
    };

    xdg.configFile = lib.mapAttrs' (
      name: source: lib.nameValuePair "opencode/plugins/${name}" { inherit source; }
    ) cfg.plugins;
  };
}
