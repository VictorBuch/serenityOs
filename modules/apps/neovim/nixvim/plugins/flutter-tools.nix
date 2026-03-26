{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      flutter-tools-nvim
      plenary-nvim
    ];

    extraConfigLua = ''
      -- Flutter Tools setup
      require('flutter-tools').setup({
        decorations = {
          statusline = {
            app_version = true,
            device = true
          }
        },
        widget_guides = {
          enabled = true
        }
      })

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

      -- Auto hot reload Flutter on save
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.dart",
        callback = function()
          -- Check if Flutter is running
          local flutter_running = vim.fn.system("pgrep -f 'flutter run'"):len() > 0
          if flutter_running then
            vim.cmd("FlutterReload")
          end
        end,
      })
    '';
  };
}
