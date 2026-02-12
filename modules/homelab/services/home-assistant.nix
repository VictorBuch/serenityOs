{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.home-assistant;
  domain = config.homelab.domain;
in
{
  options.home-assistant = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the Home Assistant service.";
    };
  };

  config = mkIf cfg.enable {

    # Ensure hass user can access USB serial devices (for Zigbee dongle)
    users.users.hass.extraGroups = [ "dialout" ];

    # Create empty yaml files for UI-managed configs if they don't exist
    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
      "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
      "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
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
        "esphome"
        "cast" # Chromecast
        "spotify"
        "tuya"
        "mobile_app" # For HA companion app
      ];

      customComponents = [
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
