{
  programs.nixvim.keymaps = [
    {
      action = "<cmd>Telescope find_files<CR>";
      key = "<leader><leader>";
    }
    {
      action = "<cmd>Telescope live_grep<CR>";
      key = "<leader>/";
    }
    {
      action = "<cmd>Telescope oldfiles<CR>";
      key = "<leader>fr";
    }
    {
      action = "<cmd>Telescope buffers<CR>";
      key = "<leader>fb";
    }
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      options = {
        desc = "Move left";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options = {
        desc = "Move down";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options = {
        desc = "Move up";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options = {
        desc = "Move right";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<";
      action = "<gv";
      options = {
        desc = "Stay in indent mode";
        silent = true;
      };
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      options = {
        desc = "Stay in indent mode";
        silent = true;
      };
    }
    {
      mode = "x";
      key = "J";
      action = ":move '>+1<CR>gv-gv";
      options = {
        desc = "Move text up and down";
        silent = true;
      };
    }
    {
      mode = "x";
      key = "K";
      action = ":move '>-2<CR>gv-gv";
      options = {
        desc = "Move text up and down";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>e";
      action = ":Neotree action=focus reveal toggle<CR>";
      options.silent = true;
    }
    {
      mode = "n";
      key = "<S-l>";
      action = ":BufferLineCycleNext<CR>";
      options = {
        desc = "Next buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<S-h>";
      action = ":BufferLineCyclePrev<CR>";
      options = {
        desc = "Previous buffer";
        silent = true;
      };
    }
    # Flutter keymaps
    {
      mode = "n";
      key = "<leader>Fc";
      action = "<cmd>Telescope flutter commands<CR>";
      options = {
        desc = "Flutter Commands";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fr";
      action = "<cmd>FlutterRun<CR>";
      options = {
        desc = "Flutter Run";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fd";
      action = "<cmd>FlutterDevices<CR>";
      options = {
        desc = "Flutter Devices";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fe";
      action = "<cmd>FlutterEmulators<CR>";
      options = {
        desc = "Flutter Emulators";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>FR";
      action = "<cmd>FlutterReload<CR>";
      options = {
        desc = "Flutter Hot Reload";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fs";
      action = "<cmd>FlutterRestart<CR>";
      options = {
        desc = "Flutter Restart";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fq";
      action = "<cmd>FlutterQuit<CR>";
      options = {
        desc = "Flutter Quit";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Ft";
      action = "<cmd>FlutterDevTools<CR>";
      options = {
        desc = "Flutter DevTools";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fo";
      action = "<cmd>FlutterOutlineToggle<CR>";
      options = {
        desc = "Flutter Outline";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fl";
      action = "<cmd>FlutterLogToggle<CR>";
      options = {
        desc = "Flutter Logs";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fa";
      action.__raw = ''
        function()
          vim.fn.jobstart("flutter emulators --launch Pixel_6_API_35", { detach = true })
          vim.notify("Launching Pixel 6 emulator...", vim.log.levels.INFO)
        end
      '';
      options = {
        desc = "Flutter: Launch Android Emulator";
        silent = true;
      };
    }
    # LazyVim-style terminal keymaps
    {
      mode = "n";
      key = "<leader>ft";
      action = "<cmd>ToggleTerm<CR>";
      options = {
        desc = "Terminal (Root Dir)";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>fT";
      action = "<cmd>ToggleTerm dir=%:p:h<CR>";
      options = {
        desc = "Terminal (cwd)";
        silent = true;
      };
    }
    # LazyVim-style git keymaps
    {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>LazyGit<CR>";
      options = {
        desc = "LazyGit (Root Dir)";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>gb";
      action = "<cmd>Gitsigns blame_line<CR>";
      options = {
        desc = "Git Blame Line";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>Gitsigns diffthis<CR>";
      options = {
        desc = "Git Diff";
        silent = true;
      };
    }
    # Buffer keymaps
    {
      mode = "n";
      key = "<leader>bb";
      action = "<cmd>Telescope buffers<CR>";
      options = {
        desc = "Switch Buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bd";
      action.__raw = "function() require('mini.bufremove').delete(0, false) end";
      options = {
        desc = "Delete Buffer";
        silent = true;
      };
    }
    # Additional buffer management from nvf
    {
      mode = "n";
      key = "<leader>bo";
      action = "<cmd>BufferLineCloseOthers<CR>";
      options = {
        desc = "Delete other buffers";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bD";
      action = "<cmd>bdelete | close<CR>";
      options = {
        desc = "Delete buffer and window";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bl";
      action = "<cmd>BufferLineCloseLeft<CR>";
      options = {
        desc = "Delete buffers to the left";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>br";
      action = "<cmd>BufferLineCloseRight<CR>";
      options = {
        desc = "Delete buffers to the right";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>BufferLineTogglePin<CR>";
      options = {
        desc = "Toggle pin";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bP";
      action = "<cmd>BufferLineGroupClose ungrouped<CR>";
      options = {
        desc = "Delete non-pinned buffers";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "[b";
      action = "<cmd>BufferLineCyclePrev<CR>";
      options = {
        desc = "Previous buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "]b";
      action = "<cmd>BufferLineCycleNext<CR>";
      options = {
        desc = "Next buffer";
        silent = true;
      };
    }
    # LSP keybindings from nvf
    {
      mode = "n";
      key = "gr";
      action.__raw = "function() vim.lsp.buf.references() end";
      options = {
        desc = "Goto references";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gI";
      action.__raw = "function() vim.lsp.buf.implementation() end";
      options = {
        desc = "Goto implementation";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gy";
      action.__raw = "function() vim.lsp.buf.type_definition() end";
      options = {
        desc = "Goto type definition";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gD";
      action.__raw = "function() vim.lsp.buf.declaration() end";
      options = {
        desc = "Goto declaration";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gK";
      action.__raw = "function() vim.lsp.buf.signature_help() end";
      options = {
        desc = "Signature help";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ca";
      action.__raw = "function() vim.lsp.buf.code_action() end";
      options = {
        desc = "Code action";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>cr";
      action.__raw = "function() vim.lsp.buf.rename() end";
      options = {
        desc = "Rename";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>cl";
      action = "<cmd>LspInfo<CR>";
      options = {
        desc = "LSP info";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>cd";
      action.__raw = "function() vim.diagnostic.open_float() end";
      options = {
        desc = "Line diagnostics";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>cD";
      action.__raw = "function() vim.diagnostic.setloclist() end";
      options = {
        desc = "Document diagnostics";
        silent = true;
      };
    }
    # Formatting from nvf
    {
      mode = "n";
      key = "<leader>cf";
      action.__raw = "function() require('conform').format({ timeout_ms = 500, lsp_fallback = true }) end";
      options = {
        desc = "Format";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<leader>cf";
      action.__raw = "function() require('conform').format({ async = true, lsp_fallback = true }) end";
      options = {
        desc = "Format range";
        silent = true;
      };
    }
    # Flash keybindings from nvf
    {
      mode = "n";
      key = "s";
      action.__raw = "function() require('flash').jump() end";
      options = {
        desc = "Flash jump";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "S";
      action.__raw = "function() require('flash').treesitter() end";
      options = {
        desc = "Flash treesitter";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "s";
      action.__raw = "function() require('flash').jump() end";
      options = {
        desc = "Flash jump";
        silent = true;
      };
    }
    # Trouble keybindings from nvf
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      options = {
        desc = "Diagnostics";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xX";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
      options = {
        desc = "Buffer diagnostics";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xs";
      action = "<cmd>Trouble symbols toggle focus=false<CR>";
      options = {
        desc = "Symbols";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xl";
      action = "<cmd>Trouble lsp toggle focus=false win.position=right<CR>";
      options = {
        desc = "LSP";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xt";
      action = "<cmd>TodoTrouble<CR>";
      options = {
        desc = "Todo Trouble";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>xT";
      action = "<cmd>TodoTelescope<CR>";
      options = {
        desc = "Todo Telescope";
        silent = true;
      };
    }
    # Clear search highlight
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<CR>";
      options = {
        desc = "Clear highlight";
        silent = true;
      };
    }
    # Terminal mode mappings from nvf
    {
      mode = "t";
      key = "<C-h>";
      action = "<C-\\><C-n><C-w>h";
      options = {
        desc = "Navigate left from terminal";
        silent = true;
      };
    }
    {
      mode = "t";
      key = "<C-j>";
      action = "<C-\\><C-n><C-w>j";
      options = {
        desc = "Navigate down from terminal";
        silent = true;
      };
    }
    {
      mode = "t";
      key = "<C-k>";
      action = "<C-\\><C-n><C-w>k";
      options = {
        desc = "Navigate up from terminal";
        silent = true;
      };
    }
    {
      mode = "t";
      key = "<C-l>";
      action = "<C-\\><C-n><C-w>l";
      options = {
        desc = "Navigate right from terminal";
        silent = true;
      };
    }
    {
      mode = "t";
      key = "<Esc><Esc>";
      action = "<C-\\><C-n>";
      options = {
        desc = "Exit terminal mode";
        silent = true;
      };
    }
    # Flutter widget refactoring keybindings from nvf
    {
      mode = "n";
      key = "<leader>Fww";
      action.__raw = "function() vim.lsp.buf.code_action({ filter = function(a) return a.title:match('Wrap with') end, apply = true }) end";
      options = {
        desc = "Flutter: Wrap with widget";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fwc";
      action.__raw = "function() vim.lsp.buf.code_action({ filter = function(a) return a.title == 'Wrap with Column' end, apply = true }) end";
      options = {
        desc = "Flutter: Wrap with Column";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fwr";
      action.__raw = "function() vim.lsp.buf.code_action({ filter = function(a) return a.title == 'Wrap with Row' end, apply = true }) end";
      options = {
        desc = "Flutter: Wrap with Row";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fwe";
      action.__raw = "function() vim.lsp.buf.code_action({ filter = function(a) return a.title == 'Wrap with Center' end, apply = true }) end";
      options = {
        desc = "Flutter: Wrap with Center";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Fwx";
      action.__raw = "function() vim.lsp.buf.code_action({ filter = function(a) return a.title:match('Remove') end, apply = true }) end";
      options = {
        desc = "Flutter: Remove widget";
        silent = true;
      };
    }
    # LazyVim-style diagnostic navigation
    {
      mode = "n";
      key = "]d";
      action.__raw = "function() vim.diagnostic.goto_next() end";
      options = {
        desc = "Next diagnostic";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "[d";
      action.__raw = "function() vim.diagnostic.goto_prev() end";
      options = {
        desc = "Previous diagnostic";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "]e";
      action.__raw = "function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end";
      options = {
        desc = "Next error";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "[e";
      action.__raw = "function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end";
      options = {
        desc = "Previous error";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "]w";
      action.__raw = "function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN }) end";
      options = {
        desc = "Next warning";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "[w";
      action.__raw = "function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN }) end";
      options = {
        desc = "Previous warning";
        silent = true;
      };
    }
    # Additional LSP keybindings
    {
      mode = "i";
      key = "<C-k>";
      action.__raw = "function() vim.lsp.buf.signature_help() end";
      options = {
        desc = "Signature help";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<leader>ca";
      action.__raw = "function() vim.lsp.buf.code_action() end";
      options = {
        desc = "Code action";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>cR";
      action.__raw = "function() vim.lsp.buf.rename() end";
      options = {
        desc = "Rename file";
        silent = true;
      };
    }
    # Yanky keymaps
    {
      mode = "n";
      key = "p";
      action = "<Plug>(YankyPutAfter)";
      options = {
        desc = "Put after";
      };
    }
    {
      mode = "n";
      key = "P";
      action = "<Plug>(YankyPutBefore)";
      options = {
        desc = "Put before";
      };
    }
    {
      mode = "n";
      key = "[y";
      action = "<Plug>(YankyCycleForward)";
      options = {
        desc = "Cycle yank forward";
      };
    }
    {
      mode = "n";
      key = "]y";
      action = "<Plug>(YankyCycleBackward)";
      options = {
        desc = "Cycle yank backward";
      };
    }
    {
      mode = "n";
      key = ">p";
      action = "<Plug>(YankyPutIndentAfterLinewise)";
      options = {
        desc = "Put indent after linewise";
      };
    }
    {
      mode = "n";
      key = "<p";
      action = "<Plug>(YankyPutIndentBeforeLinewise)";
      options = {
        desc = "Put indent before linewise";
      };
    }
    {
      mode = "n";
      key = "=p";
      action = "<Plug>(YankyPutAfterFilter)";
      options = {
        desc = "Put after filter";
      };
    }
    {
      mode = "n";
      key = "]p";
      action = "<Plug>(YankyPutIndentAfterLinewise)";
      options = {
        desc = "Put indent after";
      };
    }
    {
      mode = "n";
      key = "[p";
      action = "<Plug>(YankyPutIndentBeforeLinewise)";
      options = {
        desc = "Put indent before";
      };
    }
    {
      mode = "n";
      key = "<leader>p";
      action = "<cmd>Telescope yank_history<CR>";
      options = {
        desc = "Yank history";
        silent = true;
      };
    }
    # Yanky visual mode keymaps
    {
      mode = "v";
      key = "p";
      action = "<Plug>(YankyPutAfter)";
      options = {
        desc = "Paste (yanky)";
      };
    }
    {
      mode = "v";
      key = "P";
      action = "<Plug>(YankyPutBefore)";
      options = {
        desc = "Paste before (yanky)";
      };
    }
    # Session Management (Persistence)
    {
      mode = "n";
      key = "<leader>qs";
      action.__raw = "function() require('persistence').load() end";
      options = {
        desc = "Restore session";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ql";
      action.__raw = "function() require('persistence').load({ last = true }) end";
      options = {
        desc = "Restore last session";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>qd";
      action.__raw = "function() require('persistence').stop() end";
      options = {
        desc = "Don't save current session";
        silent = true;
      };
    }
    # Zen Mode / Twilight
    {
      mode = "n";
      key = "<leader>z";
      action = "<cmd>ZenMode<CR>";
      options = {
        desc = "Zen mode";
        silent = true;
      };
    }
    # Yazi File Manager
    {
      mode = "n";
      key = "<leader>y";
      action = "<cmd>Yazi<CR>";
      options = {
        desc = "Yazi file manager";
        silent = true;
      };
    }
    # Missing gd keymap (go to definition)
    {
      mode = "n";
      key = "gd";
      action.__raw = "function() vim.lsp.buf.definition() end";
      options = {
        desc = "Goto definition";
        silent = true;
      };
    }
    # Missing K keymap (hover)
    {
      mode = "n";
      key = "K";
      action.__raw = "function() vim.lsp.buf.hover() end";
      options = {
        desc = "Hover";
        silent = true;
      };
    }
  ];
}
