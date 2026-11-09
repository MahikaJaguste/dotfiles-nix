# Handoff: extend dotfiles-nix for a Linux work machine

Audience: an agent working on `dotfiles-work`, the thin overlay flake that
imports `dotfiles-nix.homeModules.default`.

## Context

`dotfiles-work` imports `dotfiles-nix.homeModules.default`, sets
`my.profile = "full"`, and adds work settings such as the git identity and
`github.cadence.com` SSH hosts.

The target is a RHEL-like Linux VM (x86_64, no root, not NixOS). It is reached
over SSH from a **Windows laptop using its default terminal**, then tmux is
started on the VM. The separate macOS/Ghostty setup is not part of this path.

The goal is to fix root causes in `dotfiles-nix` with generic options, so the
work overlay only sets host facts and never patches module internals.

## Environment facts

- Accounts come from sssd: `/etc/nsswitch.conf` has `passwd: files sss`, and
  the module is `/usr/lib64/libnss_sss.so.2`. The uid (295834) is not in
  `/etc/passwd`.
- Nix-built programs use Nix's glibc and cannot load the host's NSS modules.
- `/usr/lib/locale/locale-archive` exists for the system glibc. Nix glibc only
  has `C`, `C.utf8` and `POSIX`, and `LOCALE_ARCHIVE` is unset.
- System `/usr/bin/bash`, `/usr/bin/tmux` and `/usr/bin/ssh` exist.
- The Windows SSH client sends `TERM=xterm-256color`. The VM has that terminfo;
  no `xterm-ghostty` entry is needed.
- Outbound SSH to github.com is blocked on ports 22 and 443. HTTPS to
  github.com and api.github.com works.
- A TLS-intercepting proxy is in place. Nix fetches need the corporate CA (see
  `dotfiles-work/README.md`).

## Problems and root causes

1. **`I have no name!@host` in tmux.** tmux forced Nix bash
   (`${pkgs.bashInteractive}/bin/bash`). That bash links Nix glibc, so
   `getpwuid()` cannot use sssd and the prompt falls back to `I have no name!`.
   `$USER` still works because it is only an environment variable. The system
   `/bin/bash` works because it uses the host glibc.

2. **Overwritten text in the status bar.** Nix programs cannot find
   `en_US.UTF-8` in Nix's locale archive, so they fall back to the C locale.
   tmux then treats the terminal as non-UTF-8 and mis-measures Catppuccin
   powerline glyphs and icons.

3. **No icons.** Over SSH, fonts are rendered by the Windows terminal. A Nerd
   Font installed on the VM does nothing. Install the font on Windows and set
   it as the Windows Terminal font. The VM only needs a UTF-8 locale so tmux
   measures the glyphs correctly.

4. **tmux window rename not working.** Catppuccin v2 displays `#T`, the pane
   title, not `#W`, the window name. On a bare SSH session there is no terminal
   shell integration updating the pane title, so the status bar looks static.
   Check with:

   ```bash
   tmux display-message -p '#W | #T | #{pane_current_command}'
   ```

   If `#W` changes but the bar does not, use `#W` for the Catppuccin window
   text. If `#W` stays `bash`, adjust `automatic-rename-format`.

5. **Nix `openssh` and other user-lookup tools fail.** `nix run .#github-ssh`
   failed with `No user exists for uid 295834` because the app used Nix
   `openssh` on Linux. Nix openssh cannot resolve sssd accounts.

6. **SSH key clash.** `my.git.personal.sshKey` defaults to
   `~/.ssh/id_ed25519`, and the work overlay also used that file for its own
   host (`gitkeyid`). One key cannot serve both GitHub accounts.

7. **Ghostty terminfo.** This was listed as a work issue but is not one. The
   work client is Windows Terminal over SSH, which sends `xterm-256color`.
   Ghostty's `ssh-terminfo`/`ssh-env` settings only affect SSH sessions started
   from the Mac.

8. **No SSH to github.com from the work VM.** Pushes must use HTTPS there.

## Changes already made in core

- **`my.shell.path`** (`modules/home/meta/shell.nix`). Default is Nix bash.
  `tmux.nix` uses it for `programs.tmux.shell`, `default-command`, and
  `SHELL`. Consumers can set `/bin/bash`.
