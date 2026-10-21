# AGENTS.md

## What this repository is

A Nix flake that builds one user's development environment with Home Manager:
bash, git, tmux, Neovim/LazyVim, lazygit, Ghostty and CLI tools. There is no
application code and no test suite — the product is the evaluated home
configuration.

## Why it is shaped this way

- **Reproducible.** Every tool, plugin and setting is pinned in `flake.lock` and
  applied in one command. Nothing is installed or edited by hand.
- **Declarative.** `~/.config/nvim`, `~/.bashrc`, `~/.config/tmux/tmux.conf` and
  the rest are generated. Edit the Nix module, never the generated file.
- **Dendritic.** The config is split into small, self-registering modules rather
  than one large `home.nix`, so a feature is one file and machines differ only
  by a host module and a profile.

## Architecture in one minute

- `flake.nix` declares inputs and hands control to `flake-parts`.
- `modules/flake/` is the flake-level tree: hosts and flake outputs.
- `modules/home/` is the Home Manager tree, grouped by area.
- `import-tree` discovers every `.nix` file. There are no import lists.
- Hosts live in `modules/flake/hosts/<name>.nix` and pick a profile.
- `modules/home/profiles.nix` maps a profile to `my.<feature>.enable` flags.

Details, recipes and pitfalls: `.opencode/skills/nix-repo-structure/SKILL.md`.
Load that skill before changing the flake or adding modules.

## Commands

Replace `mj` with the host name (`nix flake show` lists the available ones).

```bash
nix run nixpkgs#home-manager -- build --flake .#mj    # verify
nix run nixpkgs#home-manager -- switch --flake .#mj   # apply
nix flake check --no-build                            # type-check outputs
nix flake update                                      # bump inputs
```

Switch only when the user asks; build and report first.

## Ground rules

- Every file under `modules/` is a module. Do not add `imports` entries for it.
- Features gate themselves on `options.my.<feature>.enable` with `lib.mkIf`.
- Share data through options, not `import ./other.nix`.
- Stage new files (`git add`) before evaluating — flakes ignore untracked paths.
- Do not bump `home.stateVersion` or add plaintext secrets as part of other work.
- Keep docs honest: README is for humans, the skill is for agents. Neither is an
  inventory — discover hosts and flags with the commands above.
