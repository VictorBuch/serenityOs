{
  programs.nixvim.plugins.lsp = {
    enable = true;
    keymaps.lspBuf = {
      "gd" = "definition";
      "K" = "hover";
    };
    servers = {
      # Core language servers
      jsonls.enable = true;
      lua_ls = {
        enable = true;
        settings.telemetry.enable = false;
      };
      yamlls.enable = true;
      nixd.enable = true;
      gopls.enable = true;

      # Dart/Flutter
      dartls = {
        enable = true;
      };

      # Frontend language servers
      ts_ls.enable = true;
      svelte.enable = true;
      vue_ls = {
        enable = true;
      };
      eslint = {
        enable = true;
        extraOptions = {
          settings = {
            format = false; # Use prettier for formatting
          };
        };
      };

      # Web language servers
      html.enable = true;
      cssls.enable = true;
      tailwindcss.enable = true;
      emmet_ls = {
        enable = true;
        filetypes = [
          "html"
          "css"
          "scss"
          "javascript"
          "javascriptreact"
          "typescript"
          "typescriptreact"
          "vue"
          "svelte"
        ];
      };
    };
  };
}
