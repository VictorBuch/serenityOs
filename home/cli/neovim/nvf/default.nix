{
  config,
  options,
  pkgs,
  lib,
  inputs,
  ...
}:

# https://notashelf.github.io/nvf/options.html
{
  imports = [
    inputs.nvf.homeManagerModules.default
    # Configuration files
    ./options.nix
    ./keymaps.nix
    ./autocommands.nix
    # Plugin configurations
    ./plugins/theme.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/treesitter.nix
    ./plugins/ui.nix
    ./plugins/editor.nix
    ./plugins/git.nix
    ./plugins/navigation.nix
    ./plugins/terminal.nix
    ./plugins/tools.nix
  ];

  options = {
    home.cli.neovim.nvf.enable = lib.mkEnableOption "Enables nvf-based neovim";
  };

  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    home.packages =
      with pkgs.unstable;
      [
        ripgrep
        fd
        fzf
        lazygit

        # Formatters
        nodePackages.prettier
        nixfmt-rfc-style

        # Linters
        nodePackages.eslint_d

        # LSP servers
        emmet-ls # Emmet language server for HTML/CSS/JSX

        # Go development tools
        go
        gopls # Go LSP server
        gofumpt # Stricter gofmt
        goimports-reviser # Import organizer
        golangci-lint # Go linter
        delve # Go debugger
        gotools # Additional go tools (godoc, etc.)
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
