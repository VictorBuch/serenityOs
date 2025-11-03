{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      telescope.enable = true;

      filetree.neo-tree = {
        enable = true;
        setupOpts = {
          close_if_last_window = true;
          filesystem = {
            filtered_items = {
              hide_gitignored = false;
              hide_dotfiles = false;
              hide_by_name = {
                "node_modules" = false;
              };
            };
            follow_current_file = {
              enabled = true;
            };
          };
          window = {
            mappings = {
              "h" = "close_node";
              "l" = "open";
            };
          };
        };
      };

      extraPlugins = with pkgs.vimPlugins; {
        yazi-nvim = {
          package = yazi-nvim;
          setup = ''
            require('yazi').setup({
              open_for_directories = false,
            })
          '';
        };
      };
    };
  };
}
