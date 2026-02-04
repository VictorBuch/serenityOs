{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.filebrowser;
  user = config.user;
  nixosIp = config.homelab.nixosIp;
in
{

  options.filebrowser = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the filebrowser service.";
    };

    user = mkOption {
      type = types.str;
      default = "filebrowser";
      description = "The system user to run the filebrowser service as.";
    };

    port = mkOption {
      type = types.int;
      default = 3030;
      description = "Port on which filebrowser listens.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address on which filebrowser should bind. Defaults to localhost for reverse proxy usage.";
    };
  };

  config = lib.mkIf config.filebrowser.enable {

    users.users = {
      "${cfg.user}" = {
        isSystemUser = true;
        description = "User for filebrowser service";
        createHome = false;
        group = "filebrowser";
        extraGroups = [ "resolvconf" "users" ];
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
            --root /mnt/pool
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [
      config.filebrowser.port
    ];
  };
}
