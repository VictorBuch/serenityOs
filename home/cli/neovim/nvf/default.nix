{
  config,
  options,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./theme.nix
    ./lsp.nix
    ./completion.nix
    ./treesitter.nix
    ./ui.nix
    ./editor.nix
    ./git.nix
    ./navigation.nix
    ./terminal.nix
    ./tools.nix
    ./keymaps.nix
    ./autocommands.nix
  ];

  options = {
    home.cli.neovim.nvf.enable = lib.mkEnableOption "Enables nvf-based neovim";
  };

  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    home.packages = with pkgs;
      [
        ripgrep
        fd
        fzf
        lazygit

        nodePackages.prettier
        nixfmt-rfc-style

        nodePackages.eslint
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        wl-clipboard # Wayland clipboard (Linux only)
      ];

    programs.nvf = {
      enable = true;
      defaultEditor = true;

      settings.vim = {
        viAlias = true;
        vimAlias = true;

        globals.mapleader = " ";
      };
    };
  };
}
