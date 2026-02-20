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
    inputs.nixvim.homeModules.nixvim
    ./options.nix
    ./keymaps.nix
    ./autocommands.nix
    # Plugin configurations
    ./plugins/alpha.nix
    ./plugins/blink-cmp.nix
    ./plugins/bufferline.nix
    ./plugins/conform.nix
    ./plugins/diffview.nix
    ./plugins/emmet.nix
    ./plugins/flash.nix
    ./plugins/flutter-tools.nix
    ./plugins/gitsigns.nix
    ./plugins/indent-blankline.nix
    ./plugins/lint.nix
    ./plugins/lsp.nix
    ./plugins/lualine.nix
    ./plugins/mini.nix
    ./plugins/mini-bufremove.nix
    ./plugins/neotree.nix
    ./plugins/noice.nix
    ./plugins/nonels.nix
    ./plugins/notify.nix
    ./plugins/persistence.nix
    ./plugins/snacks.nix
    ./plugins/telescope.nix
    ./plugins/todo-comments.nix
    ./plugins/toggleterm.nix
    ./plugins/treesitter.nix
    ./plugins/trouble.nix
    ./plugins/twilight.nix
    ./plugins/vim-tmux-navigator.nix
    ./plugins/web-devicons.nix
    ./plugins/yanky.nix
    ./plugins/yazi.nix
    ./plugins/zen-mode.nix
  ];

  options = {
    home.cli.neovim.nixvim.enable = lib.mkEnableOption "Enables nixvim-based neovim";
  };

  config = lib.mkIf config.home.cli.neovim.nixvim.enable {
    home.packages = with pkgs; [
      ripgrep
      fd
      fzf
      lazygit
      nodePackages.prettier
      nixfmt
    ];
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      globals.mapleader = " ";
      clipboard.providers.wl-copy.enable = pkgs.stdenv.isLinux;

      colorschemes.catppuccin = {
        enable = true;
        settings = {
          flavour = "mocha";
          term_colors = true;
          transparent_background = true;
          dim_inactive = {
            enabled = false;
          };
          styles = {
            comments = [ "italic" ];
            conditionals = [ "italic" ];
          };
          integrations = {
            blink_cmp = true;
            gitsigns = true;
            nvimtree = true;
            treesitter = true;
            notify = true;
            mini.enabled = true;
            telescope.enabled = true;
            which_key = true;
          };
        };
      };
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = {
        which-key.enable = true;
        lazygit.enable = true;
      };
    };
  };
}
