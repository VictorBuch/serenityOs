args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

let
  # `monoFamily` comes from osConfig.fonts.mono.familyMono, so it follows the
  # `fonts.mono.preset` switch in modules/common/fonts.nix. The Mono variant is
  # deliberate: the jetbrains-mono preset's plain `family` is proportional-ish,
  # only `familyMono` guarantees a fixed advance width (this is the same option
  # stylix's ghostty target used to read before it was disabled).
  ghosttySettings = monoFamily: {
    # Colors come from noctalia's `ghostty` template: it writes
    # ~/.config/ghostty/themes/noctalia from the wallpaper palette and reloads
    # ghostty live (SIGUSR2). This `theme` line makes noctalia's apply step a
    # no-op edit (the key is already present) so it only writes the theme file.
    theme = "noctalia";
    # Transparency is NOT covered by noctalia's ghostty template — that template
    # only writes palette/background/foreground/cursor/selection. Stylix used to
    # supply this from `opacity.terminal`, but its ghostty target is disabled (it
    # bundles colors+opacity+fonts behind one switch), so opacity has to be set
    # here or the window renders fully opaque. Sorts before `theme` in the
    # generated config, which is fine: the theme file never sets an opacity key,
    # so there is nothing to clobber it.
    background-opacity = 0.85;
    alpha-blending = "native";
    window-decoration = false;
    confirm-close-surface = false;
    # Same story as background-opacity: the disabled stylix target was also the
    # only writer of font-family, so without this ghostty silently falls back to
    # its own bundled default instead of the configured mono font. font-size
    # stays pinned here rather than tracking stylix's fonts.sizes.terminal.
    font-family = monoFamily;
    font-size = 14;
    mouse-scroll-multiplier = 1;
  };
in

mkModule {
  name = "ghostty";
  category = "development";
  linuxPackages = { pkgs, ... }: [ pkgs.ghostty ];
  darwinExtraConfig = {
    homebrew.casks = [ "ghostty" ];
  };
  description = "Ghostty terminal emulator";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      osConfig ? { },
      ...
    }:
    let
      # Fall back to the generic "monospace" fontconfig alias if fonts.nix is not
      # in play (bare HM, or a host with fonts.enable = false) so this module
      # still evaluates standalone.
      settings =
        ghosttySettings (lib.attrByPath [ "fonts" "mono" "familyMono" ] "monospace" osConfig)
        // {
          # Live Seam. The leading `?` suppresses the error when the file is
          # absent, and ghostty loads included files *after* the config that
          # names them, so anything here wins. Absolute path on purpose: a
          # relative one resolves against the config file, which is a store
          # symlink. Reload with SIGUSR2 or ctrl+shift+comma.
          config-file = "?${config.home.homeDirectory}/.config/ghostty/local";
        };
    in
    {
      programs.ghostty = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        inherit settings;
      };

      home.activation.ghosttyLocalSeam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        seam="$HOME/.config/ghostty/local"
        if [ ! -e "$seam" ]; then
          mkdir -p "$(dirname "$seam")"
          echo '# Live Seam -- not managed by Nix. Loaded after the generated' > "$seam"
          echo '# config, so settings here win. Reload with ctrl+shift+comma.' >> "$seam"
        fi
      '';
      xdg.configFile."ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
        text = lib.generators.toKeyValue { } settings;
      };
    };
} args
