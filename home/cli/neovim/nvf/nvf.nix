{
  config,
  options,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.nvf.homeManagerModules.default
  ];

  options = {
    home.cli.neovim.nvf.enable = lib.mkEnableOption "Enables nvf-based neovim";
  };

  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    home.packages = with pkgs; [
      ripgrep
      fd
      fzf
      lazygit
      nodePackages.prettier
      nixfmt-rfc-style
    ];

    programs.nvf = {
      enable = true;
      defaultEditor = true;

      settings.vim = {
        viAlias = true;
        vimAlias = true;

        globals.mapleader = " ";

        options = {
          number = true;
          relativenumber = true;
          splitbelow = true;
          splitright = true;
          scrolloff = 4;
          autoindent = true;
          expandtab = true;
          shiftwidth = 2;
          smartindent = true;
          tabstop = 2;
          ignorecase = true;
          incsearch = true;
          smartcase = true;
          swapfile = false;
          undofile = true;
          termguicolors = true;
          updatetime = 100;
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
          transparent = true;
        };

        autocomplete = {
          nvim-cmp.enable = false;
          blink-cmp.enable = true;
        };

        snippets.luasnip.enable = true;

        lsp = {
          enable = true;
          formatOnSave = true;
          lspkind.enable = true;
          trouble.enable = true;
        };

        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;
          nix.enable = true;
          ts.enable = true;
          go.enable = true;
          dart.enable = true;
          html.enable = true;
          css.enable = true;
          tailwind.enable = true;
          markdown.enable = true;
          lua.enable = true;
          yaml.enable = true;
          bash.enable = true;
        };

        git = {
          enable = true;
          gitsigns.enable = true;
        };

        filetree.neo-tree = {
          enable = true;
          setupOpts = {
            window = {
              mappings = {
                "h" = "close_node";
                "l" = "open";
              };
            };
          };
        };
        telescope.enable = true;

        terminal.toggleterm = {
          enable = true;
          mappings.open = "<C-\\>";
          setupOpts = {
            direction = "horizontal";
            size = 15;
          };
          lazygit = {
            enable = true;
            mappings.open = "<leader>gg";
          };
        };

        statusline.lualine = {
          enable = true;
          theme = "catppuccin";
        };

        tabline.nvimBufferline = {
          enable = true;
          setupOpts = {
            options = {
              style_preset = "minimal";
              seperator_style = "slope";
              show_buffer_close_icon = false;
            };
          };
        };
        mini = {
          comment.enable = true;
          surround.enable = true;
          pairs.enable = true;
        };

        ui = {
          noice.enable = true;
          illuminate.enable = true;
          borders = {
            enable = true;
            globalStyle = "rounded";
          };
          smartcolumn.enable = false;
        };

        visuals = {
          nvim-web-devicons.enable = true;
          indent-blankline.enable = true;
          nvim-cursorline.enable = true;
          # fidget-nvim.enable = true;
          highlight-undo.enable = true;
        };

        notify.nvim-notify.enable = true;
        dashboard.alpha = {
          enable = true;
          theme = null; # Disable default theme to use custom layout
          layout = [
            {
              type = "padding";
              val = 16;
            }
            {
              type = "text";
              val = [
                "                                   "
                "    ⢀⣀⣀⡀      ⣇    ⢀⡀        "
                "  ⢀⣤⣶⣿⣿⣿⣿⣿⣦⡀  ⢀⣀⣸⣿⣆⣀⡀ ⣼⣿⣦⣀⡀    "
                " ⢀⣾⣿⣿⠉⠉⠉⠙⢿⣿⣷⡄⢻⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀  "
                " ⣾⣿⣿⠁  ⣀⣀ ⠹⣿⣿⣿⣄⠙⠛⠁⠄⢸⣿⣿⠟⠛⠛⠛⢿⣿⣷  "
                " ⣿⣿⣿⡀ ⢸⣿⣷ ⢀⣾⣿⣿⣿⣷⣄⡀⠄⠄⣿⣿⡇⠄⠄⠄⣼⣿⣿⠂ "
                " ⢹⣿⣿⣿⣦⣄⣉⣠⣾⣿⣿⡿⢻⣿⣿⣿⣿⣦⣈⣿⣿⣦⣄⣀⣴⣿⣿⠃  "
                "  ⠈⠛⠿⣿⣿⣿⣿⣿⡿⠟⠁⠄⠄⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋   "
                "      ⠉⠉⠉⠁         ⠉⠉⠉⠉⠉      "
                "                                   "
                "        D U C K  I T  U P       "
                "                                   "
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
        comments.comment-nvim.enable = true;
        autopairs.nvim-autopairs.enable = true;
        utility.diffview-nvim.enable = true;
        binds.whichKey.enable = true;
        presence.neocord.enable = false;
        notes.todo-comments.enable = true;

        extraPlugins = with pkgs.vimPlugins; {
          flash-nvim = {
            package = flash-nvim;
            setup = ''
              require('flash').setup({
                labels = "asdfghjklqwertyuiopzxcvbnm",
                search = { multi_window = true, forward = true, wrap = true },
                jump = { autojump = false },
                label = { uppercase = false },
                modes = { char = { enabled = true, jump_labels = true } },
              })
            '';
          };
          dressing-nvim = {
            package = dressing-nvim;
            setup = ''
              require('dressing').setup({
                input = { enabled = true, default_prompt = "Input:", border = "rounded" },
                select = { enabled = true, backend = { "telescope", "builtin" } },
              })
            '';
          };
          conform = {
            package = conform-nvim;
            setup = ''
              require('conform').setup({
                formatters_by_ft = {
                  javascript = { "prettier" }, javascriptreact = { "prettier" },
                  typescript = { "prettier" }, typescriptreact = { "prettier" },
                  vue = { "prettier" }, css = { "prettier" }, scss = { "prettier" },
                  html = { "prettier" }, json = { "prettier" }, yaml = { "prettier" },
                  markdown = { "prettier" }, go = { "gofmt", "goimports" },
                  nix = { "nixfmt" }, dart = { "dart_format" },
                },
                format_on_save = { timeout_ms = 500, lsp_fallback = true },
              })
            '';
          };
          nvim-lint = {
            package = nvim-lint;
            setup = ''
              require('lint').linters_by_ft = {
                javascript = { 'eslint' }, typescript = { 'eslint' },
                javascriptreact = { 'eslint' }, typescriptreact = { 'eslint' },
              }
              vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged" }, {
                callback = function() require("lint").try_lint() end,
              })
            '';
          };
          emmet-vim.package = emmet-vim;
          flutter-tools = {
            package = flutter-tools-nvim;
            setup = ''
              require('flutter-tools').setup({
                decorations = { statusline = { app_version = true, device = true } },
                widget_guides = { enabled = true },
              })
            '';
          };
        };

        maps.normal = {
          "<leader>e" = {
            action = ":Neotree toggle<CR>";
            desc = "Toggle file explorer";
            silent = true;
          };
          "<C-h>" = {
            action = "<C-w>h";
            desc = "Move left";
          };
          "<C-j>" = {
            action = "<C-w>j";
            desc = "Move down";
          };
          "<C-k>" = {
            action = "<C-w>k";
            desc = "Move up";
          };
          "<C-l>" = {
            action = "<C-w>l";
            desc = "Move right";
          };
          "<S-h>" = {
            action = ":BufferLineCyclePrev<CR>";
            desc = "Previous buffer";
            silent = true;
          };
          "<S-l>" = {
            action = ":BufferLineCycleNext<CR>";
            desc = "Next buffer";
            silent = true;
          };
          "<leader>bd" = {
            action = ":bdelete<CR>";
            desc = "Delete buffer";
            silent = true;
          };
          "<leader>bb" = {
            action = ":Telescope buffers<CR>";
            desc = "Switch buffer";
            silent = true;
          };
          "<leader><space>" = {
            action = ":Telescope find_files<CR>";
            desc = "Find files";
            silent = true;
          };
          "<leader>ff" = {
            action = ":Telescope find_files<CR>";
            desc = "Find files";
            silent = true;
          };
          "<leader>/" = {
            action = ":Telescope live_grep<CR>";
            desc = "Live grep";
            silent = true;
          };
          "<leader>fg" = {
            action = ":Telescope live_grep<CR>";
            desc = "Live grep";
            silent = true;
          };
          "<leader>fb" = {
            action = ":Telescope buffers<CR>";
            desc = "Buffers";
            silent = true;
          };
          "<leader>fr" = {
            action = ":Telescope oldfiles<CR>";
            desc = "Recent files";
            silent = true;
          };
          # Git keymaps are provided by gitsigns module
          "<leader>xx" = {
            action = ":Trouble diagnostics toggle<CR>";
            desc = "Diagnostics";
            silent = true;
          };
          "<leader>xX" = {
            action = ":Trouble diagnostics toggle filter.buf=0<CR>";
            desc = "Buffer diagnostics";
            silent = true;
          };
          "<leader>xs" = {
            action = ":Trouble symbols toggle focus=false<CR>";
            desc = "Symbols";
            silent = true;
          };
          "<leader>xl" = {
            action = ":Trouble lsp toggle focus=false win.position=right<CR>";
            desc = "LSP";
            silent = true;
          };
          "<leader>xt" = {
            action = ":TodoTrouble<CR>";
            desc = "Todo Trouble";
            silent = true;
          };
          "<leader>xT" = {
            action = ":TodoTelescope<CR>";
            desc = "Todo Telescope";
            silent = true;
          };
          "<leader>ft" = {
            action = ":ToggleTerm<CR>";
            desc = "Terminal";
            silent = true;
          };
          "s" = {
            action = ":lua require('flash').jump()<CR>";
            desc = "Flash jump";
            silent = true;
          };
          "S" = {
            action = ":lua require('flash').treesitter()<CR>";
            desc = "Flash treesitter";
            silent = true;
          };
          "<leader>cf" = {
            action = ":lua require('conform').format({ timeout_ms = 500, lsp_fallback = true })<CR>";
            desc = "Format";
            silent = true;
          };
          "<Esc>" = {
            action = ":nohlsearch<CR>";
            desc = "Clear highlight";
            silent = true;
          };
          "<leader>Fc" = {
            action = ":Telescope flutter commands<CR>";
            desc = "Flutter commands";
            silent = true;
          };
          "<leader>Fr" = {
            action = ":FlutterRun<CR>";
            desc = "Flutter run";
            silent = true;
          };
          "<leader>Fd" = {
            action = ":FlutterDevices<CR>";
            desc = "Flutter devices";
            silent = true;
          };
          "<leader>Fe" = {
            action = ":FlutterEmulators<CR>";
            desc = "Flutter emulators";
            silent = true;
          };
          "<leader>FR" = {
            action = ":FlutterReload<CR>";
            desc = "Flutter reload";
            silent = true;
          };
          "<leader>Fs" = {
            action = ":FlutterRestart<CR>";
            desc = "Flutter restart";
            silent = true;
          };
          "<leader>Fq" = {
            action = ":FlutterQuit<CR>";
            desc = "Flutter quit";
            silent = true;
          };
        };

        maps.visual = {
          "p" = {
            action = "_dP";
            desc = "Better paste";
            silent = true;
          };
          "<" = {
            action = "<gv";
            desc = "Indent left";
            silent = true;
          };
          ">" = {
            action = ">gv";
            desc = "Indent right";
            silent = true;
          };
          "s" = {
            action = ":lua require('flash').jump()<CR>";
            desc = "Flash jump";
            silent = true;
          };
          # Git keymaps in visual mode are provided by gitsigns module
        };

        luaConfigRC = {
          highlight-yank = ''
            vim.api.nvim_create_autocmd('TextYankPost', {
              group = vim.api.nvim_create_augroup('highlight_yank', {}),
              desc = 'Highlight selection on yank',
              pattern = '*',
              callback = function()
                vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
              end,
            })
          '';
          auto-format = ''
            vim.api.nvim_create_autocmd("BufWritePre", {
              pattern = "*",
              callback = function(args)
                require("conform").format({ bufnr = args.buf })
              end,
            })
          '';
          close-with-q = ''
            vim.api.nvim_create_autocmd("FileType", {
              pattern = { "qf", "help", "man", "notify", "lspinfo", "trouble", "checkhealth" },
              callback = function(event)
                vim.bo[event.buf].buflisted = false
                vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
              end,
            })
          '';
        };
      };
    };
  };
}
