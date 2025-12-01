{
  programs.nixvim = {
    plugins.gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        current_line_blame_opts = {
          virt_text = true;
          virt_text_pos = "eol";
          delay = 500;
          ignore_whitespace = false;
        };
        signs = {
          add = {
            text = "│";
          };
          change = {
            text = "│";
          };
          delete = {
            text = "_";
          };
          topdelete = {
            text = "‾";
          };
          changedelete = {
            text = "~";
          };
          untracked = {
            text = "┆";
          };
        };
      };
    };

    keymaps = [
      # Navigation
      {
        mode = "n";
        key = "]c";
        action.__raw = ''
          function()
            if vim.wo.diff then
              vim.cmd.normal({']c', bang = true})
            else
              require('gitsigns').nav_hunk('next')
            end
          end
        '';
        options = {
          desc = "Next git hunk";
          expr = true;
        };
      }
      {
        mode = "n";
        key = "[c";
        action.__raw = ''
          function()
            if vim.wo.diff then
              vim.cmd.normal({'[c', bang = true})
            else
              require('gitsigns').nav_hunk('prev')
            end
          end
        '';
        options = {
          desc = "Previous git hunk";
          expr = true;
        };
      }

      # Actions
      {
        mode = "n";
        key = "<leader>gs";
        action = ":Gitsigns stage_hunk<CR>";
        options = {
          desc = "Git stage hunk";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>gs";
        action = ":Gitsigns stage_hunk<CR>";
        options = {
          desc = "Git stage hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gr";
        action = ":Gitsigns reset_hunk<CR>";
        options = {
          desc = "Git reset hunk";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>gr";
        action = ":Gitsigns reset_hunk<CR>";
        options = {
          desc = "Git reset hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gS";
        action = "<cmd>Gitsigns stage_buffer<CR>";
        options = {
          desc = "Git stage buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gu";
        action = "<cmd>Gitsigns undo_stage_hunk<CR>";
        options = {
          desc = "Git undo stage hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gR";
        action = "<cmd>Gitsigns reset_buffer<CR>";
        options = {
          desc = "Git reset buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options = {
          desc = "Git preview hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gb";
        action.__raw = "function() require('gitsigns').blame_line({ full = true }) end";
        options = {
          desc = "Git blame line";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>Gitsigns diffthis<CR>";
        options = {
          desc = "Git diff";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gD";
        action.__raw = "function() require('gitsigns').diffthis('~') end";
        options = {
          desc = "Git diff ~";
          silent = true;
        };
      }

      # Text object
      {
        mode = [
          "o"
          "x"
        ];
        key = "ih";
        action = ":<C-U>Gitsigns select_hunk<CR>";
        options = {
          desc = "Git hunk text object";
          silent = true;
        };
      }
    ];
  };
}
