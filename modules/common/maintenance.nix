let
  module =
    isLinux:
    {
      config,
      lib,
      ...
    }:
    {
      options = lib.optionalAttrs isLinux {
        autoupgrade.enable = lib.mkEnableOption "Enable autoupgrade";
      };

      config = lib.mkMerge (
        [
          {
            nix.gc = {
              automatic = true;
              options = "--delete-older-than 30d";
            }
            // (lib.optionalAttrs isLinux {
              dates = "weekly";
              randomizedDelaySec = "30min";
              persistent = true;
            })
            // (lib.optionalAttrs (!isLinux) {
              interval = {
                Weekday = 0;
                Hour = 3;
                Minute = 15;
              };
            });
          }
        ]
        ++ lib.optionals isLinux [
          {
            # Limit the number of boot generations to prevent /boot from filling up
            boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
            boot.loader.grub.configurationLimit = lib.mkDefault 5;
            nix.gc.automatic = lib.mkDefault true;

            nix.optimise = {
              automatic = true;
              dates = [ "weekly" ];
              randomizedDelaySec = "45min";
              persistent = true;
            };
          }

          # Builds whatever is pushed to GitHub main, lock file included. Hosts
          # never bump inputs on their own: on 2026-08-27 a per-host nixpkgs bump
          # shipped gerbil 1.5.0 to one end of the pangolin tunnel while the other
          # still ran the older newt, and the public edge went down.
          (lib.mkIf config.autoupgrade.enable {
            system.autoUpgrade = {
              enable = true;
              dates = "Sun *-*-* 02:00:00";
              randomizedDelaySec = "45min";
              flake = "github:VictorBuch/serenityOs";
              flags = [ "-L" ];
            };
          })
        ]
      );
    };
in
{
  flake.modules.nixos.base = module true;
  flake.modules.darwin.base = module false;
}
