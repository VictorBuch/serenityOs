args@{
  config,
  pkgs,
  pkgs-stable,
  lib,
  mkModule,
  ...
}:

let
  # Same matched wine/yabridge pair reaper.nix installs, selected by the same option, so
  # the chainloaders in ~/.local/share/yabridge always belong to the running build.
  # The packages themselves are installed by reaper.nix; this module only wires up the
  # user-side files.
  track =
    (import ./_wine-tracks.nix { inherit pkgs pkgs-stable; }).${config.apps.audio.reaper.wineTrack};

  # Candidate plugin directories inside the wine prefixes. yabridgectl add is idempotent,
  # so this list is re-applied on every activation rather than once ever.
  #
  # CASING MATTERS. drive_c is a real Linux directory tree, so "VstPlugins" and
  # "VstPlugIns" are two different directories even though Windows considers them the
  # same. Wine writes into whichever spelling already exists, so which one an installer
  # lands in is down to who created it first. Watching only one spelling is how
  # AmpliTube's VST2 sat in VstPlugIns unbridged while its VST3 worked fine. List both.
  pluginDirs = [
    "$HOME/.wine-audio/drive_c/Program Files/Steinberg/VstPlugins"
    "$HOME/.wine-audio/drive_c/Program Files/VstPlugins"
    "$HOME/.wine-audio/drive_c/Program Files/VstPlugIns"
    "$HOME/.wine-audio/drive_c/Program Files/Common Files/VST3"
    "$HOME/.wine-audio/drive_c/Program Files/Common Files/CLAP"
    # Legacy prefix, from before the audio prefix was split out of the gaming one.
    "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
    "$HOME/.wine/drive_c/Program Files/Common Files/VstPlugins"
    "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
  ];

  # Shared preamble for every yabridge.toml. Documents the keys yabridge 5.1.1 actually
  # accepts, since silently-ignored typos are the usual failure mode here.
  tomlHeader = ''
    # Yabridge configuration -- MANAGED BY NIX (modules/apps/audio/yabridge.nix)
    # Docs: https://github.com/robbert-vdh/yabridge#configuration
    #
    # yabridge only reads yabridge.toml files sitting next to the bridged .so/.clap files
    # or in a parent directory of them -- i.e. exactly here, in ~/.vst{,3}/yabridge and
    # ~/.clap/yabridge. It does NOT read ~/.config/yabridge/yabridge.toml; a file there
    # is silently ignored.
    #
    # Valid keys in yabridge 5.1.1: disable_pipes, editor_coordinate_hack,
    # editor_disable_host_scaling, editor_force_dnd, editor_xembed, frame_rate, group,
    # hide_daw, vst3_prefer_32bit. Anything else is ignored without warning.
    #
    # Debugging: run `YABRIDGE_DEBUG_LEVEL=1 reaper` from a terminal.
  '';
in

