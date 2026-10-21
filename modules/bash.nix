_: {
  programs.bash = {
    enable = true;
    historySize = 10000;
    historyFileSize = 20000;
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
    ];
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate --all";
      cat = "bat";
      ls = "eza";
      find = "fd";
      grep = "rg";
      top = "btop";
      # macOS ships /usr/bin/vi and /usr/bin/vim, which come before the Nix
      # profile in PATH and shadow programs.neovim's aliases. Send them to
      # Neovim (LazyVim) explicitly.
      vi = "nvim";
      vim = "nvim";
    };
    # Placed before the bash-completion block. bash-completion temporarily
    # sets LC_ALL= and uses LC_COLLATE; with no LANG set (common on macOS)
    # Nix bash 5 then warns "setlocale: LC_COLLATE: cannot change locale ()".
    # A concrete collation avoids the warning without forcing a language.
    bashrcExtra = ''
      export LC_COLLATE=C
    '';

    initExtra = ''
      # Prompt with git branch
      parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
      }
      export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$(parse_git_branch)\$ "
    '';
  };
}
