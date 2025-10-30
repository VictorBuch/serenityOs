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
