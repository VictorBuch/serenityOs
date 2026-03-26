{
  programs.nixvim.plugins.yazi = {
    enable = true;
    settings = {
      open_for_directories = false;
      floating_window_scaling_factor = 0.9;
      yazi_floating_window_border = "rounded";
    };
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>y";
      action = "<cmd>Yazi<CR>";
      options = {
        desc = "Open Yazi file manager";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>Y";
      action = "<cmd>Yazi cwd<CR>";
      options = {
        desc = "Open Yazi in cwd";
        silent = true;
      };
    }
  ];
}
