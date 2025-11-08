{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      mini = {
        ai = {
          enable = true;
        };
        comment = {
          enable = true;
          setupOpts = {
            mappings = {
              comment = "<leader>gc";
              comment_line = "<leader>gc";
              comment_visual = "<leader>gc";
              textobject = "<leader>gc";
            };
          };
        };
        surround = {
          enable = true;
          setupOpts = {
            mappings = {
              add = "sa"; # Add surrounding in Normal and Visual modes
              delete = "sd"; # Delete surrounding
              find = "sf"; # Find surrounding (to the right)
              find_left = "sF"; # Find surrounding (to the left)
              highlight = "sh"; # Highlight surrounding
              replace = "sr"; # Replace surrounding
              update_n_lines = "sn"; # Update n_lines
            };
          };
        };
        pairs.enable = true; # Auto pairs
        bufremove.enable = true;
      };

      binds.whichKey.enable = true;

      # Autopairs (additional to mini.pairs for more features)
      autopairs.nvim-autopairs.enable = false;

      # Comments
      comments.comment-nvim.enable = false;

      # Additional editor enhancement plugins via extraPlugins
      extraPlugins = with pkgs.vimPlugins; {
        vim-tmux-navigator = {
          package = vim-tmux-navigator;
        };

        # Yanky for yank ring management
        yanky-nvim = {
          package = yanky-nvim;
          setup = ''
            require('yanky').setup({
              ring = {
                history_length = 100,
                storage = "shada",
                sync_with_numbered_registers = true,
                cancel_event = "update",
              },
              picker = {
                select = {
                  action = nil,
                },
                telescope = {
                  enable = true,
                  use_default_mappings = true,
                },
              },
              system_clipboard = {
                sync_with_ring = true,
              },
              highlight = {
                on_put = true,
                on_yank = true,
                timer = 300,
              },
              preserve_cursor_position = {
                enabled = true,
              },
            })
          '';
        };

        # Dressing for better UI select/input
        dressing-nvim = {
          package = dressing-nvim;
          setup = ''
            require('dressing').setup({
              input = {
                enabled = true,
                default_prompt = "Input:",
                border = "rounded",
                prefer_width = 40,
                max_width = nil,
                min_width = 20,
              },
              select = {
                enabled = true,
                backend = { "telescope", "builtin" },
                telescope = nil,
                builtin = {
                  border = "rounded",
                },
              },
            })
          '';
        };
      };
    };
  };
}
