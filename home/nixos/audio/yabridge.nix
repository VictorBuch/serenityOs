args@{
  config,
  pkgs,
  pkgs-stable,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  _file = toString ./.;
  name = "yabridge";
  description = "Yabridge configuration for Windows VST plugins with copy protection support";
  homeConfig =
    {
      config,
      pkgs,
      pkgs-stable,
      lib,
      ...
    }:
    {
      # Create symlinks to yabridge binaries in the expected location
      # Use pkgs-stable for yabridge to avoid breaking changes in audio stack
      home.file = {
        ".local/share/yabridge/yabridge-host.exe" = {
          source = "${pkgs-stable.yabridge}/bin/yabridge-host.exe";
          force = true; # Overwrite existing files from manual installation
        };
        ".local/share/yabridge/yabridge-host-32.exe" = {
          source = "${pkgs-stable.yabridge}/bin/yabridge-host-32.exe";
          force = true;
        };
        ".local/share/yabridge/libyabridge-chainloader-vst2.so" = {
          source = "${pkgs-stable.yabridge}/lib/libyabridge-chainloader-vst2.so";
          force = true;
        };
        ".local/share/yabridge/libyabridge-chainloader-vst3.so" = {
          source = "${pkgs-stable.yabridge}/lib/libyabridge-chainloader-vst3.so";
          force = true;
        };
        ".local/share/yabridge/libyabridge-chainloader-clap.so" = {
          source = "${pkgs-stable.yabridge}/lib/libyabridge-chainloader-clap.so";
          force = true;
        };

        # Yabridge configuration for VST2 plugins
        # This configures compatibility options and plugin groups
        ".vst/yabridge/yabridge.toml" = {
          text = ''
            # Yabridge Configuration for Audio Plugins
            # Documentation: https://github.com/robbert-vdh/yabridge#configuration
            #
            # IMPORTANT NOTES:
            # - Wine 9.21 is recommended (9.22+ has GUI issues)
            # - Use WINEFSYNC=1 for better performance (kernel 5.16+ required)
            # - DXVK is installed for modern plugin GUIs
            #
            # For debugging plugin issues, launch your DAW from terminal and check output,
            # or set YABRIDGE_DEBUG_LEVEL=1 (or 2 for verbose)

            # === Global Settings ===
            # Applied to all plugins that don't have their own section
            ["*"]
            # Disable host-driven HiDPI scaling if you have display issues
            # Wine doesn't handle fractional scaling well - set font DPI to 192 in winecfg for 200% scale
            editor_disable_host_scaling = false

            # Enable drag-and-drop support in REAPER (REAPER's FX window intercepts drops otherwise)
            editor_force_dnd = true

            # Frame rate for plugin GUI updates (default: 60)
            frame_rate = 60

            # === IK Multimedia Plugins (Amplitube 5, etc.) ===
            # Group IK plugins together for inter-plugin communication
            ["*Amplitube*"]
            group = "ik-multimedia"

            ["*IK Multimedia*"]
            group = "ik-multimedia"

            ["*T-RackS*"]
            group = "ik-multimedia"

            # === Steven Slate Plugins (SSD5, etc.) ===
            ["*SSD5*"]
            # SSD5 may need these if you encounter issues:
            # editor_coordinate_hack = true  # Uncomment if GUI renders in wrong position
            # hide_daw = true                # Uncomment if text input causes crashes

            ["*Slate*"]
            # Group Slate plugins if you need inter-plugin communication

            # === FabFilter Plugins ===
            # FabFilter plugins (like Pro-Q 3) need grouping for analyzer features
            ["*FabFilter*"]
            group = "fabfilter"

            # === Known Problematic Plugins ===
            # PSPaudioware E27 and Soundtoys Crystallizer need this:
            # ["*PSPaudioware*"]
            # editor_coordinate_hack = true

            # ["*Soundtoys*"]
            # editor_coordinate_hack = true

            # Plugins that need XEmbed (use only if normal embedding fails):
            # ["*SomePlugin*"]
            # editor_xembed = true

            # Plugins with console output issues (like ujam/LoopCloud):
            # ["*LoopCloud*"]
            # disable_pipes = true

            # === Plugin Groups for Performance ===
            # Uncomment to host all plugins in a single process (faster loading, less isolation)
            # ["*"]
            # group = "all"
          '';
          force = true;
        };

        # Yabridge configuration for VST3 plugins
        ".vst3/yabridge/yabridge.toml" = {
          text = ''
            # Yabridge VST3 Configuration
            # Note: Multiple instances of VST3 plugins share a process by design
            # Groups are mainly useful for faster initial loading across different plugins

            ["*"]
            editor_disable_host_scaling = false
            editor_force_dnd = true

            # IK Multimedia VST3 plugins
            ["*Amplitube*.vst3"]
            group = "ik-multimedia"

            # FabFilter VST3 plugins
            ["*FabFilter*.vst3"]
            group = "fabfilter"
            editor_disable_host_scaling = true
          '';
          force = true;
        };

        # Yabridge configuration for CLAP plugins
        ".clap/yabridge/yabridge.toml" = {
          text = ''
            # Yabridge CLAP Configuration
            # CLAP plugins also share processes by design like VST3

            ["*"]
            editor_disable_host_scaling = false
            editor_force_dnd = true
          '';
          force = true;
        };
      };

      # Create VST wrapper directories and configure yabridgectl
      home.activation.setupYabridge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create VST directories
        $DRY_RUN_CMD mkdir -p $HOME/.vst/yabridge
        $DRY_RUN_CMD mkdir -p $HOME/.vst3/yabridge
        $DRY_RUN_CMD mkdir -p $HOME/.clap/yabridge

        # Audio WINEPREFIX path (separate from gaming Wine)
        AUDIO_PREFIX="$HOME/.wine-audio"

        # Configure yabridgectl if not already configured
        if [ ! -f $HOME/.config/yabridgectl/config.toml ]; then
          echo "Setting up yabridgectl configuration..."

          # === Audio WINEPREFIX paths (primary) ===
          # VST2 plugins (Steinberg convention)
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/Steinberg/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/Steinberg/VstPlugins"
          fi

          # VST2 plugins (alternative location)
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/VstPlugins"
          fi

          # VST3 plugins (Windows standard)
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/Common Files/VST3" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/Common Files/VST3"
          fi

          # CLAP plugins
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/Common Files/CLAP" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/Common Files/CLAP"
          fi

          # === Legacy .wine prefix paths (fallback for existing installations) ===
          if [ -d "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
          fi

          if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VST3" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
          fi

          if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VstPlugins"
          fi

          # Sync yabridge configuration
          $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl sync
        fi
      '';
    };
} args
