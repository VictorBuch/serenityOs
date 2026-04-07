{
  programs.nixvim.opts = {
    updatetime = 100; # Faster completion
    autoread = true; # Auto-reload files changed outside of Neovim
    number = true;
    relativenumber = true;
    splitbelow = true;
    splitright = true;
    scrolloff = 4;

    autoindent = true;
    clipboard = "unnamedplus";
    expandtab = true;
    shiftwidth = 2;
    smartindent = true;
    tabstop = 2;

    ignorecase = true;
    incsearch = true;
    smartcase = true;
    wildmode = "list:longest";

    swapfile = false;
    undofile = true; # Build-in persistent undo

    termguicolors = true;
    cursorline = true; # Highlight current line
  };
}
