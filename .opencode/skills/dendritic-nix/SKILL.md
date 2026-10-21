---
name: Dendritic Nix Flake
description: Maintain and extend this repository's dendritic Nix flake (flake-parts + import-tree + Home Manager). Use when adding or changing a tool, feature module, host, profile, input, package, or Home Manager setting, and when debugging module evaluation, `nix flake check`, or `home-manager build`.
---

# Dendritic Nix Flake

This repo manages one user's dev environment (bash, git, tmux, LazyVim, lazygit,
Ghostty, CLI tools) with Home Manager, structured as a **dendritic flake**.

## The three rules

1. **Every file under `modules/` is a module.** Nothing else belongs there.
2. **Modules are discovered, not imported.** `import-tree` recursively imports
   every `.nix` file. There is no import list anywhere.
3. **Modules communicate only through the module system** (`options` + `config`),
   never through `import ./other.nix`.

Consequence: directory names are documentation only. Moving a module between
groups changes nothing at evaluation time.

## Layout

```text
flake.nix                     # inputs + mkFlake(import-tree ./modules/flake)
flake.lock
modules/
├── flake/                    # flake-parts modules (the flake's outputs)
│   ├── systems.nix           # systems = [...]
│   ├── hosts.nix             # options.my.hosts -> flake.homeConfigurations
│   └── hosts/mj.nix          # one file per machine
└── home/                     # Home Manager modules (the user environment)
    ├── base.nix              # home.stateVersion, programs.home-manager.enable
    ├── profiles.nix          # my.profile -> which my.*.enable flags are on
    ├── meta/fonts.nix        # my.font.mono, Nerd Font, fontconfig
    ├── shell/bash.nix
    ├── dev/git.nix
    ├── dev/cli-tools.nix
    ├── terminal/tmux.nix
    ├── terminal/ghostty.nix
    ├── editors/neovim.nix
    └── editors/lazygit.nix
```

`lib/` (repo root, create it if needed) is for pure helper functions. Never put
helpers in `modules/` — they would be evaluated as modules.

## Wiring, end to end

`flake.nix`:

```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules/flake);
```

`modules/flake/hosts.nix` declares `options.my.hosts`, then builds one
`homeManagerConfiguration` per host:

- `pkgs = inputs.nixpkgs.legacyPackages.${host.system}`
- `extraSpecialArgs = { username; inputs; lazyvim; }` — so every home module can
  use `inputs.<name>` and `lazyvim`, and `username` for identity only
- `modules = [ (inputs.import-tree ../home) <identity module> { my.profile = host.profile; } ]`

There are **two separate module systems** sharing a `my.` prefix:

| Namespace | Lives in | Examples |
| --- | --- | --- |
| flake-parts | `modules/flake/` | `my.hosts.mj.system`, `my.hosts.mj.profile` |
| Home Manager | `modules/home/` | `my.profile`, `my.tmux.enable`, `my.font.mono` |

They never reference each other. A host's `profile` is copied into the home
configuration as `my.profile` by `hosts.nix`. Do not try to read
`config.my.hosts` from a home module or `config.my.tmux` from a flake module.

## Invariants

1. **Do not add `imports` entries for files under `modules/`.** They are already
   imported by `import-tree`; a second import evaluates the module twice and can
   duplicate list values or cause infinite recursion.
2. **`imports` is allowed only** for external modules (`lazyvim.homeManagerModules.default`)
   and inside `flake.nix` for the `modules/flake` bootstrap. It must stay at the
   top level of the module, never inside `config = lib.mkIf ...`.
3. **Every feature gates itself** on `options.my.<feature>.enable` and wraps all
   of its config in `lib.mkIf config.my.<feature>.enable`.
4. **Modules are pure.** No `import ./x.nix`, no `builtins.getEnv`, no reading
   files at eval time. Share values by declaring an option.
5. **No behaviour changes while refactoring.** Verify with `home-manager build`
   and compare against the active generation (commands below).

