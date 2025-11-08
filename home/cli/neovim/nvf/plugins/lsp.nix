{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      lsp = {
        enable = true;
        formatOnSave = true;
        lspkind.enable = true;
        trouble.enable = true;
      };

      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        # Nix
        nix = {
          enable = true;
          format.enable = true;
          format.type = "nixfmt";
        };

        # TypeScript/JavaScript
        ts = {
          enable = true;
          format.enable = true;
          format.type = "prettier";
          extraDiagnostics.enable = true;
          extraDiagnostics.types = [ "eslint_d" ];
        };

        # Go
        go = {
          enable = true;
          format.enable = true;
          format.type = "gofumpt";
          lsp.enable = true;
        };

        # Dart/Flutter
        dart = {
          enable = true;
          flutter-tools = {
            enable = true;
            color.enable = true; # LSP color support
          };
        };

        # HTML
        html = {
          enable = true;
          treesitter = {
            enable = true;
            autotagHtml = true;
          };
        };

        # CSS
        css = {
          enable = true;
          format.enable = true;
          format.type = "prettier";
        };

        # Tailwind CSS
        tailwind.enable = true;

        # Markdown
        markdown = {
          enable = true;
          format.enable = true;
          format.type = "prettierd";
        };

        # Lua
        lua.enable = true;

        # YAML
        yaml.enable = true;

        # Bash
        bash.enable = true;
      };

      extraPlugins = with pkgs.vimPlugins; {
        emmet-vim.package = emmet-vim;
      };
    };
  };
}
