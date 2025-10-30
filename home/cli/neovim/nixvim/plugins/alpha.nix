{
  programs.nixvim.plugins.alpha = {
    enable = true;
    layout = [
      {
        type = "padding";
        val = 8;
      }
      {
        opts = {
          hl = "Type";
          position = "center";
        };
        type = "text";
        val = [
          "                                                     "
          " ███████╗███████╗██████╗ ███████╗███╗   ██╗██╗████████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗"
          " ██╔════╝██╔════╝██╔══██╗██╔════╝████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝██║   ██║██║████╗ ████║"
          " ███████╗█████╗  ██████╔╝█████╗  ██╔██╗ ██║██║   ██║    ╚████╔╝ ██║   ██║██║██╔████╔██║"
          " ╚════██║██╔══╝  ██╔══██╗██╔══╝  ██║╚██╗██║██║   ██║     ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║"
          " ███████║███████╗██║  ██║███████╗██║ ╚████║██║   ██║      ██║    ╚████╔╝ ██║██║ ╚═╝ ██║"
          " ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝"
          "                                                     "
        ];
      }
      {
        type = "padding";
        val = 2;
      }
      {
        type = "group";
        val = [
          {
            on_press.__raw = "function() require('telescope.builtin').find_files() end";
            opts = {
              shortcut = "f";
              position = "center";
              cursor = 3;
              width = 50;
              align_shortcut = "right";
              hl_shortcut = "Keyword";
            };
            type = "button";
            val = "  Find File";
          }
          {
            on_press.__raw = "function() require('telescope.builtin').oldfiles() end";
            opts = {
              shortcut = "r";
              position = "center";
              cursor = 3;
              width = 50;
              align_shortcut = "right";
              hl_shortcut = "Keyword";
            };
            type = "button";
            val = "  Recent Files";
          }
          {
            on_press.__raw = "function() require('telescope.builtin').live_grep() end";
            opts = {
              shortcut = "g";
              position = "center";
              cursor = 3;
              width = 50;
              align_shortcut = "right";
              hl_shortcut = "Keyword";
            };
            type = "button";
            val = "  Find Text";
          }
          {
            on_press.__raw = "function() vim.cmd('Neotree toggle') end";
            opts = {
              shortcut = "e";
              position = "center";
              cursor = 3;
              width = 50;
              align_shortcut = "right";
              hl_shortcut = "Keyword";
            };
            type = "button";
            val = "  File Browser";
          }
          {
            on_press.__raw = "function() vim.cmd('qa') end";
            opts = {
              shortcut = "q";
              position = "center";
              cursor = 3;
              width = 50;
              align_shortcut = "right";
              hl_shortcut = "Keyword";
            };
            type = "button";
            val = "  Quit Neovim";
          }
        ];
      }
      {
        type = "padding";
        val = 2;
      }
    ];
  };
}
