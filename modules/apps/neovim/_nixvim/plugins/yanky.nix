{
  programs.nixvim = {
    plugins.yanky = {
      enable = true;
      enableTelescope = true;
      settings = {
        highlight = {
          on_put = true;
          on_yank = true;
          timer = 300;
        };
        preserve_cursor_position = {
          enabled = true;
        };
      };
    };

    keymaps = [
      # LazyVim-style yanky keymaps
      # Basic put operations
      {
        mode = [ "n" "x" ];
        key = "p";
        action = "<Plug>(YankyPutAfter)";
        options = {
          desc = "Put text after cursor";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "P";
        action = "<Plug>(YankyPutBefore)";
        options = {
          desc = "Put text before cursor";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "gp";
        action = "<Plug>(YankyGPutAfter)";
        options = {
          desc = "Put text after selection";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "gP";
        action = "<Plug>(YankyGPutBefore)";
        options = {
          desc = "Put text before selection";
          silent = true;
        };
      }
      # Yank history navigation (LazyVim uses [y and ]y)
      {
        mode = "n";
        key = "[y";
        action = "<Plug>(YankyCycleForward)";
        options = {
          desc = "Cycle forward through yank history";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "]y";
        action = "<Plug>(YankyCycleBackward)";
        options = {
          desc = "Cycle backward through yank history";
          silent = true;
        };
      }
      # Indenting put operations
      {
        mode = [ "n" "x" ];
        key = ">p";
        action = "<Plug>(YankyPutIndentAfterShiftRight)";
        options = {
          desc = "Put and indent right";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = ">P";
        action = "<Plug>(YankyPutIndentBeforeShiftRight)";
        options = {
          desc = "Put before and indent right";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "<p";
        action = "<Plug>(YankyPutIndentAfterShiftLeft)";
        options = {
          desc = "Put and indent left";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "<P";
        action = "<Plug>(YankyPutIndentBeforeShiftLeft)";
        options = {
          desc = "Put before and indent left";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "=p";
        action = "<Plug>(YankyPutIndentAfterFilter)";
        options = {
          desc = "Put after applying a filter";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "=P";
        action = "<Plug>(YankyPutIndentBeforeFilter)";
        options = {
          desc = "Put before applying a filter";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "]p";
        action = "<Plug>(YankyPutIndentAfterLinewise)";
        options = {
          desc = "Put indented after cursor (linewise)";
          silent = true;
        };
      }
      {
        mode = [ "n" "x" ];
        key = "[p";
        action = "<Plug>(YankyPutIndentBeforeLinewise)";
        options = {
          desc = "Put indented before cursor (linewise)";
          silent = true;
        };
      }
      # Open yank history with Telescope (LazyVim uses <leader>p)
      {
        mode = "n";
        key = "<leader>p";
        action = ":Telescope yank_history<CR>";
        options = {
          desc = "Open yank history";
          silent = true;
        };
      }
    ];
  };
}
