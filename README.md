# dotfiles-nix

Reproducible development environment managed with [Home Manager](https://github.com/nix/home-manager) and [Nix Flakes](https://nixos.wiki/wiki/Flakes).

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

**On macOS (Apple Silicon):**
```bash
nix run nixpkgs#home-manager -- switch --flake .#aarch64-darwin
```

**On macOS (Intel):**
```bash
nix run nixpkgs#home-manager -- switch --flake .#x86_64-darwin
```

**On Linux:**
```bash
nix run nixpkgs#home-manager -- switch --flake .#x86_64-linux
```

### 4. Start using your environment

```bash
exec bash    # reload shell
tmux         # start tmux
```

## Adding a New Tool

1. Create a new file in `modules/` (e.g., `modules/mytool.nix`)
2. Add the module to the `imports` list in `home.nix`
3. Run `home-manager switch --flake .` to apply

## Updating

```bash
nix flake update    # update all dependencies
home-manager switch --flake .   # apply changes
```

## Repo Structure

```
dotfiles-nix/
├── flake.nix              # Entry point — pins nixpkgs + home-manager
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
