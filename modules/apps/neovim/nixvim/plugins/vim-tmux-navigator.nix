{
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;
    settings = {
      disable_when_zoomed = 1;
      no_mappings = 0;
    };
  };
}
