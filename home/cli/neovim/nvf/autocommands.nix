{ config, lib, ... }:

{
  config = lib.mkIf config.home.cli.neovim.nvf.enable {
    programs.nvf.settings.vim.luaConfigRC = {
      # Highlight text on yank
      highlight-yank = ''
        vim.api.nvim_create_autocmd('TextYankPost', {
          group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
          desc = 'Highlight selection on yank',
          pattern = '*',
          callback = function()
            vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
          end,
        })
      '';

      # Close special buffers with 'q'
      close-with-q = ''
        vim.api.nvim_create_autocmd('FileType', {
          pattern = { 'qf', 'help', 'man', 'notify', 'lspinfo', 'trouble', 'checkhealth' },
          callback = function(event)
            vim.bo[event.buf].buflisted = false
            vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
          end,
        })
      '';

      # Flutter hot reload on save
      flutter-hot-reload = ''
        vim.api.nvim_create_autocmd('BufWritePost', {
          pattern = '*.dart',
          callback = function()
            -- Check if Flutter is running
            local flutter_running = vim.fn.system("pgrep -f 'flutter run'"):len() > 0
            if flutter_running then
              vim.cmd('FlutterReload')
            end
          end,
        })
      '';
    };
  };
}
