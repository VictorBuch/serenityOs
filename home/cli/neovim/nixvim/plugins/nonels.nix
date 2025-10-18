{
  # none-ls disabled in favor of conform-nvim + nvim-lint
  # conform-nvim handles: prettier, gofmt, goimports, nixfmt
  # nvim-lint handles: eslint, golangci_lint
  programs.nixvim.plugins.none-ls = {
    enable = false;
  };
}
