{
  programs.nixvim = {
    plugins.flash = {
      enable = true;
      settings = {
        labels = "asdfghjklqwertyuiopzxcvbnm";
        search = {
          multi_window = true;
          forward = true;
          wrap = true;
          mode = "exact";
          incremental = false;
        };
        jump = {
          jumplist = true;
          pos = "start";
          history = false;
          register = false;
          nohlsearch = false;
          autojump = false;
        };
        label = {
          uppercase = true;
          rainbow = {
            enabled = false;
            shade = 5;
          };
        };
        modes = {
          search = {
            enabled = true;
          };
          char = {
            enabled = true;
            jump_labels = false;
            multi_line = true;
            label = {
              exclude = "hjkliardc";
            };
            keys = {
              __raw = ''{ "f", "F", "t", "T", ";", "," }'';
            };
            char_actions.__raw = ''
              function(motion)
                return {
                  [";"] = "next",
                  [","] = "prev",
                  [motion:lower()] = "next",
                  [motion:upper()] = "prev",
                }
              end
            '';
            search = {
              wrap = false;
            };
            highlight = {
              backdrop = true;
            };
          };
          treesitter = {
            labels = "abcdefghijklmnopqrstuvwxyz";
            jump = {
              pos = "range";
            };
            search = {
              incremental = false;
            };
            label = {
              before = true;
              after = true;
              style = "inline";
            };
            highlight = {
              backdrop = false;
              matches = false;
            };
          };
        };
        prompt = {
          enabled = true;
          prefix = [
            [
              ""
              "FlashPromptIcon"
            ]
          ];
          win_config = {
            relative = "editor";
            width = 1;
            height = 1;
            row = -1;
            col = 0;
            zindex = 1000;
          };
        };
      };
    };

    keymaps = [
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = "function() require('flash').jump() end";
        options = {
          desc = "Flash";
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "S";
        action.__raw = "function() require('flash').treesitter() end";
        options = {
          desc = "Flash Treesitter";
          silent = true;
        };
      }
      {
        mode = "o";
        key = "r";
        action.__raw = "function() require('flash').remote() end";
        options = {
          desc = "Remote Flash";
          silent = true;
        };
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "R";
        action.__raw = "function() require('flash').treesitter_search() end";
        options = {
          desc = "Treesitter Search";
          silent = true;
        };
      }
      {
        mode = [ "c" ];
        key = "<c-s>";
        action.__raw = "function() require('flash').toggle() end";
        options = {
          desc = "Toggle Flash Search";
          silent = true;
        };
      }
    ];
  };
}
