{
  programs.nixvim.plugins.snacks = {
    enable = true;
    settings = {
      bigfile = {
        enabled = true;
      };
      input = {
        enabled = true;
      };
      notifier = {
        enabled = true;
        timeout = 3000;
      };
      # Picker module - replaces vim.ui.select with a nice fuzzy finder
      # This fixes visual bugs in code actions menu (<leader>ca)
      picker = {
        enabled = true;
        ui_select = true;  # Replace vim.ui.select with snacks picker
      };
      quickfile = {
        enabled = true;
      };
      scroll = {
        enabled = false;
      };
      statuscolumn = {
        enabled = false;
      };
      words = {
        enabled = true;
      };
    };
  };
}