mkModule {
  name = "yabridge";
  platforms = [ "linux" ];
  category = "audio";
  description = "Yabridge configuration for Windows VST plugins with copy protection support";

  # No packages here -- reaper.nix installs yabridge/yabridgectl so there is exactly
  # one place deciding which track is active.

  homeConfig =
    { lib, ... }:
    {
      home.file = {
        # Chainloaders and hosts. yabridgectl syncs plugin stubs that dlopen these, so
        # they must always match the yabridge build the stubs were synced with.
        ".local/share/yabridge/yabridge-host.exe" = {
          source = "${track.yabridge}/bin/yabridge-host.exe";
          force = true; # Overwrite existing files from manual installation
        };
        ".local/share/yabridge/libyabridge-chainloader-vst2.so" = {
          source = "${track.yabridge}/lib/libyabridge-chainloader-vst2.so";
          force = true;
        };
        ".local/share/yabridge/libyabridge-chainloader-vst3.so" = {
          source = "${track.yabridge}/lib/libyabridge-chainloader-vst3.so";
          force = true;
        };
        ".local/share/yabridge/libyabridge-chainloader-clap.so" = {
          source = "${track.yabridge}/lib/libyabridge-chainloader-clap.so";
          force = true;
        };

      }
      // lib.optionalAttrs track.has32bitHost {
        # Only the stable (pinned-track) yabridge still builds the 32-bit bitbridge host.
        # Linking it unconditionally would break the modern track at build time, since the
        # file simply is not in that output.
        ".local/share/yabridge/yabridge-host-32.exe" = {
          source = "${track.yabridge}/bin/yabridge-host-32.exe";
          force = true;
        };
      }
      // {
        # === VST2 ===
        ".vst/yabridge/yabridge.toml" = {
          text = ''
            ${tomlHeader}
            # === Global defaults ===
            ["*"]
            # Wine handles fractional scaling badly; if plugin GUIs come out the wrong
            # size, set the font DPI in `audio-winetricks winecfg` rather than flipping
            # this, which only affects VST3/CLAP host-driven scaling.
            editor_disable_host_scaling = false

            # REAPER's FX window swallows drops otherwise.
            editor_force_dnd = true

            frame_rate = 60

            # === IK Multimedia (AmpliTube, TONEX, T-RackS, MODO, ...) ===
            # frame_rate 120 keeps their animated meters smooth.
            #
            # editor_xembed forces real X11 embedding instead of yabridge's default
            # reparenting. Under the default, AmpliTube hangs REAPER on load: the last
            # thing the bridge logs is
            #   IPlugView::attached(parent = ..., "X11EmbedWindowID")
            # with no reply, the yabridge host goes defunct, and REAPER blocks in
            # futex_do_wait. xembed is the documented remedy for exactly that.
            #
            # TWO WAYS THESE SECTIONS SILENTLY DO NOTHING, both hit here already:
            #   1. The globs are CASE-SENSITIVE. "*Amplitube*" never matches "AmpliTube".
            #   2. They match the BRIDGED path, which for a VST3 bundle continues past
            #      the .vst3 into "Foo.vst3/Contents/x86_64-linux/Foo.so". A pattern
            #      ending in ".vst3" therefore matches nothing.
            # A section that matches nothing is not an error -- the plugin quietly falls
            # through to ["*"]. Always confirm with:
            #   YABRIDGE_DEBUG_LEVEL=1 reaper 2>&1 | grep "config from"
            #
            # No `group` here: group hosting needs yabridge-group-host.exe, which this
            # yabridge build does not ship (bin/ has only yabridge-host{,-32}.exe).
            ["*AmpliTube*"]
            frame_rate = 120
            editor_xembed = true

            ["*IK Multimedia*"]
            frame_rate = 120
            editor_xembed = true

            ["*TONEX*"]
            frame_rate = 120
            editor_xembed = true

            ["*T-RackS*"]
            frame_rate = 120
            editor_xembed = true

            # === Steven Slate (SSD5, ...) ===
            # Known unfixable-from-config bug: dragging an instrument onto the kit inside
            # SSD5's own browser crashes the plugin under wine. Load preset kits instead.
            ["*SSD5*"]

            ["*Slate*"]

            # === FabFilter ===
            ["*FabFilter*"]
          '';
          force = true;
        };

        # === VST3 ===
        ".vst3/yabridge/yabridge.toml" = {
          text = ''
            ${tomlHeader}
            ["*"]
            editor_disable_host_scaling = false
            editor_force_dnd = true
            frame_rate = 60

            # NO ".vst3" SUFFIX on these patterns. yabridge matches the bridged path,
            # which for a bundle is "Foo.vst3/Contents/x86_64-linux/Foo.so" -- anything
            # ending in ".vst3" matches nothing at all. See the VST2 config above.
            ["*AmpliTube*"]
            frame_rate = 120
            editor_xembed = true

            ["*IK Multimedia*"]
            frame_rate = 120
            editor_xembed = true

            ["*TONEX*"]
            frame_rate = 120
            editor_xembed = true

            ["*T-RackS*"]
            frame_rate = 120
            editor_xembed = true

            # No drag-drop of instruments onto the kit. See VST2 config.
            ["*SSD5*"]

            ["*Slate*"]

            ["*FabFilter*"]
            editor_disable_host_scaling = true
          '';
          force = true;
        };

        # === CLAP ===
        ".clap/yabridge/yabridge.toml" = {
          text = ''
            ${tomlHeader}
            ["*"]
            editor_disable_host_scaling = false
            editor_force_dnd = true
            frame_rate = 60

            # See the VST2 config above for the xembed rationale and the two ways these
            # sections silently match nothing.
            ["*AmpliTube*"]
            frame_rate = 120
            editor_xembed = true

            ["*IK Multimedia*"]
            frame_rate = 120
            editor_xembed = true

            ["*TONEX*"]
            frame_rate = 120
            editor_xembed = true
          '';
          force = true;
        };
      };

      # Re-register plugin directories and re-sync on EVERY activation.
      #
      # This used to be guarded on ~/.config/yabridgectl/config.toml not existing, which
      # meant it ran exactly once, ever: plugins installed later, and yabridge version
      # bumps, never made it into ~/.vst*. `yabridgectl add` is idempotent and `sync` is
      # cheap, so just always do both. `|| true` keeps a half-built prefix from failing
      # the whole activation.
      home.activation.setupYabridge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.vst/yabridge" "$HOME/.vst3/yabridge" "$HOME/.clap/yabridge"

        ${lib.concatMapStringsSep "\n" (dir: ''
          if [ -d "${dir}" ]; then
            $DRY_RUN_CMD ${track.yabridgectl}/bin/yabridgectl add "${dir}" || true
          fi
        '') pluginDirs}

        $DRY_RUN_CMD ${track.yabridgectl}/bin/yabridgectl sync || true
      '';
    };
} args
