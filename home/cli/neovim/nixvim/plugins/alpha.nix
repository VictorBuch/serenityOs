{
  programs.nixvim.plugins.alpha = {
    enable = true;
    settings.layout = [
      {
        type = "padding";
        val = 4;
      }
      {
        type = "text";
        val = [
          "                                                                      "
          " ███████╗███████╗██████╗ ███████╗███╗   ██╗██╗████████╗██╗   ██╗██╗███╗   ███╗"
          " ██╔════╝██╔════╝██╔══██╗██╔════╝████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝██║████╗ ████║"
          " ███████╗█████╗  ██████╔╝█████╗  ██╔██╗ ██║██║   ██║    ╚████╔╝ ██║██╔████╔██║"
          " ╚════██║██╔══╝  ██╔══██╗██╔══╝  ██║╚██╗██║██║   ██║     ╚██╔╝  ██║██║╚██╔╝██║"
          " ███████║███████╗██║  ██║███████╗██║ ╚████║██║   ██║      ██║   ██║██║ ╚═╝ ██║"
          " ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝   ╚═╝╚═╝     ╚═╝"
          "                                                                      "
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
            on_press.__raw = "function() vim.cmd('Telescope find_files') end";
            opts = {
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
            on_press.__raw = "function() vim.cmd('Telescope oldfiles') end";
            opts = {
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
            on_press.__raw = "function() vim.cmd('Telescope live_grep') end";
            opts = {
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
            on_press.__raw = "function() vim.cmd('Neotree toggle') end";
            opts = {
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
            on_press.__raw = "function() vim.cmd('qa') end";
            opts = {
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
}
