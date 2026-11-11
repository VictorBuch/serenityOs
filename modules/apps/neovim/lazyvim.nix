let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
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
        statix
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
    };
in
{
  flake.modules.nixos.lazyvim = module;
  flake.modules.darwin.lazyvim = module;
}
