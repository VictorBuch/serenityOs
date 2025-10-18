{
  programs.nixvim.plugins.conform-nvim = {
    settings = {
      formatters_by_ft = {
        # JavaScript/TypeScript/Web
        javascript = [ "prettier" ];
        javascriptreact = [ "prettier" ];
        typescript = [ "prettier" ];
        typescriptreact = [ "prettier" ];
        vue = [ "prettier" ];
        css = [ "prettier" ];
        scss = [ "prettier" ];
        less = [ "prettier" ];
        html = [ "prettier" ];
        json = [ "prettier" ];
        jsonc = [ "prettier" ];
        yaml = [ "prettier" ];
        markdown = [ "prettier" ];
        "markdown.mdx" = [ "prettier" ];
        graphql = [ "prettier" ];
        handlebars = [ "prettier" ];

        # Go
        go = [
          "gofmt"
          "goimports"
        ];

        # Nix
        nix = [ "nixfmt" ];

        # Dart/Flutter
        dart = [ "dart_format" ];
      };
      format_on_save = {
        lsp_fallback = true;
        timeout_ms = 500;
      };
    };
  };
}
