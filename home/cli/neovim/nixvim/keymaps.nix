{
  programs.nixvim.keymaps = [
    {
      mode = "v";
      key = "p";
      action = "_dP";
      options = {
        desc = "Better paste";
        silent = true;
      };
    }
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
      action = "<cmd>bdelete<CR>";
      options = {
        desc = "Delete Buffer";
        silent = true;
      };
    }
  ];
}
