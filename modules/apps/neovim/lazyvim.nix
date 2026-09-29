args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "lazyvim";
  category = "neovim";
  description = "Plain Neovim plus the tools LazyVim needs; config lives unmanaged in ~/.config/nvim";
  packages = { pkgs, ... }: with pkgs; [
    neovim
    git
    curl
    ripgrep
    fd
    fzf
    lazygit
    tree-sitter
    gcc
    gnumake
    unzip
    nodejs
    python3
    lua-language-server
    stylua
    nixd
    nixfmt
    bash-language-server
    shfmt
    typescript-language-server
    vtsls
    tailwindcss-language-server
    yaml-language-server
    vscode-langservers-extracted
    gopls
    rust-analyzer
    pyright
  ];
} args
