---
name: Nix Repository Structure
description: Use when adding, changing, moving, or debugging anything in this Nix repository. Explains the dendritic flake layout (flake-parts + import-tree + Home Manager), where files belong, the conventions to follow, and how to verify a change.
---

# Nix Repository Structure

This repository manages a user's dev environment with Nix, structured
dendritically: the configuration is split into small, self-registering modules
instead of one central file with import lists. Read this before adding files or
changing wiring.

Do not treat this document as an inventory of the repo. Hosts, features, and
options change; discover the current state with the commands under
[Orienting](#orienting). Keep this file about rules and structure.

## Concept

- **`flake.nix` is only a bootstrap.** It declares inputs and hands control to
  `flake-parts`, which discovers everything under `modules/flake/`.
- **`modules/flake/`** is the flake-level module tree (`flake-parts`). It
  declares hosts and any flake outputs (`flake.*`, `perSystem`).
- **`modules/home/`** is the Home Manager module tree. Every host consumes
  `flake.homeModules.default`, the same bundle another flake can import, so
  local hosts and consumers cannot drift.
- **Discovery replaces imports.** `import-tree` recursively imports every `.nix`
  file under those directories. There is no import list to update.
- **Directory names are documentation.** Because discovery is recursive, moving
  a module between groups does not change behaviour.
- **`my.hosts.*` and `my.*` are different namespaces.** The first belongs to
  `flake-parts` (host definitions); the second belongs to Home Manager
  (profiles, features, shared values). They never reference each other; a host's
  profile is copied into the home configuration under `my.profile`.

## Rules

1. Every file under `modules/` is a module. Nothing else goes there.
2. Do not add `imports` entries for files under `modules/`. They are already
   imported; a second import evaluates them twice.
3. `imports` is only for external modules and for the `flake.nix` bootstrap, and
   must stay at the top level of a module — never inside `config = lib.mkIf`.
4. Cross-module data flows through options (`config.my.*`), never through
   `import ./other.nix`. If two modules need the same value, declare an option
   with a default.
5. Every feature module declares `options.my.<feature>.enable` and wraps its
   entire config in `lib.mkIf config.my.<feature>.enable`.
6. Modules are pure: no file reads, no `builtins.getEnv`, no evaluation-time
   side effects.
7. Pure helpers belong in a top-level `lib/`, not in `modules/`.
8. Refactors must not change behaviour. Verify by building and diffing against
   the active generation.
9. Defaults that a consuming flake may override use `lib.mkDefault`. Profile
   flags and shared values such as `home.stateVersion` must not be hard-set.
10. Import external flake modules at the flake boundary (`modules/flake/`), not
    from `modules/home/`, when the home tree configures them. Include them in
    the exported `homeModules.default` bundle, and have hosts consume that
    bundle rather than rebuilding the module list. This keeps the home tree
    free of special-argument requirements and avoids import-time recursion.

## Module shape

```nix
{ config, lib, pkgs, ... }:
{
  options.my.mytool.enable = lib.mkEnableOption "mytool configuration";

  config = lib.mkIf config.my.mytool.enable {
    programs.mytool.enable = true;
    # ... settings, packages, files for this feature only
  };
}
```

Option naming: `my.<camelCaseFeature>.enable`; nested values use dotted options
(`my.font.mono`). Give new options a `description`.

## Where things go

| You are adding | Put it in |
| --- | --- |
| A shell feature (runs inside the session) | `modules/home/shell/<tool>.nix` |
| A terminal emulator or multiplexer | `modules/home/terminal/<tool>.nix` |
| An interactive editor | `modules/home/editor/<tool>.nix` |
| A git workflow tool | `modules/home/git/<tool>.nix` |
| Packages with no configuration of their own | `modules/home/packages/<name>.nix` |
| A value used by several modules | an option in `modules/home/meta/` |
| Which features a machine enables | `modules/home/profiles.nix` |
| A machine | `modules/flake/hosts/<name>.nix` |
| A package or app this flake provides | `modules/flake/packages/<name>.nix` |
| A flake output, formatter, check | `modules/flake/` |
| A reusable Home Manager bundle for another flake | `flake.homeModules.default` in `modules/flake/home-modules.nix` |
| A pure helper function | `lib/` (create it) |
| An external flake module | `modules/flake/` (host build or exported bundle), top-level `imports`, with a comment saying why |

Groups describe **what owns the configuration**, not where a tool happens to be
used: a tool with a config belongs to the group that owns that config (lazygit
is a git tool even though it opens Neovim), a bare package set belongs in
`packages/`, and cross-cutting values belong in `meta/`. Do not create a group
for a single file; add one only when a family has several.

## Extending

**Feature or tool.** Create one self-contained file in the matching group
(see the table; use an existing group rather than inventing one). Enable it in
`profiles.nix`, or set `my.<feature>.enable = true;` in a single host module.
Keep the package and its config together.

**Host.** Add a file under `modules/flake/hosts/` setting
`my.hosts.<name> = { system; username; profile; }`. No other file changes.

**Profile.** The profile name is declared as an enum in two places: the
`my.profile` option in `profiles.nix` and the host submodule in
`flake/hosts/default.nix`. Update both, then decide the feature flags in
`profiles.nix`.

**Move or rename.** Just move the file; do not touch imports. **Delete.** Remove
the file and its enable flag. If it declared options other modules read, move
those declarations to `meta/` or update the consumers first.

**Input.** Add it to `flake.nix`, lock it, then read `inputs.<name>` in a flake
module. Use `extraSpecialArgs` for values, not for external modules: Home
Manager resolves `imports` before special args. Import an external Home Manager
module at the flake boundary and include it in the exported bundle.

**Reuse from another flake.** Export the home tree as
`flake.homeModules.default` from `modules/flake/`. Include external Home
Manager modules in that bundle so consumers do not need to pass special
arguments, and have `mkHome` consume the same bundle. A consumer imports
`inputs.<name>.homeModules.default`, sets
`my.profile`, and overrides feature flags or `home.stateVersion` with normal
definitions; those defaults are `lib.mkDefault` here. It must still set
`home.username` and `home.homeDirectory`. Do not import
`modules/flake/hosts/default.nix` from the consumer — that would create this
flake's personal hosts there.

**New tree (nix-darwin, NixOS).** Create `modules/darwin/` or `modules/nixos/`,
add a flake module that sets `flake.darwinConfigurations` /
`flake.nixosConfigurations`, and reuse `modules/home` for the user layer. No
existing file needs to change shape.

**Neovim plugin option.** `programs.lazyvim.plugins.<name>` becomes
`lua/plugins/<name>.lua` and must return a lazy.nvim spec. Setting `opts` merges
with LazyVim's defaults.

## Verify

```bash
git add -A                    # flakes only see tracked files
nix flake show
nix flake check --no-build
nix run nixpkgs#home-manager -- build --flake .#<host>
```

`nix flake check` type-checks outputs but does not build home configurations;
always build for real verification. To prove a refactor is behaviour-preserving,
Diff `result/home-files` against the active generation
(`~/.local/state/nix/profiles/home-manager`).

Apply only when the user asks: `... switch --flake .#<host>`.

## Pitfalls

- New files are invisible to flakes until `git add`ed.
- Every home module is imported by every host. A platform-specific package or
  reference at module top level breaks evaluation on other systems; keep it
  inside `mkIf`/`optionals`.
- `nix flake check` skips non-current systems unless `--all-systems` is passed.
- Infinite recursion usually means a module reads its own
  `config.my.<feature>.enable` while computing an option value; read `config`
  only in the `config =` attribute.
- `home.file` merges as an attrset; use `lib.mkIf`/`mkMerge` rather than two
  conflicting assignments.
- Never edit generated files (`~/.config/nvim`, `~/.config/tmux/tmux.conf`,
  `~/.bashrc`); edit the module and rebuild.
- Do not add Neovim support through `:LazyExtras` or Mason; add a LazyVim extra
  and put the binary in `extraPackages`.
- Do not bump `home.stateVersion` as part of unrelated work.
- Hard-setting a feature flag or `home.stateVersion` prevents a consuming flake
  from overriding it. Use `lib.mkDefault` for defaults.
- Importing an external Home Manager module from `modules/home` when it needs a
  special argument causes infinite recursion. Import it in `modules/flake/`.
- The exported `homeModules.default` must include external modules the home
  tree configures; otherwise consumers enable a feature whose options are
  missing.
- Do not add plaintext secrets; there is no secret-management setup.

## Orienting

```bash
find modules -name '*.nix' | sort          # modules present
rg 'mkEnableOption' modules/home           # features and their flags
rg 'my\.' modules/flake                    # host wiring
nix eval .#homeConfigurations.<host>.config.my --json
nix flake show                             # hosts and outputs
```

`nix repl .#homeConfigurations.<host>` is the fastest way to inspect a value
(`config.programs.tmux.shell`, `config.my.<feature>.enable`).

## Style

- 2-space indent, nixfmt-compatible.
- One concern per file; split past roughly 200 lines by concern.
- Comments explain *why* (platform quirks, upstream behaviour), not *what*.
- Keep option names and file names aligned so the repo stays greppable.
