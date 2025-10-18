{
  programs.nixvim.plugins.neo-tree = {
    enable = true;
    settings = {
      close_if_last_window = true;
      enable_refresh_on_write = true;
    };
  };
}
