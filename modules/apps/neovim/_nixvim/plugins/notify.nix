{
  programs.nixvim.plugins.notify = {
    enable = true;
    settings = {
      background_colour = "#000000";
      fps = 60;
      level = 2;
      minimum_width = 50;
      render = "default";
      stages = "fade_in_slide_out";
      timeout = 3000;
      top_down = true;
    };
  };
}
