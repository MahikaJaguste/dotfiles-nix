{
  perSystem =
    { config, lib, pkgs, ... }:
    {
      packages.github-ssh = pkgs.writeShellApplication {
        name = "github-ssh";
        # Prefer the system OpenSSH at runtime. macOS has Apple's UseKeychain
        # support there, and non-NixOS Linux needs the host client so account
        # lookup can use NSS modules such as sssd. The Nix client is only a
        # fallback for systems without /usr/bin/ssh.
        runtimeInputs = with pkgs; [
          coreutils
          gh
        ] ++ lib.optionals stdenv.hostPlatform.isLinux [ openssh ];
        text = ''
          usage() {
            cat <<'EOF'
          Usage: github-ssh [options]

          Create an SSH key if needed and add its public key to GitHub.

          Options:
            --key NAME|PATH   Key name under ~/.ssh, or a path. Default: id_ed25519
            --email EMAIL     Key comment. Default: mahika.for.me@gmail.com
            --title TITLE     GitHub key title. Default: "<hostname> <key name>"
            --account USER    Add the key with this gh account. Default: active account.
            --ssh-host HOST   Verify against this SSH host. Default: github.com
            --ssh-port PORT   Verify against this SSH port.
            --no-verify       Skip the final ssh authentication check.
            -h, --help        Show this help.
          EOF
          }

          key=id_ed25519
          email=mahika.for.me@gmail.com
          title=
          account=
          ssh_host=github.com
          ssh_port=
          verify=1

          ssh_bin=ssh
          ssh_keygen_bin=ssh-keygen
          if [[ -x /usr/bin/ssh && -x /usr/bin/ssh-keygen ]]; then
            ssh_bin=/usr/bin/ssh
            ssh_keygen_bin=/usr/bin/ssh-keygen
          fi

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --key)
                key="''${2:?--key needs a value}"
                shift 2
                ;;
              --email)
                email="''${2:?--email needs a value}"
                shift 2
                ;;
              --title)
                title="''${2:?--title needs a value}"
                shift 2
                ;;
              --account)
                account="''${2:?--account needs a value}"
                shift 2
                ;;
              --ssh-host)
                ssh_host="''${2:?--ssh-host needs a value}"
                shift 2
                ;;
              --ssh-port)
                ssh_port="''${2:?--ssh-port needs a value}"
                shift 2
                ;;
              --no-verify)
                verify=0
                shift
                ;;
              -h | --help)
                usage
                exit 0
                ;;
              *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 2
                ;;
            esac
          done

          case "$key" in
            *.pub) key="''${key%.pub}" ;;
          esac

          if [[ "$key" == */* || "$key" == "~"* ]]; then
            key="''${key/#\~/$HOME}"
          else
            key="$HOME/.ssh/$key"
          fi

          mkdir -p "$(dirname "$key")"
          chmod 700 "$(dirname "$key")"

          if [[ ! -f "$key" ]]; then
            "$ssh_keygen_bin" -t ed25519 -a 100 -C "$email" -f "$key"
          elif [[ ! -f "$key.pub" ]]; then
            "$ssh_keygen_bin" -y -f "$key" >"$key.pub"
            chmod 644 "$key.pub"
          fi

          chmod 600 "$key"

          if [[ -z "$title" ]]; then
            title="$(uname -n) $(basename "$key")"
          fi

          echo "Key: $key"
          echo "Fingerprint: $("$ssh_keygen_bin" -lf "$key.pub")"

          if [[ -n "$account" ]]; then
            if ! token="$(gh auth token -h github.com -u "$account")"; then
              echo "No gh token for github.com account '$account'." >&2
              echo "Run 'gh auth login' for that account first." >&2
              exit 1
            fi
            export GH_TOKEN="$token"
          fi

          if gh auth status -h github.com >/dev/null 2>&1; then
            if gh ssh-key add "$key.pub" --title "$title"; then
              echo "Added the public key to GitHub."
            else
              echo "Could not add the key with gh." >&2
              echo "Run 'gh auth refresh -h github.com -s admin:public_key' and retry," >&2
              echo "or add this public key at https://github.com/settings/ssh/new:" >&2
              cat "$key.pub" >&2
            fi
          else
            echo "gh is not logged in to github.com. Add this public key at" >&2
            echo "https://github.com/settings/ssh/new:" >&2
            cat "$key.pub" >&2
            echo "Or run 'gh auth login' and rerun this command." >&2
          fi

          if [[ "$verify" -eq 1 ]]; then
            echo
            echo "Testing SSH authentication..."
            verify_opts=(
              -i "$key"
              -o IdentitiesOnly=yes
              -o StrictHostKeyChecking=accept-new
              -o ConnectTimeout=10
            )
            if [[ -n "$ssh_port" ]]; then
              verify_opts+=(-p "$ssh_port")
            fi
            output="$("$ssh_bin" "''${verify_opts[@]}" -T "git@$ssh_host" 2>&1 || true)"
            printf '%s\n' "$output"
            if [[ "$output" != *"successfully authenticated"* ]]; then
              echo >&2
              echo "SSH verification did not succeed. If this network blocks SSH" >&2
              echo "to GitHub, use HTTPS instead:" >&2
              echo "  gh auth login -p https && gh auth setup-git" >&2
            fi
          fi
        '';
      };

      apps.github-ssh = {
        type = "app";
        program = "${config.packages.github-ssh}/bin/github-ssh";
        meta.description = "Create an SSH key and add it to GitHub";
      };
    };
}
