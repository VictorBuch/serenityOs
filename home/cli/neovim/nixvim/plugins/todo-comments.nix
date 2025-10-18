{
  programs.nixvim = {
    plugins.todo-comments = {
      enable = true;
      settings = {
        signs = true;
        sign_priority = 8;
        keywords = {
          FIX = {
            icon = " ";
            color = "error";
            alt = [
              "FIXME"
              "BUG"
              "FIXIT"
              "ISSUE"
            ];
          };
          TODO = {
            icon = " ";
            color = "info";
          };
          HACK = {
            icon = " ";
            color = "warning";
          };
          WARN = {
            icon = " ";
            color = "warning";
            alt = [
              "WARNING"
              "XXX"
            ];
          };
          PERF = {
            icon = " ";
            alt = [
              "OPTIM"
              "PERFORMANCE"
              "OPTIMIZE"
            ];
          };
          NOTE = {
            icon = " ";
            color = "hint";
            alt = [ "INFO" ];
          };
          TEST = {
            icon = "⏲ ";
            color = "test";
            alt = [
              "TESTING"
              "PASSED"
              "FAILED"
            ];
          };
        };
        gui_style = {
          fg = "NONE";
          bg = "BOLD";
        };
        merge_keywords = true;
        highlight = {
          multiline = true;
          multiline_pattern = "^.";
          multiline_context = 10;
          before = "";
          keyword = "wide";
          after = "fg";
          pattern = ''.*<(KEYWORDS)\s*:'';
          comments_only = true;
          max_line_len = 400;
          exclude = [ ];
        };
        colors = {
          error = [
            "DiagnosticError"
            "ErrorMsg"
            "#DC2626"
          ];
          warning = [
            "DiagnosticWarn"
            "WarningMsg"
            "#FBBF24"
          ];
          info = [
            "DiagnosticInfo"
            "#2563EB"
          ];
          hint = [
            "DiagnosticHint"
            "#10B981"
          ];
          default = [
            "Identifier"
            "#7C3AED"
          ];
          test = [
            "Identifier"
            "#FF00FF"
          ];
        };
        search = {
          command = "rg";
          args = [
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
          ];
          pattern = ''\b(KEYWORDS):'';
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "]t";
        action = ''
          function()
            require("todo-comments").jump_next()
          end
        '';
        lua = true;
        options = {
          desc = "Next todo comment";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "[t";
        action = ''
          function()
            require("todo-comments").jump_prev()
          end
        '';
        lua = true;
        options = {
          desc = "Previous todo comment";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>xt";
        action = "<cmd>Trouble todo toggle<cr>";
        options = {
          desc = "Todo (Trouble)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>xT";
        action = "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>";
        options = {
          desc = "Todo/Fix/Fixme (Trouble)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>st";
        action = "<cmd>TodoTelescope<cr>";
        options = {
          desc = "Todo";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>sT";
        action = "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>";
        options = {
          desc = "Todo/Fix/Fixme";
          silent = true;
        };
      }
    ];
  };
}
