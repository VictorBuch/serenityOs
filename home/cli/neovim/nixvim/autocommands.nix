{
  programs.nixvim.autoCmd = [
    # Highlight yank
    {
      event = "TextYankPost";
      group = "highlight_yank";
      callback.__raw = ''
        function()
          vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
        end
      '';
      desc = "Highlight selection on yank";
      pattern = "*";
    }

    # Close special buffers with 'q'
    {
      event = "FileType";
      callback.__raw = ''
        function(event)
          vim.bo[event.buf].buflisted = false
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
        end
      '';
      pattern = [ "qf" "help" "man" "notify" "lspinfo" "trouble" "checkhealth" ];
    }

    # Flutter hot reload on save
    {
      event = "BufWritePost";
      pattern = "*.dart";
      callback.__raw = ''
        function()
          -- Check if Flutter is running
          local flutter_running = vim.fn.system("pgrep -f 'flutter run'"):len() > 0
          if flutter_running then
            vim.cmd('FlutterReload')
          end
        end
      '';
      desc = "Flutter hot reload on save";
    }

    # Close toggleterm with 'q' in normal mode
    {
      event = "TermOpen";
      pattern = "term://*toggleterm#*";
      callback.__raw = ''
        function()
          vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = 0, silent = true })
        end
      '';
      desc = "Close toggleterm with q";
    }
  ];

  programs.nixvim.autoGroups = {
    highlight_yank = {
      clear = true;
    };
  };
}
