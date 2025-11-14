{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim.theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
      transparent = true;
    };
  };
}
