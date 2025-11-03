{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim.maps = {
      # ========================================
      # NORMAL MODE KEYMAPS
      # ========================================
      normal = {
        # -------------------- Fuzzy Finding --------------------
        "<leader><leader>" = {
          action = ":Telescope find_files<CR>";
          desc = "Find files";
          silent = true;
        };
        "<leader>/" = {
          action = ":Telescope live_grep<CR>";
          desc = "Live grep";
          silent = true;
        };
        "<leader>fr" = {
          action = ":Telescope oldfiles<CR>";
          desc = "Recent files";
          silent = true;
        };
        "<leader>fb" = {
          action = ":Telescope buffers<CR>";
          desc = "Buffers";
          silent = true;
        };

        # -------------------- Window Navigation --------------------
        # Note: <C-h/j/k/l> are handled by vim-tmux-navigator plugin
        "<C-h>" = {
          action = "<C-w>h";
          desc = "Move left";
          silent = true;
        };
        "<C-j>" = {
          action = "<C-w>j";
          desc = "Move down";
          silent = true;
        };
        "<C-k>" = {
          action = "<C-w>k";
          desc = "Move up";
          silent = true;
        };
        "<C-l>" = {
          action = "<C-w>l";
          desc = "Move right";
          silent = true;
        };

        # -------------------- File Explorer --------------------
        "<leader>e" = {
          action = ":Neotree action=focus reveal toggle<CR>";
          desc = "Toggle file explorer";
          silent = true;
        };

        # -------------------- Buffer Navigation --------------------
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
        "[b" = {
          action = ":BufferLineCyclePrev<CR>";
          desc = "Previous buffer";
          silent = true;
        };
        "]b" = {
          action = ":BufferLineCycleNext<CR>";
          desc = "Next buffer";
          silent = true;
        };

        # -------------------- Buffer Management --------------------
        "<leader>bb" = {
          action = ":Telescope buffers<CR>";
          desc = "Switch buffer";
          silent = true;
        };
        "<leader>bd" = {
          action = ":lua require('mini.bufremove').delete(0, false)<CR>";
          desc = "Delete buffer";
          silent = true;
        };
        "<leader>bo" = {
          action = ":BufferLineCloseOthers<CR>";
          desc = "Delete other buffers";
          silent = true;
        };
        "<leader>bD" = {
          action = ":bdelete | close<CR>";
          desc = "Delete buffer and window";
          silent = true;
        };
        "<leader>bl" = {
          action = ":BufferLineCloseLeft<CR>";
          desc = "Delete buffers to the left";
          silent = true;
        };
        "<leader>br" = {
          action = ":BufferLineCloseRight<CR>";
          desc = "Delete buffers to the right";
          silent = true;
        };
        "<leader>bp" = lib.mkForce {
          action = ":BufferLineTogglePin<CR>";
          desc = "Toggle pin";
          silent = true;
        };
        "<leader>bP" = {
          action = ":BufferLineGroupClose ungrouped<CR>";
          desc = "Delete non-pinned buffers";
          silent = true;
        };

        # -------------------- LSP --------------------
        "gd" = {
          action = ":lua vim.lsp.buf.definition()<CR>";
          desc = "Goto definition";
          silent = true;
        };
        "gr" = {
          action = ":lua vim.lsp.buf.references()<CR>";
          desc = "Goto references";
          silent = true;
        };
        "gI" = {
          action = ":lua vim.lsp.buf.implementation()<CR>";
          desc = "Goto implementation";
          silent = true;
        };
        "gy" = {
          action = ":lua vim.lsp.buf.type_definition()<CR>";
          desc = "Goto type definition";
          silent = true;
        };
        "gD" = {
          action = ":lua vim.lsp.buf.declaration()<CR>";
          desc = "Goto declaration";
          silent = true;
        };
        "K" = {
          action = ":lua vim.lsp.buf.hover()<CR>";
          desc = "Hover";
          silent = true;
        };
        "gK" = {
          action = ":lua vim.lsp.buf.signature_help()<CR>";
          desc = "Signature help";
          silent = true;
        };
        "<leader>ca" = {
          action = ":lua vim.lsp.buf.code_action()<CR>";
          desc = "Code action";
          silent = true;
        };
        "<leader>cr" = {
          action = ":lua vim.lsp.buf.rename()<CR>";
          desc = "Rename";
          silent = true;
        };
        "<leader>cR" = {
          action = ":lua vim.lsp.buf.rename()<CR>";
          desc = "Rename file";
          silent = true;
        };
        "<leader>cl" = {
          action = ":LspInfo<CR>";
          desc = "LSP info";
          silent = true;
        };
        "<leader>cd" = {
          action = ":lua vim.diagnostic.open_float()<CR>";
          desc = "Line diagnostics";
          silent = true;
        };
        "<leader>cD" = {
          action = ":lua vim.diagnostic.setloclist()<CR>";
          desc = "Document diagnostics";
          silent = true;
        };

        # -------------------- Formatting --------------------
        "<leader>cf" = {
          action = ":lua vim.lsp.buf.format({ timeout_ms = 500 })<CR>";
          desc = "Format";
          silent = true;
        };

        # -------------------- Diagnostics Navigation --------------------
        "]d" = {
          action = ":lua vim.diagnostic.goto_next()<CR>";
          desc = "Next diagnostic";
          silent = true;
        };
        "[d" = {
          action = ":lua vim.diagnostic.goto_prev()<CR>";
          desc = "Previous diagnostic";
          silent = true;
        };
        "]e" = {
          action = ":lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<CR>";
          desc = "Next error";
          silent = true;
        };
        "[e" = {
          action = ":lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<CR>";
          desc = "Previous error";
          silent = true;
        };
        "]w" = {
          action = ":lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })<CR>";
          desc = "Next warning";
          silent = true;
        };
        "[w" = {
          action = ":lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })<CR>";
          desc = "Previous warning";
          silent = true;
        };

        # -------------------- Flash Navigation --------------------
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

        # -------------------- Git --------------------
        "<leader>gg" = {
          action = ":LazyGit<CR>";
          desc = "LazyGit (Root Dir)";
          silent = true;
        };
        "<leader>gb" = {
          action = ":Gitsigns blame_line<CR>";
          desc = "Git Blame Line";
          silent = true;
        };
        "<leader>gd" = {
          action = ":Gitsigns diffthis<CR>";
          desc = "Git Diff";
          silent = true;
        };

        # -------------------- Trouble Diagnostics --------------------
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

        # -------------------- Terminal --------------------
        "<leader>ft" = {
          action = ":ToggleTerm<CR>";
          desc = "Terminal (Root Dir)";
          silent = true;
        };
        "<leader>fT" = {
          action = ":ToggleTerm dir=%:p:h<CR>";
          desc = "Terminal (cwd)";
          silent = true;
        };

        # -------------------- Flutter --------------------
        "<leader>Fc" = {
          action = ":Telescope flutter commands<CR>";
          desc = "Flutter Commands";
          silent = true;
        };
        "<leader>Fr" = {
          action = ":FlutterRun<CR>";
          desc = "Flutter Run";
          silent = true;
        };
        "<leader>Fd" = {
          action = ":FlutterDevices<CR>";
          desc = "Flutter Devices";
          silent = true;
        };
        "<leader>Fe" = {
          action = ":FlutterEmulators<CR>";
          desc = "Flutter Emulators";
          silent = true;
        };
        "<leader>FR" = {
          action = ":FlutterReload<CR>";
          desc = "Flutter Hot Reload";
          silent = true;
        };
        "<leader>Fs" = {
          action = ":FlutterRestart<CR>";
          desc = "Flutter Restart";
          silent = true;
        };
        "<leader>Fq" = {
          action = ":FlutterQuit<CR>";
          desc = "Flutter Quit";
          silent = true;
        };
        "<leader>Ft" = {
          action = ":FlutterDevTools<CR>";
          desc = "Flutter DevTools";
          silent = true;
        };
        "<leader>Fo" = {
          action = ":FlutterOutlineToggle<CR>";
          desc = "Flutter Outline";
          silent = true;
        };
        "<leader>Fl" = {
          action = ":FlutterLogToggle<CR>";
          desc = "Flutter Logs";
          silent = true;
        };

        # Flutter widget refactoring
        "<leader>Fww" = {
          action = ":lua vim.lsp.buf.code_action({ filter = function(a) return a.title:match('Wrap with') end, apply = true })<CR>";
          desc = "Flutter: Wrap with widget";
          silent = true;
        };
        "<leader>Fwc" = {
          action = ":lua vim.lsp.buf.code_action({ filter = function(a) return a.title == 'Wrap with Column' end, apply = true })<CR>";
          desc = "Flutter: Wrap with Column";
          silent = true;
        };
        "<leader>Fwr" = {
          action = ":lua vim.lsp.buf.code_action({ filter = function(a) return a.title == 'Wrap with Row' end, apply = true })<CR>";
          desc = "Flutter: Wrap with Row";
          silent = true;
        };
        "<leader>Fwe" = {
          action = ":lua vim.lsp.buf.code_action({ filter = function(a) return a.title == 'Wrap with Center' end, apply = true })<CR>";
          desc = "Flutter: Wrap with Center";
          silent = true;
        };
        "<leader>Fwx" = {
          action = ":lua vim.lsp.buf.code_action({ filter = function(a) return a.title:match('Remove') end, apply = true })<CR>";
          desc = "Flutter: Remove widget";
          silent = true;
        };

        # -------------------- Utilities --------------------
        "<Esc>" = {
          action = ":nohlsearch<CR>";
          desc = "Clear highlight";
          silent = true;
        };

        # -------------------- Yanky --------------------
        "p" = {
          action = "<Plug>(YankyPutAfter)";
          desc = "Put after";
        };
        "P" = {
          action = "<Plug>(YankyPutBefore)";
          desc = "Put before";
        };
        "[y" = {
          action = "<Plug>(YankyCycleForward)";
          desc = "Cycle yank forward";
        };
        "]y" = {
          action = "<Plug>(YankyCycleBackward)";
          desc = "Cycle yank backward";
        };
        ">p" = {
          action = "<Plug>(YankyPutIndentAfterLinewise)";
          desc = "Put indent after linewise";
        };
        "<p" = {
          action = "<Plug>(YankyPutIndentBeforeLinewise)";
          desc = "Put indent before linewise";
        };
        "=p" = {
          action = "<Plug>(YankyPutAfterFilter)";
          desc = "Put after filter";
        };
        "]p" = {
          action = "<Plug>(YankyPutIndentAfterLinewise)";
          desc = "Put indent after";
        };
        "[p" = lib.mkForce {
          action = "<Plug>(YankyPutIndentBeforeLinewise)";
          desc = "Put indent before";
        };
        "<leader>p" = {
          action = ":Telescope yank_history<CR>";
          desc = "Yank history";
          silent = true;
        };

        # -------------------- Session Management --------------------
        "<leader>qs" = {
          action = ":lua require('persistence').load()<CR>";
          desc = "Restore session";
          silent = true;
        };
        "<leader>ql" = {
          action = ":lua require('persistence').load({ last = true })<CR>";
          desc = "Restore last session";
          silent = true;
        };
        "<leader>qd" = {
          action = ":lua require('persistence').stop()<CR>";
          desc = "Don't save current session";
          silent = true;
        };

        # -------------------- Zen Mode / Twilight --------------------
        "<leader>z" = {
          action = ":ZenMode<CR>";
          desc = "Zen mode";
          silent = true;
        };

        # -------------------- Yazi File Manager --------------------
        "<leader>y" = {
          action = ":Yazi<CR>";
          desc = "Yazi file manager";
          silent = true;
        };
      };

      # ========================================
      # VISUAL MODE KEYMAPS
      # ========================================
      visual = {
        # -------------------- Indenting --------------------
        "<" = {
          action = "<gv";
          desc = "Indent left (stay in visual mode)";
          silent = true;
        };
        ">" = {
          action = ">gv";
          desc = "Indent right (stay in visual mode)";
          silent = true;
        };

        # -------------------- Yanky Paste --------------------
        "p" = {
          action = "<Plug>(YankyPutAfter)";
          desc = "Paste (yanky)";
        };
        "P" = {
          action = "<Plug>(YankyPutBefore)";
          desc = "Paste before (yanky)";
        };

        # -------------------- Flash --------------------
        "s" = {
          action = ":lua require('flash').jump()<CR>";
          desc = "Flash jump";
          silent = true;
        };

        # -------------------- LSP --------------------
        "<leader>ca" = {
          action = ":lua vim.lsp.buf.code_action()<CR>";
          desc = "Code action";
          silent = true;
        };
        "<leader>cf" = {
          action = ":lua vim.lsp.buf.format({ timeout_ms = 500 })<CR>";
          desc = "Format range";
          silent = true;
        };
      };

      # ========================================
      # INSERT MODE KEYMAPS
      # ========================================
      insert = {
        # -------------------- LSP Signature Help --------------------
        "<C-k>" = {
          action = ":lua vim.lsp.buf.signature_help()<CR>";
          desc = "Signature help";
          silent = true;
        };
      };

      # ========================================
      # TERMINAL MODE KEYMAPS
      # ========================================
      terminal = {
        # -------------------- Terminal Navigation --------------------
        "<C-h>" = {
          action = "<C-\\><C-n><C-w>h";
          desc = "Navigate left from terminal";
          silent = true;
        };
        "<C-j>" = {
          action = "<C-\\><C-n><C-w>j";
          desc = "Navigate down from terminal";
          silent = true;
        };
        "<C-k>" = {
          action = "<C-\\><C-n><C-w>k";
          desc = "Navigate up from terminal";
          silent = true;
        };
        "<C-l>" = {
          action = "<C-\\><C-n><C-w>l";
          desc = "Navigate right from terminal";
          silent = true;
        };

        # -------------------- Quick Escape --------------------
        "<Esc><Esc>" = {
          action = "<C-\\><C-n>";
          desc = "Exit terminal mode";
          silent = true;
        };
      };
    };
  };
}
