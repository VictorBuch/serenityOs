args@{
  config,
  pkgs,
  lib,
  mkModule,
  inputs,
  ...
}:

# Doom Emacs — FULLY DECLARATIVE via nix-doom-emacs-unstraightened.
#
# Nix builds Doom AND every package it declares (no straight.el, no
# `doom sync`). The config lives in this repo at ./doom.d (init.el,
# packages.el, config.org) and is bundled read-only into the store, so the
# enabled modules always match the deps nix builds. Edit ./doom.d and
# rebuild (`darwin-rebuild switch` / `nixos-rebuild switch`) to apply.
#
# Mutable Doom state (cache/data) lives in $XDG_DATA_HOME/nix-doom, NOT in
# ~/.config/doom — the old imperative dir is left untouched and unused.
#
# Enable per-host with `apps.emacs.enable = true;`.
mkModule {
  name = "doom";
  category = "emacs";
  description = "Doom Emacs (declarative) via nix-doom-emacs-unstraightened: nix builds Doom + all packages, config in repo ./doom.d";

  # Make the unstraightened home-manager module available to Home Manager.
  # Cross-platform: same module on NixOS and Darwin.
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

        # Bundled DOOMDIR — copied into the nix store at build time.
        doomDir = ./doom.d;

        # `:config literate` is a no-op under unstraightened; this tangles
        # config.org -> config.el inside the build sandbox instead.
        tangleArgs = "--all config.org";

        # Binaries Doom needs on its PATH at runtime. Overrides the module's
        # default [ ripgrep git fd ], so re-list those plus our LSPs/formatters.
        # eglot finds language servers here; apheleia finds formatters.
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

      # Emacs daemon — systemd user service on NixOS, launchd agent on macOS.
      # The module wires its wrapped emacs into services.emacs.package itself.
      services.emacs = {
        enable = true;
        defaultEditor = true; # keep nvim as $EDITOR
      };
    };
} args
