args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "yabridge";
  category = "audio";
  description = "Yabridge configuration for Windows VST plugins with copy protection support";
  linuxPackages = { pkgs-stable, ... }: [
    pkgs-stable.yabridge
    pkgs-stable.yabridgectl
  ];
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
            ["*Amplitube*"]
            group = "ik-multimedia"

            ["*IK Multimedia*"]
            group = "ik-multimedia"

            ["*T-RackS*"]
            group = "ik-multimedia"

            # === Steven Slate Plugins (SSD5, etc.) ===
            ["*SSD5*"]

            ["*Slate*"]

            # === FabFilter Plugins ===
            ["*FabFilter*"]
            group = "fabfilter"
          '';
          force = true;
        };

        # Yabridge configuration for VST3 plugins
        ".vst3/yabridge/yabridge.toml" = {
          text = ''
            # Yabridge VST3 Configuration
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

          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/Steinberg/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/Steinberg/VstPlugins"
          fi
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/VstPlugins"
          fi
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/Common Files/VST3" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/Common Files/VST3"
          fi
          if [ -d "$AUDIO_PREFIX/drive_c/Program Files/Common Files/CLAP" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$AUDIO_PREFIX/drive_c/Program Files/Common Files/CLAP"
          fi

          # Legacy .wine prefix paths
          if [ -d "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
          fi
          if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VST3" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
          fi
          if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VstPlugins"
          fi

          $DRY_RUN_CMD ${pkgs-stable.yabridgectl}/bin/yabridgectl sync
        fi
      '';
    };
} args
