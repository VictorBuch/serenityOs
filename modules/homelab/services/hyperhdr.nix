{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hyperhdr;
in
{

  options.hyperhdr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the HyperHDR ambient lighting service.";
    };

    user = mkOption {
      type = types.str;
      default = "hyperhdr";
      description = "The system user to run the HyperHDR service as.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/hyperhdr";
      description = "Directory to store HyperHDR data and configuration.";
    };
  };

  config = mkIf cfg.enable {

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
        ExecStart = "${pkgs.unstable.hyperhdr}/bin/hyperhdr --service --userdata ${cfg.dataDir}";

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

    # Install HyperHDR package
    environment.systemPackages = with pkgs.unstable; [
      hyperhdr
    ];

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      8090 # Web interface
      19444 # JSON API for Home Assistant integration
      19445
    ];
  };
}
