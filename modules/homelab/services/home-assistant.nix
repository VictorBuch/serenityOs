{
  lib,
  config,
  pkgs,
  expiring,
  ...
}:

with lib;

let
  cfg = config.homelab.home-assistant;
  domain = config.homelab.domain;
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
      'until ${pkgs.curl}/bin/curl -sf -o /dev/null http://127.0.0.1:8124/manifest.json; do ${pkgs.coreutils}/bin/sleep 2; done' || true
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
      package =
        expiring.onBump pkgs.home-assistant "2026.8.3"
          "retest home-assistant's install check before keeping it disabled"
          (pkgs.home-assistant.overrideAttrs (oldAttrs: {
            doInstallCheck = false;
          }));

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
      ];

      customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
          mushroom
          mini-graph-card   #  graphs like the reference image
          card-mod          #  rounded-corner / theme tweaks
	  bubble-card
       ];

      config = {
        # Basic setup with default integrations
        default_config = { };

        # HTTP configuration for Nabu Casa remote access
        http = {
          server_port = 8124;
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

        # UI-managed automations, scenes, and scripts
        "automation ui" = "!include automations.yaml";
        "scene ui" = "!include scenes.yaml";
        "script ui" = "!include scripts.yaml";

        # ZHA Zigbee configuration
        # Configure via UI: Settings → Devices → Add Integration → ZHA
        # Select: /dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_78df85e24191ed11bfe1bfd13b20a988-if00-port0
      };
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      8124 # Home Assistant web interface
    ];
  };
}
