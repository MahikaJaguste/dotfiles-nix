# dotfiles-nix

Reproducible development environment managed with [Home Manager](https://github.com/nix-community/home-manager) and [Nix Flakes](https://nixos.wiki/wiki/Flakes), structured as a [dendritic flake](https://github.com/mightyiam/dendritic): every file in `modules/` is a module, modules are discovered rather than imported, and they talk to each other through options instead of `import`.

## What's Included

| Tool                                     | Description                                                 |
| ---------------------------------------- | ----------------------------------------------------------- |
| **tmux**                                 | Terminal multiplexer with vi mode, mouse, sensible splits   |
| **git**                                  | Version control with useful aliases                         |
| **bash**                                 | Shell with git-aware prompt, aliases, history               |
| **lazygit**                              | Terminal UI for git                                         |
| **neovim**                               | LazyVim via lazyvim-nix: Nix-managed plugins, LSP servers   |
| **Ghostty**                              | Cross-platform terminal with truecolor and Catppuccin Mocha |
| **Nerd Font**                            | JetBrainsMono Nerd Font Mono for terminal/tmux icons        |
| **ripgrep, fd, fzf, eza, bat, jq, btop** | Modern CLI utilities                                        |

## Bootstrap on a New Machine

### 1. Install Nix (if not already installed)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Clone this repo

```bash
git clone https://github.com/MahikaJaguste/dotfiles-nix
cd dotfiles-nix
```

### 3. Apply the configuration

Each machine is a small module under `modules/flake/hosts/` (`mj` = this
MacBook). Select it with `.#<name>`:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mj
```

To add another machine, create `modules/flake/hosts/linux-laptop.nix`:

```nix
{
  my.hosts.linux-laptop = {
    system = "x86_64-linux";
    username = "mahika";
    profile = "full"; # or "minimal"
  };
}
```

No edit to `flake.nix` is needed: files in `modules/flake/` are discovered
automatically. Run `switch --flake .#linux-laptop` on that machine.
`home.username` and `home.homeDirectory` are set from these values
(directories use `/Users` on macOS and `/home` on Linux), so the feature
modules stay user-agnostic.

### 4. Start using your environment

```bash
exec bash    # reload shell
tmux         # start tmux
```

Ghostty is installed as part of the Home Manager generation. On macOS it is
also symlinked to `~/Applications/Ghostty.app`, so launch it from
Spotlight/Finder (`Ghostty`) or with `ghostty` from a terminal. On Linux it
appears in the application menu. You do **not** need to run `home-manager`
before opening Ghostty or tmux — only after changing this repo.

tmux sessions survive closing the terminal. To return to one later:

```bash
tmux attach       # or: tmux a
tmux new -A -s main   # attach to "main", creating it if needed
```

Otherwise a new tmux session is created when you run `tmux` with no arguments.

### Shell

Home Manager configures **bash**, which is also the default on Linux. However,
macOS still ships bash 3.2 as `/bin/bash`, and the generated `~/.bashrc` uses
bash 4.2+ features (`globstar`, `[[ -v ... ]]`). Using `/bin/bash` as the login
shell therefore produces errors such as:

```text
-bash: shopt: globstar: invalid shell option name
-bash: .bashrc: line 30: conditional binary operator expected
```

Use the Nix-provided bash 5 instead. This is a one-time change:

```bash
# Add the stable Nix profile path to the allowed shells (needs sudo).
echo "$HOME/.nix-profile/bin/bash" | sudo tee -a /etc/shells

# Make it your login shell.
chsh -s "$HOME/.nix-profile/bin/bash"

# Log out/in or open a new terminal, then verify:
echo $SHELL
bash --version
```

On Linux, bash is normally already new enough; if not, install bash 5 and set
it as your login shell the same way.

If Terminal.app still opens `/bin/bash` after this, its own profile is
overriding the login shell. Change _Settings → Profiles → [your profile] →
Shell_ to use the login shell (or set the command to
`/Users/<you>/.nix-profile/bin/bash`). From the command line, after quitting
Terminal:

```bash
defaults delete com.apple.Terminal Shell
```

tmux also caches the shell it started with. The config now explicitly uses the
Nix bash for new panes, but panes/windows created before the change keep their
old shell. Close them, or run `exec ~/.nix-profile/bin/bash` inside them. A
full reset is `tmux kill-server` followed by starting tmux again.

`bash-completion` temporarily unsets `LC_ALL` and uses `LC_COLLATE`. With no
`LANG` set (common on macOS) Nix bash 5 warns `setlocale: LC_COLLATE: cannot
change locale ()`. The bash config exports `LC_COLLATE=C` before completion is
loaded, which removes the warning without changing the UTF-8 character set.

### Terminal colours and fonts

Catppuccin uses 24-bit ("truecolor") colours. Ghostty supports truecolor on
both macOS and Linux, so the tmux config enables `Tc` unconditionally and the
exact Catppuccin palette is used. Avoid Apple Terminal before macOS 26 — it
only supports 256 colours and will mis-render the RGB sequences.

JetBrainsMono Nerd Font is installed through Nix. Home Manager copies it into
`~/Library/Fonts/HomeManager` on macOS and makes it available to fontconfig on
Linux. Ghostty is configured to use `JetBrainsMono Nerd Font Mono`, and the
Catppuccin status bar uses Nerd Font icons and rounded separators.

After editing the tmux config, reload it with `prefix r`; if an already-running
session still shows wrong colours, detach and reattach (`prefix d`, then `tmux
attach`) so tmux re-reads the terminal's capabilities.

### Neovim (LazyVim)

Neovim runs [LazyVim](https://www.lazyvim.org) through
[lazyvim-nix](https://github.com/pfassina/lazyvim-nix), a Home Manager module
that installs LazyVim's plugin set with Nix and generates `~/.config/nvim` from
`modules/home/editors/neovim.nix`. Mason is disabled: LSP servers, formatters and linters
come from `programs.lazyvim.extraPackages`, so the binaries are pinned by Nix
instead of downloaded into `~/.local/share/nvim/mason`.

Enabled extras (`programs.lazyvim.extras`):

- `lang.nix` (nil_ls, nixfmt, statix)
- `lang.python` (pyright, ruff, python3)
- `lang.typescript` (vtsls)
- `lang.rust` (rust-analyzer, clippy checks, rustfmt)
- `lang.json`, `lang.yaml`, `lang.toml`, `lang.markdown`
- `coding.blink` (blink.cmp completion)
- Bash is configured by hand in `plugins.bash` (bashls, shfmt, shellcheck)

Useful keys (LazyVim defaults, leader is `Space`):

| Key               | Action                                      |
| ----------------- | ------------------------------------------- |
| `Space Space`     | Find files                                  |
| `Space /`         | Live grep                                   |
| `Space e`         | File explorer                               |
| `Space gg`        | Lazygit                                     |
| `Space cf`        | Format buffer                               |
| `Space ca`        | Code action                                 |
| `Space cr`        | Rename symbol                               |
| `Space xx`        | Diagnostics (Trouble)                       |
| `Space l`         | Lazy (plugin state; versions come from Nix) |
| `gd` / `gr` / `K` | Definition / references / hover             |
| `]d` / `[d`       | Next / previous diagnostic                  |

To add something, edit `modules/home/editors/neovim.nix` and apply:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mj
```

- **Language:** `extras.lang.<lang>.enable = true;` plus any missing server or
  formatter in `extraPackages`. Don't use `:LazyExtras` — plugins added there
  are not installed by Nix.
- **Tool:** add the package to `extraPackages`; LazyVim's extras already point
  their LSP/formatter configs at it.
- **Plugin config:** `plugins.<file> = ''return { { "owner/repo", opts = {...} } }'';`
  (see `plugins.bash`). Values are plain Lua.
- **Options/keymaps:** `config.options` and `config.keymaps` (Lua strings).

`~/.config/nvim` is generated from the Nix config — edit `modules/home/editors/neovim.nix`,
not those files. Plugin versions follow the `lazyvim` input in `flake.lock`, so
`nix flake update` plus a switch updates LazyVim and the Nix-managed plugins
together.

`EDITOR` and `VISUAL` point at `nvim`, and the bash aliases `vi` and `vim` also
run it (macOS ships `/usr/bin/vi` and `/usr/bin/vim`, which otherwise win in
`PATH`).

Markdown files are linted by `markdownlint-cli2` through nvim-lint. The rules
are generated in `modules/home/editors/neovim.nix` and passed with `--config`, so no
per-repo config file is needed: line length (MD013) is disabled and the rest
stays on, so fenced code blocks need a language tag such as `bash`, `text` or
`nix`.

On the first start lazy.nvim itself, `catppuccin` and `friendly-snippets` are
still fetched by lazy (LazyVim references them, but lazyvim-nix does not map them
to Nix packages). They land in `~/.local/share/nvim/lazy` and are recorded in
`~/.config/nvim/lazy-lock.json`; after that Neovim needs no network.

## Adding a New Tool

Each tool is one self-contained module in `modules/home/`. Files are discovered
automatically — there is no import list to update.

1. Create `modules/home/<group>/mytool.nix` using the standard shape:

```nix
{ config, lib, ... }:
{
  options.my.mytool.enable = lib.mkEnableOption "mytool";

  config = lib.mkIf config.my.mytool.enable {
    programs.mytool.enable = true;
  };
}
```

2. Turn it on in `modules/home/profiles.nix` so every host with that profile
   gets it, or set `my.mytool.enable = true;` in the host's flake module for a
   single machine.
3. Apply:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mj
```

If the tool needs a value another module also uses (a font name, an editor
command), declare an option for it — see `modules/home/meta/fonts.nix` — instead
of hardcoding it or importing the other file.

## Updating

```bash
nix flake update    # update all dependencies
nix run nixpkgs#home-manager -- switch --flake .#mj   # apply changes
```

## Repo Structure

```text
dotfiles-nix/
├── flake.nix                    # Bootstrap: pins inputs, hands control to modules/flake
├── flake.lock                   # Exact versions (commit this)
├── modules/
│   ├── flake/                   # Flake-level modules (flake-parts)
│   │   ├── systems.nix          # Systems to evaluate
│   │   ├── hosts.nix            # my.hosts -> homeConfigurations
│   │   └── hosts/
│   │       └── mj.nix           # This MacBook: system, username, profile
│   └── home/                    # Home Manager modules (all auto-imported)
│       ├── base.nix             # stateVersion, home-manager.enable
│       ├── profiles.nix         # Profile -> feature flags
│       ├── meta/fonts.nix       # my.font.mono + Nerd Font install
│       ├── shell/bash.nix
│       ├── dev/git.nix
│       ├── dev/cli-tools.nix
│       ├── terminal/tmux.nix
│       ├── terminal/ghostty.nix
│       ├── editors/neovim.nix
│       └── editors/lazygit.nix
├── .opencode/skills/
│   └── dendritic-nix/SKILL.md   # Agent instructions for extending this repo
└── README.md                    # This file
```

### How the wiring works

- `flake.nix` calls `flake-parts.lib.mkFlake` with `import-tree ./modules/flake`.
  Every file under `modules/flake/` is therefore a flake module, and none of
  them are listed by hand.
- `modules/flake/hosts.nix` defines the `my.hosts` option and maps each host to
  a `homeManagerConfiguration`. Each configuration imports
  `import-tree ../home`, so every file under `modules/home/` is a Home Manager
  module.
- Each feature gates itself behind `my.<feature>.enable`.
  `modules/home/profiles.nix` decides which features a profile enables.
- Directory names are documentation: discovery is recursive, so moving a file
  between groups never changes behaviour. Pure helper code that is not a module
  belongs in a top-level `lib/`, never in `modules/`.
