{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.home-assistant;
  domain = config.homelab.domain;
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

    # Create empty yaml files for UI-managed configs if they don't exist
    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
      "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
      "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
      # Make the state dir group-traversable + writable for the hass group...
      "z ${config.services.home-assistant.configDir} 0770 hass hass - -"
      # ...and grant serenity a recursive rw ACL so even files HA wrote with a
      # restrictive mode (e.g. .storage/*) stay accessible. Re-applied on every
      # rebuild/boot; the default (d:) entry covers newly-created files.
      "A+ ${config.services.home-assistant.configDir} - - - - u:serenity:rwX,d:u:serenity:rwX"
    ];

    services.home-assistant = {
      enable = true;
      package = pkgs.home-assistant.overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });

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
	"nextcloud"
	"ntfy"
	"paperless_ngx"
	"overseerr"
	"wled"
	"roborock"
	"homekit"
	"homekit_controller"
      ];

      customComponents = [
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
