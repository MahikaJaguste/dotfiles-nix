# dotfiles-nix

Reproducible development environment managed with [Home Manager](https://github.com/nix-community/home-manager) and [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## What's Included

| Tool | Description |
|------|-------------|
| **tmux** | Terminal multiplexer with vi mode, mouse, sensible splits |
| **git** | Version control with useful aliases |
| **bash** | Shell with git-aware prompt, aliases, history |
| **lazygit** | Terminal UI for git |
| **neovim** | Text editor with sensible defaults |
| **ripgrep, fd, fzf, eza, bat, jq, btop** | Modern CLI utilities |

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

Each machine has a short name in `flake.nix` (`mj` = this MacBook). Select it
with `.#<name>`:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mj
```

To add another machine, add an entry in `flake.nix` with its own platform and
username:

```nix
homeConfigurations = {
  mj = mkHome {
    system = "aarch64-darwin";
    username = "mahikajaguste";
  };
  # linux-laptop = mkHome {
  #   system = "x86_64-linux";
  #   username = "mahika";
  # };
};
```

then run `switch --flake .#linux-laptop` on that machine. `home.username` and
`home.homeDirectory` are set from these values (directories use `/Users` on
macOS and `/home` on Linux), so `home.nix` itself stays user-agnostic.

### 4. Start using your environment

```bash
exec bash    # reload shell
tmux         # start tmux
```

## Adding a New Tool

1. Create a new file in `modules/` (e.g., `modules/mytool.nix`)
2. Add the module to the `imports` list in `home.nix`
3. Run `nix run nixpkgs#home-manager -- switch --flake .#mj` to apply

## Updating

```bash
nix flake update    # update all dependencies
nix run nixpkgs#home-manager -- switch --flake .#mj   # apply changes
```

## Repo Structure

```
dotfiles-nix/
├── flake.nix              # Entry point — pins nixpkgs + home-manager + per-machine names
├── flake.lock             # Lock file — exact versions (commit this)
├── home.nix               # Main Home Manager config
├── modules/
│   ├── tmux.nix           # tmux package + config
│   ├── git.nix            # git package + config
│   ├── bash.nix           # bash package + config
│   ├── lazygit.nix        # lazygit package + config
│   └── neovim.nix         # neovim package + config
└── README.md              # This file
```