## Standard module shape

```nix
{ config, lib, pkgs, ... }:
{
  options.my.mytool.enable = lib.mkEnableOption "mytool configuration";

  config = lib.mkIf config.my.mytool.enable {
    programs.mytool = {
      enable = true;
      # ... settings
    };
  };
}
```

Naming: `my.<camelCaseFeature>.enable` (`my.cliTools`, not `my.cli-tools`).
Nested data uses dotted options (`my.font.mono`).

## Recipes

### Add a tool or feature

1. Pick the group: `shell/`, `dev/`, `terminal/`, `editors/`, or `meta/`.
   A new group directory is fine — discovery is recursive.
2. Create `modules/home/<group>/<tool>.nix` in the standard shape above.
   Include the package in the same file (`home.packages = [ pkgs.foo ];` or
   `programs.foo.package`), so the feature is self-contained.
3. Enable it in `modules/home/profiles.nix` under the `always on` block or the
   `full` profile block. To enable it on exactly one machine instead, set
   `my.<feature>.enable = true;` in that host's flake module.
4. Verify, then (only if asked) switch.

### Add a machine

Create `modules/flake/hosts/<name>.nix`:

```nix
{
  my.hosts.<name> = {
    system = "x86_64-linux";
    username = "mahika";
    profile = "full"; # or "minimal"
  };
}
```

No other file changes. `home.username` and `home.homeDirectory` are derived
(`/Users/<user>` on Darwin, `/home/<user>` elsewhere).

### Add a profile

Two edits, because the enum is declared twice:

1. `modules/home/profiles.nix` → add the name to `options.my.profile.type`
   (`lib.types.enum`) and decide the flags for it.
2. `modules/flake/hosts.nix` → add the name to the `profile` submodule's
   `lib.types.enum`, or the host option will reject it.

Then set `profile = "<name>";` in the host file.

### Share a value between modules

Declare an option in `modules/home/meta/`, give it a default, and read it as
`config.my.<...>` elsewhere. Example: `my.font.mono` is consumed by
`terminal/ghostty.nix` and `meta/fonts.nix`. Never hardcode the same string in
two modules.

### Add a flake output or package

Create a module in `modules/flake/`, e.g.:

```nix
{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.hello = pkgs.hello;
  };
}
```

`perSystem` requires the system to be listed in `modules/flake/systems.nix`.
Arbitrary flake outputs go under `flake.<attrpath>`; `flake.homeConfigurations`
is already owned by `modules/flake/hosts.nix`. Add a formatter or checks the same
way (`perSystem.formatter`, `perSystem.checks`).

### Add another module tree (nix-darwin, NixOS)

1. Add the input in `flake.nix`.
2. Create `modules/darwin/` and/or `modules/nixos/` with their modules.
3. In a `modules/flake/` module, set `flake.darwinConfigurations.<name>` /
   `flake.nixosConfigurations.<name>`, importing `(inputs.import-tree ../darwin)`
   or `../nixos` and reusing `modules/home` for the user layer.
4. No existing file needs to change shape.

### Move, rename, or delete a module

- Move/rename: just `git mv`. Do not edit imports anywhere.
- Delete a feature: delete the file and remove its `my.<feature>.enable` line
  from `profiles.nix`. If another module reads an option the file declared
  (anything other than `.enable`), move the option declaration to `meta/` or
  update the consumers first.

### Add an input

Add it under `inputs` in `flake.nix`, run `nix flake lock`, then read it as
`inputs.<name>` in a `modules/flake/` module. Home Manager modules also receive
all inputs through `extraSpecialArgs`, so `inputs.<name>` works there too.

## Verify before claiming success

```bash
git add -A   # flakes only see git-tracked files; new files must be staged
nix flake show
nix flake check --no-build
nix eval .#homeConfigurations.mj.config.my --json
nix run nixpkgs#home-manager -- build --flake .#mj
```

