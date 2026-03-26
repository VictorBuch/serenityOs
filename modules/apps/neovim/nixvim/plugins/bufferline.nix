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
        close_command.__raw = "function(n) require('mini.bufremove').delete(n, false) end";
        right_mouse_command.__raw = "function(n) require('mini.bufremove').delete(n, false) end";
      };
    };
  };
}
