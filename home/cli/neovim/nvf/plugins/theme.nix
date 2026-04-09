{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim.theme = {
      enable = true;
      name = lib.mkForce "catppuccin";
      style = "mocha";
      transparent = lib.mkForce true;
    };
  };
}
