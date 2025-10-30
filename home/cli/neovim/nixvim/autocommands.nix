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
  ];

  programs.nixvim.autoGroups = {
    highlight_yank = {
      clear = true;
    };
  };
}
