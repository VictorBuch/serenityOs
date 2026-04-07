{
  programs.nixvim.plugins.which-key = {
    enable = true;

    settings = {
      # LazyVim-style configuration
      icons = {
        breadcrumb = "»";
        separator = "➜";
        group = "+";
      };

      # Show which-key popup faster
      delay = 300;

      # Register key groups with descriptive names
      spec = [
        {
          __unkeyed-1 = "<leader>f";
          group = "Find";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
        }
        {
          __unkeyed-1 = "<leader>F";
          group = "Flutter";
        }
        {
          __unkeyed-1 = "<leader>b";
          group = "Buffer";
        }
      ];
    };
  };
}
