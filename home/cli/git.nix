args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  _file = toString ./.;
  name = "git";
  description = "Git version control";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.git = {
        enable = true;
        package = pkgs.git;

        # Git settings (new format for HM 26.05)
        settings = {
          # User configuration
          user = {
            name = "VictorBuch";
            email = "victorbuch@protonmail.com";
          };

          # Useful aliases
          alias = {
            st = "status";
            co = "checkout";
            br = "branch";
            ci = "commit";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            amend = "commit --amend";
            contributors = "shortlog -sn";
          };

          # Modern defaults
          init = {
            defaultBranch = "main";
          };

          # Pull and push behavior
          pull = {
            rebase = true;
          };
          push = {
            autoSetupRemote = true;
            default = "current";
          };

          # Better diff and merge
          diff = {
            colorMoved = "default";
          };
          merge = {
            conflictStyle = "zdiff3";
          };

          # Rebase settings
          rebase = {
            autoStash = true;
          };

          # Remember conflict resolutions
          rerere = {
            enabled = true;
          };

          # Sort branches by recent activity
          branch = {
            sort = "-committerdate";
          };

          # SSH commit signing via FIDO2 YubiKey
          commit = {
            gpgsign = true;
          };
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile = "~/.config/git/allowed_signers";
          };
          user = {
            signingkey = "~/.ssh/id_ed25519_sk.pub";
          };
        };

        # Global gitignore patterns
        ignores = [
          # macOS
          ".DS_Store"
          "._*"

          # Editor files
          "*.swp"
          "*.swo"
          "*~"
          ".vscode/"
          ".idea/"

          # Environment and secrets
          ".env"
          ".env.local"
          ".env.*.local"

          # Node.js
          "node_modules/"

          # Build artifacts
          "*.log"
          "dist/"
          "build/"

          # Nix
          ".direnv/"
          "result"
          "result-*"
        ];
      };

      # Allowed signers for SSH commit verification
      # Add both YubiKey public keys so commits from either machine verify correctly
      home.file.".config/git/allowed_signers".text = ''
        victorbuch@protonmail.com sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINIkyb8ktnpdCcN3S2k6gkSGqtoMeAATgUaF3mET/FP7AAAABHNzaDo= jayne@yubikey-5c-nano
      '';

      # Delta configuration for beautiful diffs (separate program in HM 26.05)
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          side-by-side = false;
          line-numbers = true;
          syntax-theme = "base16";

          # Catppuccin Mocha colors
          minus-style = "syntax #3c2633";
          minus-emph-style = "syntax #543a48";
          plus-style = "syntax #2c3446";
          plus-emph-style = "syntax #414559";
          map-styles = "bold purple => syntax #332e41, bold cyan => syntax #2d3a4b";

          # Decorations
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow";
          file-decoration-style = "none";
          hunk-header-style = "file line-number syntax";
          hunk-header-decoration-style = "blue box";
        };
      };
    };
} args
