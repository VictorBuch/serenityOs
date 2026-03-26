{
  programs.nixvim.plugins.mini = {
    enable = true;

    modules = {
      # Better Around/Inside textobjects
      #
      # Examples:
      #  - va)  - [V]isually select [A]round [)]paren
      #  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      #  - ci'  - [C]hange [I]nside [']quote
      ai = {
        n_lines = 500;
      };

      # Add/delete/replace surroundings (brackets, quotes, etc.)
      #
      # LazyVim-style keybindings with gs prefix:
      #  - gsaiw) - [G]o [S]urround [A]dd [I]nner [W]ord [)]Paren
      #  - gsd'   - [G]o [S]urround [D]elete [']quotes
      #  - gsr)'  - [G]o [S]urround [R]eplace [)] [']
      surround = {
        mappings = {
          add = "gsa";            # Add surrounding in Normal and Visual modes
          delete = "gsd";         # Delete surrounding
          find = "gsf";           # Find surrounding (to the right)
          find_left = "gsF";      # Find surrounding (to the left)
          highlight = "gsh";      # Highlight surrounding
          replace = "gsr";        # Replace surrounding
          update_n_lines = "gsn"; # Update `n_lines`
        };
      };
      pairs = {

      };
      comment = {
        mappings = {
          comment = "<leader>gc";
          comment_line = "<leader>gc";
          comment_visual = "<leader>gc";
          textobject = "<leader>gc";
        };
      };
    };
  };
}
