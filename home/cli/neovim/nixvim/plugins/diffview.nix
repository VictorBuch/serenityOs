{
  programs.nixvim = {
    plugins.diffview = {
      enable = true;
      settings.enhanced_diff_hl = true;
    };
    
    keymaps = [
      {
        mode = "n";
        key = "<leader>gv";
        action = "<cmd>DiffviewOpen<CR>";
        options = {
          desc = "Open diffview";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory %<CR>";
        options = {
          desc = "File history";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gH";
        action = "<cmd>DiffviewFileHistory<CR>";
        options = {
          desc = "Branch history";
          silent = true;
        };
      }
    ];
  };
}