- **`my.locale.nixArchive.enable`** (`modules/home/meta/locale.nix`). Defaults
  to true on Linux. Sets `LOCALE_ARCHIVE` to
  `${pkgs.glibcLocales}/lib/locale/locale-archive` with `lib.mkDefault`.
- **tmux window options** (`modules/home/terminal/tmux.nix`):
  `my.tmux.windowStatusStyle` (default `rounded`), `my.tmux.windowText` and
  `my.tmux.windowCurrentText` (default `#T`), `my.tmux.automaticRename`
  (default `true`), and `my.tmux.automaticRenameFormat`.
- **git SSH options** (`modules/home/git/git.nix`):
  `my.git.personal.sshHostName` (default `github.com`),
  `my.git.personal.sshPort` (default `22`), and
  `my.git.work.urlRewrite` (default `true`). `programs.ssh.package` is now
  explicitly `lib.mkDefault null`, so the system OpenSSH is used.
- **`github-ssh`** (`modules/flake/packages/github-ssh.nix`). Prefers
  `/usr/bin/ssh` and `/usr/bin/ssh-keygen`, so it avoids Nix glibc/NSS
  failures. Adds `--ssh-host` and `--ssh-port` for the verification step and
  prints a clear HTTPS suggestion when SSH verification fails.
- **Ghostty** (`modules/home/terminal/ghostty.nix`). Enables `ssh-env` and
  `ssh-terminfo` for SSH sessions started from the Mac. This is separate from
  the Windows work path.

## What the work flake should do after this

Add the host-specific values in `dotfiles-work`:

```nix
my.shell.path = "/bin/bash";

my.git.personal.sshKey = "~/.ssh/id_ed25519_personal";

# The VM is reached over SSH; it has no GUI terminal.
my.ghostty.enable = false;

# Optional: fonts are rendered by the Windows terminal.
my.fonts.enable = false;

# Follow tmux's window name instead of a pane title that bare SSH never sets.
my.tmux.windowText = "#W";
my.tmux.windowCurrentText = "#W";

# Only needed if the work host uses my.git.work and SSH to GitHub is blocked.
# my.git.work.urlRewrite = false;
```

Notes:

- Do not set `LOCALE_ARCHIVE` directly. `my.locale.nixArchive.enable` already
  defaults to true on Linux.
- Do not set `programs.ssh.package`; it already defaults to `null`.
- Use separate keys for separate accounts. The work identity should use its
  own key, for example `~/.ssh/id_ed25519_work`. The `gitkeyid`/`gitcert`
  hosts should not reuse the personal key.
- If SSH over port 443 is actually available on another network, core supports:

  ```nix
  my.git.personal.sshHostName = "ssh.github.com";
  my.git.personal.sshPort = 443;
  ```

  On this network SSH is blocked on 443 too, so use HTTPS.

## Windows client

Outside Nix:

1. Install JetBrainsMono Nerd Font (or another Nerd Font).
2. Set it as the Windows Terminal font face.
3. Keep `TERM=xterm-256color` for SSH. No extra terminfo is needed on the VM.

## How to test on the VM

1. In `dotfiles-work`: `nix flake update dotfiles-nix`, then:

   ```bash
   nix run nixpkgs#home-manager -- switch --flake .#work
   ```

2. `tmux kill-server`, open a new tmux session, and check:
   - the prompt shows `mahika@host`
   - `id -un` works inside tmux
   - the status bar has no overwritten text
   - `echo $LANG` and `locale` show UTF-8
   - `command -v git` and `git --version` resolve to the intended Git
   - window names follow the running command, or show the configured format

3. Diagnose window text with:

   ```bash
   tmux display-message -p '#W | #T | #{pane_current_command}'
   ```

4. Check the SSH helper:

   ```bash
   nix run .#github-ssh -- --help
   ```

   On this network, use `--no-verify` or let it print the HTTPS fallback.

## Git and GitHub from the VM

- SSH to github.com is blocked. Use HTTPS:

  ```bash
  gh auth login -p https
  gh auth setup-git
  ```

- Open PRs with `gh pr create`.
- The `github:` flake input already fetches over HTTPS; it does not need a
  `git+ssh` URL.
- If `my.git.work` is enabled, set `my.git.work.urlRewrite = false` on this
  network so GitHub URLs are not rewritten to a blocked SSH host.

## Docs

Keep the README as a short, command-first runbook. Put design rationale in
module comments and the agent skill, per `AGENTS.md`.
