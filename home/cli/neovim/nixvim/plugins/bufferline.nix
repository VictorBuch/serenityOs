{
  programs.nixvim.plugins.bufferline = {
    enable = true;
    settings = {
      options = {
        numbers = "none";
        style_preset = "minimal";
        separator_style = "thin";
        show_buffer_close_icons = false;
        diagnostics = false;
      };
    };
  };
}
