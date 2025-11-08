{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      terminal.toggleterm = {
        enable = true;
        mappings.open = "<C-\\>";
        setupOpts = {
          direction = "float";
          shade_terminals = true;
          shading_factor = 2;
          start_in_insert = true;
          persist_size = true;
          close_on_exit = true;
          float_opts = {
            border = "rounded";
          };
        };
        lazygit = {
          enable = true;
          direction = "float";
          mappings.open = "<leader>gg";
        };
      };
    };
  };
}
