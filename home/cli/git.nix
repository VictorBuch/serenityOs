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

        # User configuration
        userName = "VictorBuch";
        userEmail = "victorbuch@protonmail.com";

        # Useful aliases
        aliases = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          amend = "commit --amend";
          contributors = "shortlog -sn";
        };

        # Additional git configuration
        extraConfig = {
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

      # Delta configuration for beautiful diffs (configured through git in HM 25.05)
      programs.git.delta = {
        enable = true;
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
