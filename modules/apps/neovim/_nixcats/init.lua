-- nixCats / nix-wrapper-modules entry point.
-- Replace this file (and add lua/ subdirs alongside it) with your LazyVim
-- distribution. Everything in this directory becomes $XDG_CONFIG_HOME/nvim
-- for the wrapped binary.
--
-- Access nix-injected values:
--   local nixInfo = require(vim.g.nix_info_plugin_name)
--   nixInfo(nil, "settings", "cats", "lsp")   -- true/false
--   nixInfo.lze.load { ... }                  -- lze handler entry
--
-- Quick inspection: `:lua require('lzextras').debug.display(require(vim.g.nix_info_plugin_name))`

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local ok, nixInfo = pcall(require, vim.g.nix_info_plugin_name)
if not ok then
  vim.notify("nix_info plugin missing — running outside nix wrapper?", vim.log.levels.WARN)
  return
end

-- Register lze handlers so plugin specs can use `for_cat = "lsp"` etc.
local lze_ok, lze = pcall(require, "lze")
if lze_ok then
  lze.register_handlers(require("lzextras").for_cat)
  lze.register_handlers(require("lzextras").auto_enable)
end

-- Minimal smoke-test: list which categories nix enabled.
vim.api.nvim_create_user_command("NixCats", function()
  local cats = nixInfo(nil, "settings", "cats") or {}
  for k, v in pairs(cats) do
    print(string.format("%-12s %s", k, v and "on" or "off"))
  end
end, {})

print("nixCats neovim loaded — replace _nixcats/init.lua with your LazyVim config")
