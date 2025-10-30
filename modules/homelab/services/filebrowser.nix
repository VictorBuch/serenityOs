args@{ config, pkgs, lib, mkApp, ... }:

let
  user = config.user;
  nixosIp = config.homelab.nixosIp;

  # Define custom options that mkApp doesn't handle
  filebrowserOptions = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "filebrowser";
      description = "The system user to run the filebrowser service as.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 3030;
      description = "Port on which filebrowser listens.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address on which filebrowser should bind. Defaults to localhost for reverse proxy usage.";
    };
  };
in

mkApp {
  _file = toString ./.;
  name = "filebrowser";
  description = "Filebrowser web file manager";
  packages = pkgs: [];  # No packages for services

  extraConfig = { config, lib, ... }:
    let
      # Get the filebrowser config from the auto-generated option path
      cfg = lib.attrByPath (lib.splitString "." "apps.homelab.services.filebrowser") {} config;
    in
    {
      # Add custom options to the filebrowser namespace
      options = lib.setAttrByPath
        (lib.splitString "." "apps.homelab.services.filebrowser")
        filebrowserOptions;

      config = lib.mkIf cfg.enable {
        users.users = {
          "${cfg.user}" = {
            isSystemUser = true;
            description = "User for filebrowser service";
            createHome = false;
            group = "filebrowser";
          };
        };
        users.groups.filebrowser = { };

        systemd.tmpfiles.rules = [
          "d /var/lib/filebrowser 0770 ${cfg.user} filebrowser"
        ];

        systemd.services.filebrowser = {
          description = "filebrowser filebrowser service";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Restart = "on-failure";
            ExecStart = pkgs.writeShellScript "filebrowser" ''
              ${pkgs.filebrowser}/bin/filebrowser \
                --address ${cfg.address} \
                --port ${toString cfg.port} \
                --database /var/lib/filebrowser/filebrowser.db \
                --root /mnt/data
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [
          cfg.port
        ];
      };
    };
} args
