args@{ config, pkgs, lib, mkApp, ... }:

let
  # Define custom options that mkApp doesn't handle
  hyperhdrOptions = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "hyperhdr";
      description = "The system user to run the HyperHDR service as.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hyperhdr";
      description = "Directory to store HyperHDR data and configuration.";
    };
  };
in

mkApp {
  _file = toString ./.;
  name = "hyperhdr";
  description = "HyperHDR ambient lighting service";
  packages = pkgs: [ pkgs.hyperhdr ];

  extraConfig = { config, lib, ... }:
    let
      # Get the hyperhdr config from the auto-generated option path
      cfg = lib.attrByPath (lib.splitString "." "apps.homelab.services.hyperhdr") {} config;
    in
    {
      # Add custom options to the hyperhdr namespace
      options = lib.setAttrByPath
        (lib.splitString "." "apps.homelab.services.hyperhdr")
        hyperhdrOptions;

      config = lib.mkIf cfg.enable {
        # Create system user and group for HyperHDR
        users.users = {
          "${cfg.user}" = {
            isSystemUser = true;
            description = "HyperHDR ambient lighting service user";
            createHome = false;
            group = "hyperhdr";
            home = cfg.dataDir;
          };
        };
        users.groups.hyperhdr = { };

        # Create data directory with proper permissions
        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0770 ${cfg.user} hyperhdr"
        ];

        # HyperHDR systemd service
        systemd.services.hyperhdr = {
          description = "HyperHDR ambient lighting service";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = "hyperhdr";
            Restart = "on-failure";
            RestartSec = 5;

            # Set the userdata directory and run in service mode
            ExecStart = "${pkgs.hyperhdr}/bin/hyperhdr --service --userdata ${cfg.dataDir}";

            # Security settings
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ cfg.dataDir ];

            # Allow access to hardware for LED control
            DeviceAllow = [
              "/dev/mem rw"
              "/dev/gpiomem rw"
            ];
            SupplementaryGroups = [ "video" ];
          };
        };

        # Open firewall ports
        networking.firewall.allowedTCPPorts = [
          8090 # Web interface
          19444 # JSON API for Home Assistant integration
          19445
        ];
      };
    };
} args
