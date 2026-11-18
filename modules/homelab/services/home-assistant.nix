{
  flake.modules.nixos.homelab =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    with lib;

    let
      cfg = config.homelab.home-assistant;
      haConfigDir = config.services.home-assistant.configDir;

      # Idempotent repair of serenity's ACL on the HA state dir. Something (still
      # unidentified — not found in HA core or its python deps) chmods the dir
      # back to 0700, which zeroes the ACL mask and nullifies serenity's entry.
      # Cheap no-op while the mask is intact, so it's safe to run frequently.
      aclRepair = pkgs.writeShellScript "hass-acl-repair" ''
        if ${pkgs.acl}/bin/getfacl --omit-header --absolute-names ${haConfigDir} 2>/dev/null \
            | ${pkgs.gnugrep}/bin/grep -qx 'mask::rwx'; then
          exit 0
        fi
        # -R can fail on stray root-owned entries; never fatal.
        ${pkgs.acl}/bin/setfacl -R -m u:serenity:rwX -m d:u:serenity:rwX -m m::rwx ${haConfigDir} || true
      '';

      # ExecStartPost fires the moment systemd considers HA "started", which races
      # HA's own init (the likely re-locker). Wait until HA actually serves HTTP
      # before repairing, so a startup-time chmod has already happened.
      aclStartPost = pkgs.writeShellScript "hass-acl-startpost" ''
        ${pkgs.coreutils}/bin/timeout 120 ${pkgs.bash}/bin/bash -c \
          'until ${pkgs.curl}/bin/curl -sf -o /dev/null ${config.homelab.records.home-assistant.upstream}/manifest.json; do ${pkgs.coreutils}/bin/sleep 2; done' || true
        exec ${aclRepair}
      '';
    in
    {
      options.homelab.home-assistant = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the Home Assistant service.";
        };
      };

      config = mkIf cfg.enable {

        # Ensure hass user can access USB serial devices (for Zigbee dongle)
        users.users.hass.extraGroups = [ "dialout" ];

        # --- Admin access to HA's state dir for the `serenity` user ---
        # serenity is already effectively root on mal (docker + wheel groups), so
        # this grants no new privilege; it just makes /var/lib/hass convenient to
        # read and edit directly (config files, tooling) instead of via sudo.
        users.users.serenity.extraGroups = [ "hass" ];

        # HA defaults to UMask 0077 (new files 0600). Relax so hass-group members
        # can reach files HA creates from now on.
        systemd.services.home-assistant.serviceConfig.UMask = mkForce "0007";

        # Re-grant serenity's ACL after HA has fully started (see aclStartPost —
        # a plain ExecStartPost setfacl loses the race against whatever re-locks
        # the dir to 0700 during startup). Runs as the `hass` user, which owns the
        # dir, so setfacl is allowed. The `-` prefix means a failure here never
        # blocks HA from starting.
        systemd.services.home-assistant.serviceConfig.ExecStartPost = [
          "-${aclStartPost}"
        ];

        # Safety net: the re-locker is unidentified and has struck at runtime
        # without an HA restart, so reassert the ACL mask every few minutes.
        # aclRepair exits early when the mask is intact, so this is ~free.
        systemd.services.hass-acl-watchdog = {
          description = "Repair serenity ACL mask on Home Assistant config dir";
          unitConfig.ConditionPathIsDirectory = haConfigDir;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${aclRepair}";
          };
        };
        systemd.timers.hass-acl-watchdog = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "5min";
          };
        };

        # Create empty yaml files for UI-managed configs if they don't exist
        systemd.tmpfiles.rules = [
          "f ${haConfigDir}/automations.yaml 0644 hass hass"
          "f ${haConfigDir}/scenes.yaml 0644 hass hass"
          "f ${haConfigDir}/scripts.yaml 0644 hass hass"
          # Make the state dir group-traversable + writable for the hass group...
          "z ${haConfigDir} 0770 hass hass - -"
          # ...and grant serenity a recursive rw ACL so even files HA wrote with a
          # restrictive mode (e.g. .storage/*) stay accessible. Re-applied on every
          # rebuild/boot; the default (d:) entry covers newly-created files, and
          # the explicit m: entry restores the mask a chmod 0700 zeroes out.
          "A+ ${haConfigDir} - - - - u:serenity:rwX,m::rwx,d:u:serenity:rwX,d:m::rwx"
        ];

        services.home-assistant = {
          enable = true;
          # Components to enable
          extraComponents = [
            # Required for onboarding
            "analytics"
            "google_translate"
            "met"
            "radio_browser"
            "shopping_list"
            # Recommended for performance
            "isal"
            # Your requested integrations
            "zha" # Zigbee Home Automation
            "hue" # Philips Hue
            # Useful extras
            "adguard"
            "esphome"
            "cast" # Chromecast
            "spotify"
            "tuya"
            "mobile_app" # For HA companion app
            "onvif"
            "denon"
            "mcp"
            "mcp_server"
            "mealie"
            "sonarr"
            "radarr"
            "qbittorrent"
            "jellyfin"
            "music_assistant"
            "hyperion"
            "immich"
            "ntfy"
            "paperless_ngx"
            "overseerr"
            "wled"
            "roborock"
            "homekit"
            "homekit_controller"
            "androidtv_remote"
          ];

          customComponents = with pkgs.home-assistant-custom-components; [
            adaptive_lighting
            uix
          ];

          customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
            mushroom
            mini-graph-card # graphs like the reference image
            bubble-card
            # used by the "Glow" and "Control Room" dashboards (card_mod styling comes from uix)
            button-card
            layout-card
            auto-entities
            apexcharts-card
            mini-media-player
            vacuum-card
            clock-weather-card
            navbar-card
            kiosk-mode # Glow hides the HA header (escape hatch: ?disable_km)
          ];

          config = {
            # Basic setup with default integrations
            default_config = { };

            # HTTP configuration for Nabu Casa remote access
            http = {
              server_port = config.homelab.records.home-assistant.port;
              use_x_forwarded_for = true;
              trusted_proxies = [
                "127.0.0.1"
                "::1"
              ];
            };

            # Homeassistant core config
            homeassistant = {
              name = "Home";
              unit_system = "metric";
              time_zone = "Europe/Prague";
              latitude = 50.022414337137704;
              longitude = 14.402442466652143;
            };

            recorder = {
              purge_keep_days = 10;
              exclude.entities = [
                "sensor.server_smart_plug_server_current"
                "sensor.server_smart_plug_server_voltage"
                "sensor.smart_plug_terra_current"
                "sensor.smart_plug_terra_voltage"
                "switch.server_adaptive_lighting_smart_lamps_adaptive_lighting_smart_lamps"
              ];
            };

            # Themes used per-view by the YAML dashboards below.
            frontend.themes = {
              glow = {
                # warm night: charcoal glass, amber accent; light colours carry the rest
                primary-color = "#f5a524";
                accent-color = "#f5a524";
                primary-background-color = "#121014";
                secondary-background-color = "#1b181f";
                lovelace-background = "radial-gradient(1200px 600px at 10% -10%, #3a2a1a 0%, transparent 60%), radial-gradient(900px 600px at 110% 10%, #1d2340 0%, transparent 55%), #121014";
                card-background-color = "rgba(30, 27, 34, 0.72)";
                ha-card-background = "rgba(30, 27, 34, 0.72)";
                ha-card-border-radius = "24px";
                ha-card-border-width = "0px";
                ha-card-box-shadow = "0 8px 30px rgba(0,0,0,0.35)";
                primary-text-color = "#f4efe9";
                secondary-text-color = "#a39b93";
                disabled-text-color = "#5f5a55";
                divider-color = "rgba(255,255,255,0.06)";
                state-icon-color = "#a39b93";
                app-header-background-color = "transparent";
                app-header-text-color = "#f4efe9";
                bubble-main-background-color = "rgba(44, 40, 50, 0.85)";
                bubble-secondary-background-color = "rgba(60, 55, 68, 0.9)";
                bubble-pop-up-background-color = "rgba(22, 20, 26, 0.92)";
                bubble-accent-color = "#f5a524";
                bubble-border-radius = "22px";
                bubble-button-border-radius = "18px";
                bubble-icon-background-color = "rgba(255,255,255,0.06)";
                mush-chip-background = "rgba(44, 40, 50, 0.85)";
                mush-chip-border-width = "0px";
              };
              control-room = {
                # blueprint: deep navy, cyan grid lines, neon state colours
                primary-color = "#38d6ff";
                accent-color = "#38d6ff";
                primary-background-color = "#070d1a";
                secondary-background-color = "#0d1729";
                lovelace-background = "linear-gradient(rgba(56,214,255,0.045) 1px, transparent 1px) 0 0 / 32px 32px, linear-gradient(90deg, rgba(56,214,255,0.045) 1px, transparent 1px) 0 0 / 32px 32px, radial-gradient(1400px 800px at 50% -20%, #12305a 0%, #070d1a 65%)";
                card-background-color = "rgba(12, 22, 40, 0.82)";
                ha-card-background = "rgba(12, 22, 40, 0.82)";
                ha-card-border-radius = "14px";
                ha-card-border-width = "1px";
                ha-card-border-color = "rgba(56, 214, 255, 0.14)";
                ha-card-box-shadow = "none";
                primary-text-color = "#e3f2ff";
                secondary-text-color = "#7f98b8";
                disabled-text-color = "#3d5170";
                divider-color = "rgba(56,214,255,0.10)";
                state-icon-color = "#7f98b8";
                app-header-background-color = "#070d1a";
                app-header-text-color = "#e3f2ff";
              };
            };

            # YAML dashboards; the files live in /var/lib/hass/dashboards/ and are
            # edited in place (refresh the browser to pick up changes, no restart).
            lovelace.dashboards = {
              dashboard-glow = {
                mode = "yaml";
                filename = "dashboards/glow.yaml";
                title = "Glow";
                icon = "mdi:lightbulb-night";
                show_in_sidebar = true;
              };
              dashboard-control = {
                mode = "yaml";
                filename = "dashboards/control-room.yaml";
                title = "Control Room";
                icon = "mdi:floor-plan";
                show_in_sidebar = true;
              };
            };

            # UI-managed automations, scenes, and scripts
            "automation ui" = "!include automations.yaml";
            "scene ui" = "!include scenes.yaml";
            "script ui" = "!include scripts.yaml";

            # ZHA Zigbee configuration
            # Configure via UI: Settings → Devices → Add Integration → ZHA
            # Select: /dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_78df85e24191ed11bfe1bfd13b20a988-if00-port0
          };
        };

        # Own auth; the companion app and API need direct access.
        # 8123 belongs to crafty.
        homelab.records.home-assistant = {
          subdomain = "home";
          port = 8124;
          exposure = "public";
          openFirewall = true;
          tile = {
            title = "Home Assistant";
            icon = "sh:home-assistant";
            group = "infrastructure";
          };
        };
      };
    };
}
