{
  perSystem =
    { config, lib, pkgs, ... }:
    {
      packages.github-ssh = pkgs.writeShellApplication {
        name = "github-ssh";
        # macOS ships an OpenSSH with Apple's UseKeychain option, so use the
        # system client there instead of the upstream package from nixpkgs.
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
            --no-verify       Skip the final ssh authentication check.
            -h, --help        Show this help.
          EOF
          }

          key=id_ed25519
          email=mahika.for.me@gmail.com
          title=
          account=
          verify=1

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
            ssh-keygen -t ed25519 -a 100 -C "$email" -f "$key"
          elif [[ ! -f "$key.pub" ]]; then
            ssh-keygen -y -f "$key" >"$key.pub"
            chmod 644 "$key.pub"
          fi

          chmod 600 "$key"

          if [[ -z "$title" ]]; then
            title="$(uname -n) $(basename "$key")"
          fi

          echo "Key: $key"
          echo "Fingerprint: $(ssh-keygen -lf "$key.pub")"

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
            ssh -i "$key" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new \
              -o ConnectTimeout=10 -T git@github.com || true
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
