{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim.options = {
      # Line numbers
      number = true;
      relativenumber = true;

      # Splits
      splitbelow = true;
      splitright = true;

      # Scrolling
      scrolloff = 4;

      # Indentation
      autoindent = true;
      expandtab = true;
      shiftwidth = 2;
      smartindent = true;
      tabstop = 2;

      # Search
      ignorecase = true;
      incsearch = true;
      smartcase = true;

      # Wildmenu
      wildmode = "list:longest";

      # Files
      swapfile = false;
      undofile = true;

      # UI
      termguicolors = true;
      updatetime = 100;

      # Clipboard (wl-clipboard on Linux, system clipboard on macOS)
      clipboard = "unnamedplus";
    };
  };
}
