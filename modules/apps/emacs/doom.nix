args@{
  config,
  pkgs,
  lib,
  mkModule,
  inputs,
  ...
}:

# Doom Emacs — FULLY DECLARATIVE via nix-doom-emacs-unstraightened.

mkModule {
  name = "doom";
  category = "emacs";
  
  description = "Doom Emacs (declarative) via nix-doom-emacs-unstraightened: nix builds Doom + all packages, config in repo ./doom.d";

  extraConfig = {
    home-manager.sharedModules = [
      inputs.nix-doom-emacs-unstraightened.homeModule
    ];
  };

  homeConfig =
    { pkgs, ... }:
    {
      programs.doom-emacs = {
        enable = true;

        doomDir = ./doom.d;

        tangleArgs = "--all config.org";

        extraBinPackages = with pkgs; [
          # Doom hard deps
          ripgrep
          fd
          git
          coreutils
          findutils

          # spell (checkers (spell +aspell))
          (aspellWithDicts (d: [ d.en ]))

          # org-excalidraw: renders .excalidraw -> SVG on save.
          # Pin to nodejs_22: the package's bump-nan.patch targets node 22, and
          # unstable's default node 24 dropped the old v8::ScriptOrigin ctor that
          # node-canvas@2.11.2 (via nan) still uses, breaking the native build.
          (excalidraw_export.override {
            buildNpmPackage = buildNpmPackage.override { nodejs = nodejs_22; };
          })

          # language servers (lsp +eglot)
          typescript-language-server # js/ts/jsx/tsx (React)
          vscode-langservers-extracted # html, css, json, eslint
          kotlin-language-server # kotlin / jetpack compose
          nil # nix
          bash-language-server # sh +lsp
          yaml-language-server # yaml +lsp
          tailwindcss-language-server
          # dart/flutter ship their own LSP via the flutter sdk.

          # linters (flycheck, alongside eglot)
          oxlint # js/ts/jsx/tsx lint diagnostics (gated on .oxlintrc.json)

          # formatters (apheleia / format +onsave)
          prettier # js/ts/jsx/tsx/json/css/html/md/yaml
          ktlint # kotlin
          nixfmt # nix
          shfmt # shell
        ];
      };

      services.emacs = {
        enable = true;
        defaultEditor = true; 
      };
    };
} args
