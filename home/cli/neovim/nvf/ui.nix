{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      # Dashboard (Alpha with SERENITYVIM ASCII art)
      dashboard.alpha = {
        enable = true;
        theme = null; # Disable default theme to use custom layout
        layout = [
          {
            type = "padding";
            val = 4;
          }
          {
            type = "text";
            val = [
              "                                                                      "
              " ███████╗███████╗██████╗ ███████╗███╗   ██╗██╗████████╗██╗   ██╗██╗███╗   ███╗"
              " ██╔════╝██╔════╝██╔══██╗██╔════╝████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝██║████╗ ████║"
              " ███████╗█████╗  ██████╔╝█████╗  ██╔██╗ ██║██║   ██║    ╚████╔╝ ██║██╔████╔██║"
              " ╚════██║██╔══╝  ██╔══██╗██╔══╝  ██║╚██╗██║██║   ██║     ╚██╔╝  ██║██║╚██╔╝██║"
              " ███████║███████╗██║  ██║███████╗██║ ╚████║██║   ██║      ██║   ██║██║ ╚═╝ ██║"
              " ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝   ╚═╝╚═╝     ╚═╝"
              "                                                                      "
            ];
            opts = {
              position = "center";
              hl = "Type";
            };
          }
          {
            type = "padding";
            val = 2;
          }
          {
            type = "group";
            val = [
              {
                type = "button";
                val = "  Find File";
                on_press = {
                  __raw = "function() vim.cmd('Telescope find_files') end";
                };
                opts = {
                  keymap = [
                    "n"
                    "f"
                    ":Telescope find_files<CR>"
                    {
                      noremap = true;
                      silent = true;
                      nowait = true;
                    }
                  ];
                  shortcut = "f";
                  position = "center";
                  cursor = 3;
                  width = 50;
                  align_shortcut = "right";
                  hl_shortcut = "Keyword";
                };
              }
              {
                type = "button";
                val = "  Recent Files";
                on_press = {
                  __raw = "function() vim.cmd('Telescope oldfiles') end";
                };
                opts = {
                  keymap = [
                    "n"
                    "r"
                    ":Telescope oldfiles<CR>"
                    {
                      noremap = true;
                      silent = true;
                      nowait = true;
                    }
                  ];
                  shortcut = "r";
                  position = "center";
                  cursor = 3;
                  width = 50;
                  align_shortcut = "right";
                  hl_shortcut = "Keyword";
                };
              }
              {
                type = "button";
                val = "  Find Text";
                on_press = {
                  __raw = "function() vim.cmd('Telescope live_grep') end";
                };
                opts = {
                  keymap = [
                    "n"
                    "g"
                    ":Telescope live_grep<CR>"
                    {
                      noremap = true;
                      silent = true;
                      nowait = true;
                    }
                  ];
                  shortcut = "g";
                  position = "center";
                  cursor = 3;
                  width = 50;
                  align_shortcut = "right";
                  hl_shortcut = "Keyword";
                };
              }
              {
                type = "button";
                val = "  File Browser";
                on_press = {
                  __raw = "function() vim.cmd('Neotree toggle') end";
                };
                opts = {
                  keymap = [
                    "n"
                    "e"
                    ":Neotree toggle<CR>"
                    {
                      noremap = true;
                      silent = true;
                      nowait = true;
                    }
                  ];
                  shortcut = "e";
                  position = "center";
                  cursor = 3;
                  width = 50;
                  align_shortcut = "right";
                  hl_shortcut = "Keyword";
                };
              }
              {
                type = "button";
                val = "  Quit Neovim";
                on_press = {
                  __raw = "function() vim.cmd('qa') end";
                };
                opts = {
                  keymap = [
                    "n"
                    "q"
                    ":qa<CR>"
                    {
                      noremap = true;
                      silent = true;
                      nowait = true;
                    }
                  ];
                  shortcut = "q";
                  position = "center";
                  cursor = 3;
                  width = 50;
                  align_shortcut = "right";
                  hl_shortcut = "Keyword";
                };
              }
            ];
            opts = {
              spacing = 1;
            };
          }
          {
            type = "padding";
            val = 2;
          }
        ];
      };

      # Noice - Enhanced UI for messages, cmdline, and popupmenu
      ui = {
        noice.enable = true;
        illuminate.enable = true;
        borders = {
          enable = true;
          globalStyle = "rounded";
        };
        smartcolumn.enable = false;
      };

      # Notifications
      notify.nvim-notify.enable = true;

      # Statusline
      statusline.lualine = {
        enable = true;
        theme = "catppuccin";
      };

      # Bufferline (tabline)
      tabline.nvimBufferline = {
        enable = true;
        setupOpts = {
          options = {
            numbers = "none";
            style_preset = "minimal";
            separator_style = "thin";
            show_buffer_close_icons = false;
            diagnostics = false;
          };
        };
      };

      # Visual enhancements
      visuals = {
        nvim-web-devicons.enable = true;
        indent-blankline.enable = true;
        nvim-cursorline.enable = true;
        highlight-undo.enable = true;
      };
    };
  };
}
