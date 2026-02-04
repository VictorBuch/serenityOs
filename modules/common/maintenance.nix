{
  config,
  pkgs,
  lib,
  inputs,
  isLinux ? pkgs.stdenv.isLinux,
  ...
}:
let
  cfg = config;
in
{

  options = {
    maintenance.enable = lib.mkEnableOption "Enables all maintenance tasks";

    # Cross-platform options
    gc.enable = lib.mkEnableOption "Enable garbage collection";
  }
  // lib.optionalAttrs isLinux {
    # Linux-only options (only define on Linux)
    boot-cleanup.enable = lib.mkEnableOption "Enable automatic boot entry cleanup";
    autoupgrade.enable = lib.mkEnableOption "Enable autoupgrade";
    optimization.enable = lib.mkEnableOption "Enable Nix store optimization";
  };

  config = lib.mkMerge (
    [
      # When maintenance.enable is set, auto-enable sub-modules
      (lib.mkIf cfg.maintenance.enable (
        {
          gc.enable = lib.mkDefault true;
        }
        // lib.optionalAttrs isLinux {
          boot-cleanup.enable = lib.mkDefault true;
          optimization.enable = lib.mkDefault true;
          # autoupgrade is NOT enabled by default - opt-in only
        }
      ))

      # Cross-platform: Garbage collection
      (lib.mkIf cfg.gc.enable {
        nix.gc = {
          automatic = true;
          options = "--delete-older-than 30d";
        }
        // (lib.optionalAttrs isLinux {
          # NixOS-specific options
          dates = "weekly";
          randomizedDelaySec = "30min";
          persistent = true;
        })
        // (lib.optionalAttrs (!isLinux) {
          # nix-darwin-specific options
          interval = {
            Weekday = 0;
            Hour = 3;
            Minute = 15;
          }; # Weekly on Sunday at 3:15 AM
        });
      })
    ]
    ++ lib.optionals isLinux [
      # Linux-only: Boot cleanup
      (lib.mkIf cfg.boot-cleanup.enable {
        # Limit the number of boot generations to prevent /boot from filling up
        boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
        boot.loader.grub.configurationLimit = lib.mkDefault 5;
        nix.gc.automatic = lib.mkDefault true;
      })

      # Linux-only: Auto-upgrade
      (lib.mkIf cfg.autoupgrade.enable {
        system.autoUpgrade = {
          enable = true;
          dates = "02:00";
          randomizedDelaySec = "45min";
          flake = inputs.self.outPath;
          flags = [
            "--update-input"
            "nixpkgs"
            "--commit-lock-file"
            "-L"
          ];
        };
      })

      # Linux-only: Store optimization
      (lib.mkIf cfg.optimization.enable {
        nix.optimise = {
          automatic = true;
          dates = [ "weekly" ];
          randomizedDelaySec = "45min";
          persistent = true;
        };
      })
    ]
  );
}
