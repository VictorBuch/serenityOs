{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      telescope = {
        enable = true;
        setupOpts = {
          defaults = {
            mappings = {
              i = {
                # Ctrl+j/k for navigating in insert mode
                "<C-j>" = {
                  __raw = "require('telescope.actions').move_selection_next";
                };
                "<C-k>" = {
                  __raw = "require('telescope.actions').move_selection_previous";
                };
              };
              n = {
                # Ctrl+j/k for navigating in normal mode
                "<C-j>" = {
                  __raw = "require('telescope.actions').move_selection_next";
                };
                "<C-k>" = {
                  __raw = "require('telescope.actions').move_selection_previous";
                };
              };
            };
            layout_strategy = "horizontal";
            layout_config = {
              width = 0.95;
              height = 0.90;
              horizontal = {
                preview_width = 0.55;
              };
            };
            file_ignore_patterns = [
              ".next/"
              "node_modules/"
              ".git/"
              "dist/"
              "build/"
              ".cache/"
            ];
          };
        };
      };

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
