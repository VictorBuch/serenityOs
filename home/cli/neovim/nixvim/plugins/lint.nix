{
  programs.nixvim.plugins.lint = {
    enable = true;
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
    autoCmd = {
      event = [ "BufWritePost" "TextChanged" ];
      callback.__raw = ''
        function()
          require("lint").try_lint()
        end
      '';
    };
  };
}
