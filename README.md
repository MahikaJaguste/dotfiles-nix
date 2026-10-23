# dotfiles-nix

Reproducible development environment for macOS and Linux, managed with
[Nix Flakes](https://nixos.wiki/wiki/Flakes) and
[Home Manager](https://github.com/nix-community/home-manager).

## What you get

| Area     | Tools                                                        |
| -------- | ------------------------------------------------------------ |
| Terminal | Ghostty, tmux (Catppuccin Mocha), JetBrainsMono Nerd Font     |
| Editor   | Neovim with LazyVim, Nix-managed plugins and language servers |
| Shell    | bash with direnv, aliases, history and a git-aware prompt     |
| Git      | git, gh, lazygit, worktrunk, aliases and Nix-managed SSH config |
| CLI      | ripgrep, fd, fzf, eza, bat, jq, btop                          |

## Set up a new machine

1. Install Nix. This repo uses [Determinate Nix](https://determinate.systems/nix),
   which enables flakes and the `nix` command by default:

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

   If you install plain Nix instead, enable the experimental features first:

   ```bash
   mkdir -p ~/.config/nix
   echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
   ```

   Every `nix` command below assumes flakes are enabled.

2. Clone this repo:

   ```bash
   git clone https://github.com/MahikaJaguste/dotfiles-nix
   cd dotfiles-nix
   ```

3. Apply the configuration for this machine:

   ```bash
   nix run nixpkgs#home-manager -- switch --flake .#mj
   ```

   `mj` is this MacBook. Hosts live in `modules/flake/hosts/`; add a file there
   for another machine, then use `.#<name>`.

4. Set up GitHub SSH:

   ```bash
   nix run .#github-ssh
   ```

   Use a different key or email:

   ```bash
   nix run .#github-ssh -- --key id_ed25519_work --email work@example.com
   ```

   For a work account, log in once and pass the account name:

   ```bash
   gh auth login
   nix run .#github-ssh -- --key id_ed25519_work --email work@example.com --account work-username
   ```

5. Open a new shell and start working:

   ```bash
   exec bash
   tmux
   ```

   Ghostty is installed with the configuration. On macOS it is also linked into
   `~/Applications`, so it can be launched from Spotlight.

### macOS: use the Nix bash

macOS ships bash 3.2, but the generated `.bashrc` needs bash 4.2 or newer. Make
the Nix bash your login shell once:

```bash
echo "$HOME/.nix-profile/bin/bash" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/bash"
```

Log out and back in. If Terminal.app ignores this, set its profile to use the
login shell. A tmux server started before the change keeps the old shell;
restart it with `tmux kill-server`.

## Making changes

The configuration is split by area under `modules/home/`; every file is loaded
automatically, so there is no import list. To add a tool, create a file next to
similar ones and enable it in `modules/home/profiles.nix` (or in one host's
module). Machine definitions live in `modules/flake/hosts/`.

Apply changes after editing:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mj
```

Update all dependencies:

```bash
nix flake update
nix run nixpkgs#home-manager -- switch --flake .#mj
```

Generated files (`~/.config/nvim`, `~/.config/tmux/tmux.conf`, `~/.bashrc`,
`~/.ssh/config`) are managed by Nix. Edit the module, not the file.