`home-manager build` writes `./result` (gitignored). To prove a refactor did not
change behaviour, diff against the active generation:

```bash
current=$(readlink -f ~/.local/state/nix/profiles/home-manager)
diff <(cd result/home-files && find . | sort) \
     <(cd "$current/home-files" && find . | sort)
diff result/home-files/.bashrc "$current/home-files/.bashrc"
diff result/home-files/.config/tmux/tmux.conf "$current/home-files/.config/tmux/tmux.conf"
```

Apply only when the user asks:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mj
```

Inspect an option:

```bash
nix repl .#homeConfigurations.mj
# then: config.my.tmux.enable
#       config.programs.tmux.shell
```

## Pitfalls

- **Untracked files are invisible to flakes.** A new module fails with
  `Path '...' is not tracked by Git` until staged.
- **Every home module is imported by every host.** A Linux-only package or
  `pkgs.<darwin-only>` reference at module top level breaks macOS evaluation.
  Keep platform-specific values inside `lib.mkIf` / `lib.optionals`, as
  `ghostty.nix` and `tmux.nix` do.
- **`import-tree` ignores paths containing `/_`** (and hidden paths). Don't
  rely on that; use `lib/` for non-modules.
- **`nix flake check` does not build `homeConfigurations`.** It type-checks
  outputs only. Always run `home-manager build` for real verification.
- **`--all-systems` is off by default**, so `nix flake check` skips the Linux
  hosts on a Mac.
- **Infinite recursion** usually means a module reads
  `config.my.<itself>.enable` while computing an option value. Read `config` in
  the `config =` attribute only, not in `options`.
- **`home.file` merges as an attrset.** Use `lib.mkIf` inside it; do not assign
  `home.file = { ... };` from two branches without `mkMerge`.
- **Never edit generated files** (`~/.config/nvim`, `~/.config/tmux/tmux.conf`,
  `~/.bashrc`). Edit the module and rebuild.
- **Never use `:LazyExtras` or Mason** to add Neovim support. Add a LazyVim
  extra in `editors/neovim.nix` and put the binary in
  `programs.lazyvim.extraPackages`.
- **`home.stateVersion` is not a changelog.** Do not bump it unless the user
  explicitly asks; it pins migration behaviour.
- **Secrets** do not belong in these modules. There is no sops/agenix setup;
  propose one before adding plaintext credentials.
- **`import-tree` upstream moved** from `github:vic/import-tree` to
  `github:denful/import-tree`; keep the `denful` URL.

## Current inventory

Hosts: `mj` (aarch64-darwin, user `mahikajaguste`, profile `full`).

| Feature flag | File |
| --- | --- |
| `my.bash.enable` | `modules/home/shell/bash.nix` |
| `my.git.enable` | `modules/home/dev/git.nix` |
| `my.cliTools.enable` | `modules/home/dev/cli-tools.nix` |
| `my.fonts.enable`, `my.font.mono` | `modules/home/meta/fonts.nix` |
| `my.tmux.enable` | `modules/home/terminal/tmux.nix` |
| `my.ghostty.enable` | `modules/home/terminal/ghostty.nix` |
| `my.neovim.enable` | `modules/home/editors/neovim.nix` |
| `my.lazygit.enable` | `modules/home/editors/lazygit.nix` |

Profiles: `minimal` = bash + git + CLI tools + fonts; `full` = minimal + tmux +
ghostty + neovim + lazygit.

Inputs: `nixpkgs` (unstable), `home-manager`, `lazyvim`, `flake-parts`,
`import-tree`.

## Style

- 2-space indent, `nixfmt`-compatible (trailing semicolons, one attr per line
  when long).
- One concern per file; split a module past ~200 lines by concern
  (`editors/neovim/lsp.nix`, `editors/neovim/lang-rust.nix`).
- Comments explain *why* (platform quirks, upstream bugs), not *what*. Keep the
  existing platform notes when moving code.
- Give every new option a `description`; `nix flake check` and
  `home-manager option` surface it.
