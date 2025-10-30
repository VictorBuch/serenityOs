{
  programs.nixvim = {
    plugins.toggleterm = {
      enable = true;
      settings = {
        size = 15;
        hide_numbers = true;
        shade_terminals = true;
        start_in_insert = true;
        insert_mappings = true;
        terminal_mappings = true;
        persist_size = true;
        persist_mode = true;
        direction = "horizontal";
        close_on_exit = true;
        shell.__raw = "vim.o.shell";
        auto_scroll = true;
        float_opts = {
          border = "curved";
        };
      };
    };

    extraConfigLua = ''
      -- Setup custom terminals
      local Terminal = require('toggleterm.terminal').Terminal

      -- Lazygit in floating window
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        count = 5,
        hidden = true,
        float_opts = {
          border = "curved",
          width = function()
            return math.floor(vim.o.columns * 0.9)
          end,
          height = function()
            return math.floor(vim.o.lines * 0.9)
          end,
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
        end,
      })

      -- Bottom terminal (using count 1)
      local bottom_terminal = Terminal:new({
        direction = "horizontal",
        count = 1,
        hidden = true,
        size = 15,
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
      })

      -- Make functions globally accessible
      _G._lazygit_toggle = function()
        lazygit:toggle()
      end

      _G._bottom_terminal_toggle = function()
        bottom_terminal:toggle()
      end
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action.__raw = "function() _lazygit_toggle() end";
        options = {
          desc = "Lazygit";
          silent = true;
          noremap = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ft";
        action.__raw = "function() _bottom_terminal_toggle() end";
        options = {
          desc = "Terminal (bottom)";
          silent = true;
          noremap = true;
        };
      }
      {
        mode = "n";
        key = "<C-\\>";
        action = "<cmd>ToggleTerm<CR>";
        options = {
          desc = "Toggle terminal";
          silent = true;
        };
      }
      {
        mode = "t";
        key = "<C-\\>";
        action = "<cmd>ToggleTerm<CR>";
        options = {
          desc = "Toggle terminal";
          silent = true;
        };
      }
    ];
  };
}
