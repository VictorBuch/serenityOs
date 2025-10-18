{
  programs.nixvim.plugins.lint = {
    lintersByFt = {
      # JavaScript/TypeScript
      javascript = [ "eslint" ];
      javascriptreact = [ "eslint" ];
      typescript = [ "eslint" ];
      typescriptreact = [ "eslint" ];
      vue = [ "eslint" ];
      svelte = [ "eslint" ];

      # Go
      go = [ "golangcilint" ];
    };
  };
}
