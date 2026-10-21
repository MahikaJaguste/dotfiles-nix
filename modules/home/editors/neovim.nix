{ config, lib, pkgs, lazyvim, ... }:
let
  # markdownlint rule set used by nvim-lint and conform (via --config), so the
  # rules live here instead of a .markdownlint-cli2.jsonc in every repo.
  markdownlintConfig = pkgs.writeText "markdownlint-cli2.json" (
    builtins.toJSON {
      config = {
        # 80 columns conflicts with tables and long links; the rest stays on.
        MD013 = false;
      };
    }
  );
in
{
  imports = [ lazyvim.homeManagerModules.default ];

  options.my.neovim.enable = lib.mkEnableOption "Neovim with LazyVim";

  config = lib.mkIf config.my.neovim.enable {
    programs.neovim = {
      defaultEditor = true;
    };

    programs.lazyvim = {
      enable = true;

      # git, ripgrep, fd, lazygit, fzf, curl
      installCoreDependencies = true;

      # LazyVim extras replace Mason: the extras configure LSP servers and
      # formatters, and the binaries come from extraPackages below.
      extras = {
        lang = {
          nix = {
            enable = true;
            installDependencies = true; # statix, nixfmt
          };
          python = {
            enable = true;
            installDependencies = true; # ruff
            installRuntimeDependencies = true; # python3
          };
          typescript = {
            enable = true;
            vtsls.enable = true;
          };
          json = {
            enable = true;
            installDependencies = true; # vscode-langservers-extracted (jsonls)
          };
          yaml.enable = true;
          toml = {
            enable = true;
            installDependencies = true; # taplo
          };
          markdown = {
            enable = true;
            installDependencies = true; # markdownlint-cli2, markdown-toc
          };
          rust = {
            enable = true;
            # Newer rust-analyzer uses check.command instead of checkOnSave; make
            # sure clippy is what runs on save.
            config = ''
              return {
                "mrcjkb/rustaceanvim",
                opts = {
                  server = {
                    default_settings = {
                      ["rust-analyzer"] = {
                        check = { command = "clippy" },
                      },
                    },
                  },
                },
              }
            '';
          };
        };
        # LazyVim v16 defaults to blink.cmp; enabling the extra adds the plugin to
        # the Nix-managed set instead of letting lazy clone it.
        coding.blink.enable = true;
      };

      extraPackages = with pkgs; [
        # Nix
        nil
        nixfmt
        statix
        # Python
        pyright
        # TypeScript/JavaScript
        vtsls
        nodejs
        # Rust (rustaceanvim, clippy checks on save)
        rust-analyzer
        cargo
        rustc
        clippy
        rustfmt
        # JSON/YAML
        vscode-langservers-extracted
        yaml-language-server
        # Markdown
        marksman
        prettier
        # Shell (not covered by a LazyVim extra)
        bash-language-server
        shfmt
        shellcheck
      ];

      # LazyVim's starter clones lazy.nvim into stdpath("data") on first start;
      # that directory is outside lazyvim-nix's control, so let it happen once.
      plugins = {
        bash = ''
          return {
            {
              "neovim/nvim-lspconfig",
              opts = {
                servers = {
                  bashls = {},
                },
              },
            },
            {
              "stevearc/conform.nvim",
              opts = {
                formatters_by_ft = {
                  bash = { "shfmt" },
                  sh = { "shfmt" },
                },
              },
            },
            {
              "mfussenegger/nvim-lint",
              opts = {
                linters_by_ft = {
                  bash = { "shellcheck" },
                  sh = { "shellcheck" },
                },
              },
            },
          }
        '';

        markdown = ''
          return {
            {
              "mfussenegger/nvim-lint",
              opts = {
                linters = {
                  ["markdownlint-cli2"] = {
                    prepend_args = { "--config", "${markdownlintConfig}" },
                  },
                },
              },
            },
            {
              "stevearc/conform.nvim",
              opts = {
                formatters = {
                  ["markdownlint-cli2"] = {
                    prepend_args = { "--config", "${markdownlintConfig}" },
                  },
                },
              },
            },
          }
        '';
      };
    };

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
