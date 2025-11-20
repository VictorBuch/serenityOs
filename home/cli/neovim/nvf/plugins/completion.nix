{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim = {
      # Enable blink-cmp for faster completion (using nvf's built-in support)
      autocomplete.blink-cmp = {
        enable = true;
        setupOpts = {
          # Custom keymaps
          # <C-j>/<C-k> = navigate down/up through completions
          # <Enter> = accept completion (from enter preset)
          keymap = {
            preset = "enter";
            "<C-y>" = [ "select_and_accept" ];
            "<C-j>" = [
              "select_next"
              "fallback"
            ];
            "<C-k>" = [
              "select_prev"
              "fallback"
            ];
            "<Tab>" = [
              (lib.generators.mkLuaInline ''
                function(cmp)
                  if cmp.snippet_active() then
                    return cmp.snippet_forward()
                  end
                  return false
                end
              '')
              "fallback"
            ];
          };

          appearance = {
            nerd_font_variant = "mono";
            use_nvim_cmp_as_default = false;
          };

          completion = {
            accept = {
              auto_brackets = {
                enabled = true;
              };
            };

            ghost_text = {
              enabled = true;
            };

            menu = {
              draw = {
                treesitter = [ "lsp" ];
              };
            };

            documentation = {
              auto_show = true;
              auto_show_delay_ms = 200;
            };
          };

          sources = {
            default = [
              "lsp"
              "path"
              "snippets"
              "buffer"
            ];
          };

          cmdline = {
            enabled = true;
            keymap = {
              preset = "cmdline";
              "<Right>" = [ ];
              "<Left>" = [ ];
            };
            completion = {
              list = {
                selection = {
                  preselect = false;
                };
              };
              menu = {
                auto_show = lib.generators.mkLuaInline ''
                  function(ctx)
                    return vim.fn.getcmdtype() == ":"
                  end
                '';
              };
              ghost_text = {
                enabled = true;
              };
            };
          };
        };
      };

      # Enable snippets with luasnip
      snippets.luasnip.enable = true;

      # Additional luasnip configuration for Go snippets
      luaConfigRC.go-snippets = ''
        -- Go snippets for luasnip
        local ls = require("luasnip")
        local s = ls.snippet
        local t = ls.text_node
        local i = ls.insert_node
        local fmt = require("luasnip.extras.fmt").fmt

        ls.add_snippets("go", {
          -- Error handling: if err != nil
          s("enn", fmt([[
            if err != nil {{
              {}
            }}
          ]], { i(1, "return err") })),

          -- Error handling with return
          s("erreturn", fmt([[
            if err != nil {{
              return {}err
            }}
          ]], { i(1) })),

          -- Error handling with log.Fatal
          s("erfatal", fmt([[
            if err != nil {{
              fmt.Fatal(err)
            }}
          ]], {})),

          -- Error handling with log.Printf
          s("erlog", fmt([[
            if err != nil {{
              fmt.Printf("{}: %v", err)
            }}
          ]], { i(1, "error") })),

          -- Error handling with fmt.Errorf wrap
          s("erwrap", fmt([[
            if err != nil {{
              return fmt.Errorf("{}: %w", err)
            }}
          ]], { i(1, "failed to") })),
        })
      '';

      # Additional luasnip configuration for Flutter snippets
      luaConfigRC.flutter-snippets = ''
        -- Flutter snippets for luasnip
        local ls = require("luasnip")
        local s = ls.snippet
        local t = ls.text_node
        local i = ls.insert_node
        local fmt = require("luasnip.extras.fmt").fmt

        ls.add_snippets("dart", {
          -- StatelessWidget
          s("stless", fmt([[
            class {} extends StatelessWidget {{
              const {}({{super.key}});

              @override
              Widget build(BuildContext context) {{
                return {};
              }}
            }}
          ]], { i(1, "WidgetName"), i(1), i(2, "Container()") })),

          -- StatefulWidget
          s("stful", fmt([[
            class {} extends StatefulWidget {{
              const {}({{super.key}});

              @override
              State<{}> createState() => _{}State();
            }}

            class _{}State extends State<{}> {{
              @override
              Widget build(BuildContext context) {{
                return {};
              }}
            }}
          ]], {
            i(1, "WidgetName"),
            i(1),
            i(1),
            i(1),
            i(1),
            i(1),
            i(2, "Container()")
          })),

          -- Container
          s("container", fmt([[
            Container(
              {}
            )
          ]], { i(1) })),

          -- Column
          s("column", fmt([[
            Column(
              children: [
                {}
              ],
            )
          ]], { i(1) })),

          -- Row
          s("row", fmt([[
            Row(
              children: [
                {}
              ],
            )
          ]], { i(1) })),

          -- Center
          s("center", fmt([[
            Center(
              child: {},
            )
          ]], { i(1) })),

          -- Padding
          s("padding", fmt([[
            Padding(
              padding: const EdgeInsets.all({}),
              child: {},
            )
          ]], { i(1, "8.0"), i(2) })),

          -- Text
          s("text", fmt([[
            Text('{}')
          ]], { i(1, "text") })),

          -- Scaffold
          s("scaffold", fmt([[
            Scaffold(
              appBar: AppBar(
                title: const Text('{}'),
              ),
              body: {},
            )
          ]], { i(1, "Title"), i(2, "Container()") })),

          -- ListView
          s("listview", fmt([[
            ListView(
              children: [
                {}
              ],
            )
          ]], { i(1) })),

          -- ListView.builder
          s("listviewbuilder", fmt([[
            ListView.builder(
              itemCount: {},
              itemBuilder: (context, index) {{
                return {};
              }},
            )
          ]], { i(1, "10"), i(2, "ListTile()") })),

          -- SizedBox
          s("sizedbox", fmt([[
            SizedBox(
              width: {},
              height: {},
              child: {},
            )
          ]], { i(1, "100"), i(2, "100"), i(3) })),

          -- Expanded
          s("expanded", fmt([[
            Expanded(
              child: {},
            )
          ]], { i(1) })),

          -- Stack
          s("stack", fmt([[
            Stack(
              children: [
                {}
              ],
            )
          ]], { i(1) })),

          -- GestureDetector
          s("gesture", fmt([[
            GestureDetector(
              onTap: () {{
                {}
              }},
              child: {},
            )
          ]], { i(1), i(2) })),

          -- ElevatedButton
          s("elevatedbutton", fmt([[
            ElevatedButton(
              onPressed: () {{
                {}
              }},
              child: const Text('{}'),
            )
          ]], { i(1), i(2, "Button") })),

          -- TextButton
          s("textbutton", fmt([[
            TextButton(
              onPressed: () {{
                {}
              }},
              child: const Text('{}'),
            )
          ]], { i(1), i(2, "Button") })),

          -- IconButton
          s("iconbutton", fmt([[
            IconButton(
              icon: const Icon(Icons.{}),
              onPressed: () {{
                {}
              }},
            )
          ]], { i(1, "add"), i(2) })),
        })
      '';
    };
  };
}
