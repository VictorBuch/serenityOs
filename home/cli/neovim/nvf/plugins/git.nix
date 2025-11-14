{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      git = {
        enable = true;
        gitsigns = {
          enable = true;
          codeActions.enable = false; # Handled by LSP
        };
      };

      utility.diffview-nvim.enable = true;
    };
  };
}
