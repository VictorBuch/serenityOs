args@{ config, pkgs, lib, mkModule, ... }:

# Doom Emacs — LIGHT declarative install.
#
# Nix installs ONLY the emacs binary, Doom's runtime dependencies, and the
# emacs daemon. The Doom framework itself (~/.config/emacs) and your private
# config (~/.config/doom) stay imperative: bootstrap once with `doom install`
# and keep packages fresh with `doom sync`. Nix never touches those files, so
# you keep editing ~/.config/doom freely on both NixOS and macOS.
#
# Enable per-host with `apps.emacs.enable = true;`.
mkModule {
  name = "doom";
  category = "emacs";
  description = "Doom Emacs (light): nix installs emacs + Doom deps + daemon; framework/packages stay imperative via doom sync";

  # emacs binary + Doom's hard runtime deps + language servers/formatters.
  # Doom needs: git, ripgrep, fd, GNU coreutils (gls on macOS), findutils.
  # LSP servers are found off PATH by eglot; formatters by apheleia (format +onsave).
  packages =
    { pkgs, ... }:
    with pkgs;
    [
      emacs
      git
      ripgrep
      fd
      coreutils
      findutils

      # --- spell (checkers (spell +aspell)) ---
      (aspellWithDicts (d: [ d.en ]))

      # --- language servers (eglot, lsp +eglot) ---
      typescript-language-server # js/ts/jsx/tsx (React)
      vscode-langservers-extracted # html, css, json, eslint
      kotlin-language-server # kotlin / jetpack compose
      nil # nix
      # dart/flutter ship their own LSP (`dart language-server`) via the flutter sdk.
      bash-language-server # sh +lsp
      yaml-language-server # yaml +lsp

      # --- vterm: precompiled native module from nix. Doom must NOT compile
      #     it via straight.el (needs GNU libtool/cmake; fails on macOS with
      #     "glibtool: No such file"). nixpkgs emacs' site-start.el scans
      #     NIX_PROFILES share/emacs/site-lisp, so installing the package here
      #     puts vterm on the load-path. Pair with
      #     `(package! vterm :built-in 'prefer)` in packages.el. ---
      emacsPackages.vterm

      # --- formatters (apheleia / format +onsave) ---
      prettier # js/ts/jsx/tsx/json/css/html/md/yaml
      ktlint # kotlin
      nixfmt-rfc-style # nix
      shfmt # shell
    ];

  # macOS only: nix-darwin's default environment.pathsToLink omits /share/emacs,
  # so emacsPackages.vterm (which ships ONLY share/emacs/site-lisp) would have
  # zero files linked into /run/current-system/sw and drop out of the system
  # closure entirely. Link /share/emacs so the precompiled vterm module lands in
  # the profile where emacs' site-start.el (and our config.el load-path scan)
  # can find it. NixOS links "/" by default, so it needs nothing here.
  darwinExtraConfig = {
    environment.pathsToLink = [ "/share/emacs" ];
  };

  # Emacs daemon via Home Manager — cross-platform: a systemd user service on
  # NixOS, a launchd agent on macOS. emacsclient then connects instantly.
  homeConfig =
    { pkgs, ... }:
    {
      services.emacs = {
        enable = true;
        package = pkgs.emacs;
        defaultEditor = false; # keep nvim as $EDITOR
      };
    };
} args
