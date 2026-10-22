{ config, lib, pkgs, ... }:
let
  cfg = config.my.git;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options.my.git = {
    enable = lib.mkEnableOption "git configuration";

    personal = {
      userName = lib.mkOption {
        description = "Name used for personal commits.";
        type = lib.types.str;
        default = "Mahika Jaguste";
      };
      userEmail = lib.mkOption {
        description = "Email used for personal commits.";
        type = lib.types.str;
        default = "mahika.for.me@gmail.com";
      };
      sshKey = lib.mkOption {
        description = "Private key used for the personal GitHub account.";
        type = lib.types.str;
        default = "~/.ssh/id_ed25519";
      };
    };

    work = {
      enable = lib.mkEnableOption "a second, work GitHub identity";

      userName = lib.mkOption {
        description = "Name used for work commits. Required when work.enable is true.";
        type = lib.types.str;
        default = "";
      };
      userEmail = lib.mkOption {
        description = "Email used for work commits. Required when work.enable is true.";
        type = lib.types.str;
        default = "";
      };
      sshKey = lib.mkOption {
        description = "Private key used for the work GitHub account.";
        type = lib.types.str;
        default = "~/.ssh/id_ed25519_work";
      };
      sshHost = lib.mkOption {
        description = "SSH host alias for the work GitHub account.";
        type = lib.types.str;
        default = "github-work";
      };
      hostName = lib.mkOption {
        description = "Real hostname behind the work SSH alias.";
        type = lib.types.str;
        default = "github.com";
      };
      certificateFile = lib.mkOption {
        description = "Optional SSH certificate for the work identity.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      directory = lib.mkOption {
        description = "Directory whose repositories use the work identity.";
        type = lib.types.str;
        default = "~/code/work";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional cfg.work.enable {
      assertion = cfg.work.userName != "" && cfg.work.userEmail != "";
      message = "Set my.git.work.userName and my.git.work.userEmail when my.git.work.enable is true.";
    };

    programs.git = {
      enable = true;
      settings = {
        user.name = cfg.personal.userName;
        user.email = cfg.personal.userEmail;
        init.defaultBranch = "main";
        color.ui = "auto";
        core.editor = "nvim";
        core.autocrlf = "input";
        pull.rebase = false;
        diff.colorMoved = "default";
        alias = {
          last = "log -1 HEAD";
          unstage = "reset HEAD --";
        };
      };

      # Repositories under the work directory commit with the work identity.
      # Use an explicit /** so the pattern matches recursively on older Git
      # versions as well as newer ones.
      includes = lib.optional cfg.work.enable {
        condition = "gitdir:${lib.removeSuffix "/" cfg.work.directory}/**";
        contents = {
          user.name = cfg.work.userName;
          user.email = cfg.work.userEmail;

          # Rewrite only GitHub URLs. Other work hosts, such as an internal
          # repo-243 alias with certificate auth, keep their own SSH config.
          url."git@${cfg.work.sshHost}:".insteadOf = "git@${cfg.work.hostName}:";
        };
      };
    };

    # The private keys themselves are machine-local and deliberately not
    # managed by Nix. Only the client config is declarative.
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      # Machine-specific hosts can stay out of Nix, for example a work alias
      # with a short-lived SSH certificate. OpenSSH ignores a missing include.
      includes = [ "~/.ssh/config.local" ];

      settings = {
        "*" = {
          AddKeysToAgent = "yes";
          UserKnownHostsFile = "~/.ssh/known_hosts";
        } // lib.optionalAttrs isDarwin {
          UseKeychain = true;
        };

        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = cfg.personal.sshKey;
          IdentitiesOnly = true;
        };
      } // lib.optionalAttrs cfg.work.enable {
        "${cfg.work.sshHost}" = {
          HostName = cfg.work.hostName;
          User = "git";
          IdentityFile = cfg.work.sshKey;
          CertificateFile = cfg.work.certificateFile;
          IdentitiesOnly = true;
        };
      };
    };
  };
}
