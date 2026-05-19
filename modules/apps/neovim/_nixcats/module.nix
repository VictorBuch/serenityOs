inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  options,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  # Plugins fetched from flake inputs prefixed with `plugins-` are exposed at
  # config.nvim-lib.neovimPlugins.<name>. Add more via flake.nix inputs.
  options.nvim-lib.neovimPlugins = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf wlib.types.stringable;
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  # LazyVim distro from flake input (locked, reproducible).
  # Swap for hot-iteration on ~/.config/nvim:
  #   config.settings.config_directory = lib.generators.mkLuaInline "vim.fn.stdpath('config')";
  # Or vendor lua into this dir:
  #   config.settings.config_directory = ./.;
  config.settings.config_directory = inputs.lazyvim-config.outPath;

  # lze + lzextras: lazy-loader. Required for the `for_cat` / `auto_enable`
  # handlers the init.lua wires up.
  config.specs.lze = [
    config.nvim-lib.neovimPlugins.lze
    {
      name = "lzextras";
      data = config.nvim-lib.neovimPlugins.lzextras;
    }
  ];

  # ---- Category buckets ----
  # Each top-level spec becomes settings.cats.<name> (bool) on the lua side,
  # used by lze's for_cat handler to gate plugins per-host.

  # lazy.nvim handles plugin install at runtime from your LazyVim distro,
  # so plugin `data` is left empty. runtimePkgs provides binaries that
  # LazyVim/Mason/treesitter need on PATH.
  config.specs.general = {
    after = [ "lze" ];
    data = null;
    runtimePkgs = with pkgs; [
      # lazy.nvim + git clone for plugin install
      git
      curl
      # telescope/snacks pickers
      ripgrep
      fd
      fzf
      # ui
      lazygit
      # treesitter parser compile
      tree-sitter
      gcc
      gnumake
      unzip
      # mason runtime (LSP/formatter downloads — disable mason if you don't want it)
      nodejs
      python3
    ];
  };

  # Native LSPs/formatters via nix instead of (or alongside) Mason.
  # Add more here, then in lua disable the matching mason install.
  config.specs.lsp = {
    after = [ "general" ];
    data = null;
    runtimePkgs = with pkgs; [
      lua-language-server
      stylua
      nixd
      nixfmt
      bash-language-server
      shfmt
      typescript-language-server
      vtsls
      tailwindcss-language-server
      yaml-language-server
      vscode-langservers-extracted # json/html/css/eslint
      gopls
      rust-analyzer
      pyright
    ];
  };

  # ---- specMods: forward runtimePkgs onto the PATH at the spec level ----
  config.specMods =
    { config, ... }:
    {
      options.runtimePkgs = options.runtimePkgs // {
        description = "Packages added to PATH when this spec is enabled.";
      };
    };
  config.runtimePkgs = config.specCollect (acc: v: acc ++ (v.runtimePkgs or [ ])) [ ];

  # Expose enable-state of each top-level spec to lua via the nix_info plugin.
  options.settings.cats = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf lib.types.bool;
    default = builtins.mapAttrs (_: v: v.enable) config.specs;
  };

  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      prefix: inputs:
      lib.pipe inputs [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input:
          let
            name = lib.removePrefix prefix input;
          in
          {
            inherit name;
            value = config.nvim-lib.mkPlugin name inputs.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };
}
