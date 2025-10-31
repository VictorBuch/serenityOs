{
  programs.nixvim.plugins.lint = {
    enable = true;
    lintersByFt = {
      # JavaScript/TypeScript
      javascript = [ "eslint" ];
      javascriptreact = [ "eslint" ];
      typescript = [ "eslint" ];
      typescriptreact = [ "eslint" ];
      vue = [ "eslint" ];
      svelte = [ "eslint" ];

      # Go
      go = [ "golangcilint" ];
    };
    autoCmd = {
      event = [ "BufWritePost" "TextChanged" ];
      callback.__raw = ''
        function()
          -- Check if eslint config exists for JS/TS files before linting
          local ft = vim.bo.filetype
          local eslint_filetypes = {
            javascript = true,
            javascriptreact = true,
            typescript = true,
            typescriptreact = true,
            vue = true,
            svelte = true,
          }

          if eslint_filetypes[ft] then
            -- Look for eslint config files
            local eslint_configs = {
              ".eslintrc.js",
              ".eslintrc.cjs",
              ".eslintrc.yaml",
              ".eslintrc.yml",
              ".eslintrc.json",
              ".eslintrc",
              "eslint.config.js",
              "eslint.config.mjs",
              "eslint.config.cjs",
            }

            local root_dir = vim.fs.dirname(vim.fs.find(eslint_configs, {
              upward = true,
              path = vim.api.nvim_buf_get_name(0),
            })[1])

            -- Also check package.json for eslintConfig
            if not root_dir then
              local package_json = vim.fs.find("package.json", {
                upward = true,
                path = vim.api.nvim_buf_get_name(0),
              })[1]

              if package_json then
                local content = vim.fn.readfile(package_json)
                local json_str = table.concat(content, "\n")
                if string.find(json_str, '"eslintConfig"') then
                  root_dir = vim.fs.dirname(package_json)
                end
              end
            end

            -- Only lint if eslint config found
            if root_dir then
              require("lint").try_lint()
            end
          else
            -- For non-JS/TS files, always try to lint
            require("lint").try_lint()
          end
        end
      '';
    };
  };
}
