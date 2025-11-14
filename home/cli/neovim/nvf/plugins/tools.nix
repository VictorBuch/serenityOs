{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {

      # Todo-comments
      notes.todo-comments.enable = true;

      utility = {
        motion = {
          flash-nvim = {
            enable = true;
          };
        };
        # Snacks utility plugin (native nvf support)
        snacks-nvim = {
          enable = true;
          setupOpts = {
            bigfile.enabled = true;
            input.enabled = true;
            notifier = {
              enabled = true;
              timeout = 3000;
            };
            picker.enabled = true; # Fixes code action menu bugs
            quickfile.enabled = true;
            words.enabled = true;
            scroll.enabled = false;
            statuscolumn.enabled = false;
          };
        };
      };

      # Additional utility plugins via extraPlugins
      extraPlugins = with pkgs.vimPlugins; {
        # Persistence for session management
        persistence-nvim = {
          package = persistence-nvim;
          setup = ''
            require('persistence').setup({
              dir = vim.fn.expand(vim.fn.stdpath('state') .. '/sessions/'),
              options = { 'buffers', 'curdir', 'tabpages', 'winsize' },
              pre_save = nil,
            })
          '';
        };

        # Twilight for dimming inactive code
        twilight-nvim = {
          package = twilight-nvim;
          setup = ''
            require('twilight').setup({
              dimming = {
                alpha = 0.25,
                color = { 'Normal', '#ffffff' },
                inactive = false,
              },
              context = 10,
              treesitter = true,
              expand = {
                'function',
                'method',
                'table',
                'if_statement',
              },
            })
          '';
        };

        # Zen-mode for distraction-free writing
        zen-mode-nvim = {
          package = zen-mode-nvim;
          setup = ''
            require('zen-mode').setup({
              window = {
                backdrop = 0.95,
                width = 120,
                height = 1,
                options = {
                  signcolumn = 'no',
                  number = false,
                  relativenumber = false,
                  cursorline = false,
                  cursorcolumn = false,
                  foldcolumn = '0',
                  list = false,
                },
              },
              plugins = {
                options = {
                  enabled = true,
                  ruler = false,
                  showcmd = false,
                },
                twilight = { enabled = true },
                gitsigns = { enabled = false },
                tmux = { enabled = false },
              },
            })
          '';
        };
      };
    };
  };
}
