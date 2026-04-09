{
  config,
  pkgs,
  lib,
  ...
}:

let
  dataDir = "/var/lib/lute";
  user = "lute";
  group = "lute";
  port = 5001;
in
{
  options.lute.enable = lib.mkEnableOption "Enables Lute v3 language learning service";

  config = lib.mkIf config.lute.enable {

    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = dataDir;
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 ${user} ${group}"
    ];

    networking.firewall.allowedTCPPorts = [ port ];

    systemd.services.lute = {
      description = "Lute v3 Language Learning";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOME = dataDir;
      };

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = dataDir;
        ExecStart = "${pkgs.lute-v3}/bin/lute";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
      };
    };
  };
}
