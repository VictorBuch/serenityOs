# LazyVim-style blink-cmp configuration
# Replaces nvim-cmp with faster, better defaults
{
  programs.nixvim.plugins = {
    # Keep luasnip for snippets - blink-cmp will use it
    luasnip.enable = true;

    blink-cmp = {
      enable = true;

      settings = {
        # Keymap preset - "enter" matches LazyVim with custom navigation
        # <C-j>/<C-k> = navigate down/up (custom)
        # <CR> = select and accept
        # <C-Space> = show completion menu
        keymap = {
          preset = "enter";
          # Custom keymaps - merged with preset, overwrites conflicts
          "<C-j>" = [ "select_next" "fallback" ];
          "<C-k>" = [ "select_prev" "fallback" ];
        };

        appearance = {
          # Use mono nerd font variant for icons
          nerd_font_variant = "mono";
          # Use nvim-cmp style highlight groups for compatibility
          use_nvim_cmp_as_default = true;
        };

        completion = {
          accept = {
            # Automatically add brackets after functions/methods
            auto_brackets = {
              enabled = true;
            };
          };

          # Show ghost text for first completion item
          ghost_text = {
            enabled = true;
          };

          menu = {
            # Enable treesitter for better highlighting
            draw = {
              treesitter = [ "lsp" ];
            };
          };

          documentation = {
            auto_show = true;
            auto_show_delay_ms = 500;
          };
        };

        # Deprioritize emmet_ls so ts_ls completions appear first in TSX
        fuzzy = {
          sorts = [
            {
              __raw = ''
                function(a, b)
                  if (a.client_name == nil or b.client_name == nil) or (a.client_name == b.client_name) then
                    return
                  end
                  return b.client_name == "emmet_ls"
                end
              '';
            }
            "score"
            "sort_text"
          ];
        };

        # Sources in priority order: LSP → snippets → buffer → path
        sources = {
          default = [ "lsp" "path" "snippets" "buffer" ];
        };
      };
    };
  };
}
