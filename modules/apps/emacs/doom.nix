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

  # emacs binary + Doom's hard runtime deps. Identical on NixOS and macOS.
  # Doom needs: git, ripgrep, fd, GNU coreutils (gls on macOS), findutils.
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
    ];

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
