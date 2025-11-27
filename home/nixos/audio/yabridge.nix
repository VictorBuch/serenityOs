args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  _file = toString ./.;
  name = "yabridge";
  description = "Yabridge configuration for Windows VST plugins";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Create symlinks to yabridge binaries in the expected location
      home.file = {
        ".local/share/yabridge/yabridge-host.exe".source = "${pkgs.yabridge}/bin/yabridge-host.exe";
        ".local/share/yabridge/yabridge-host-32.exe".source = "${pkgs.yabridge}/bin/yabridge-host-32.exe";
        ".local/share/yabridge/libyabridge-chainloader-vst2.so".source =
          "${pkgs.yabridge}/lib/libyabridge-chainloader-vst2.so";
        ".local/share/yabridge/libyabridge-chainloader-vst3.so".source =
          "${pkgs.yabridge}/lib/libyabridge-chainloader-vst3.so";
        ".local/share/yabridge/libyabridge-chainloader-clap.so".source =
          "${pkgs.yabridge}/lib/libyabridge-chainloader-clap.so";
      };

      # Create VST wrapper directories
      home.activation.setupYabridge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create VST directories
        $DRY_RUN_CMD mkdir -p $HOME/.vst/yabridge
        $DRY_RUN_CMD mkdir -p $HOME/.vst3/yabridge
        $DRY_RUN_CMD mkdir -p $HOME/.clap/yabridge

        # Configure yabridgectl to monitor Windows VST paths
        if [ ! -f $HOME/.config/yabridgectl/config.toml ]; then
          echo "Setting up yabridgectl configuration..."

          # Add Wine VST2 path (Steinberg convention)
          if [ -d "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins" ]; then
            $DRY_RUN_CMD ${pkgs.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
          fi

          # Add Wine VST3 path (Windows standard location)
          if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VST3" ]; then
            $DRY_RUN_CMD ${pkgs.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
          fi

          if [ -d "$HOME/.wine/drive_c/Program Files/Common Files/VST3" ]; then
            $DRY_RUN_CMD ${pkgs.yabridgectl}/bin/yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VstPlugins"
          fi
          # Sync yabridge configuration
          $DRY_RUN_CMD ${pkgs.yabridgectl}/bin/yabridgectl sync
        fi
      '';
    };
} args
