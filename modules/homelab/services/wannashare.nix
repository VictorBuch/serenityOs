{
  config,
  pkgs,
  lib,
  ...
}:

let
  dataDir = "/var/lib/wannashare";
  user = "wannashare";
  group = "wannashare";
  port = 8090;
in
{
  options.wannashare.enable = lib.mkEnableOption "Enables WannaShare PocketBase backend";

  config = lib.mkIf config.wannashare.enable {

    environment.systemPackages = with pkgs; [
      go
    ];

    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = dataDir;
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 ${user} ${group}"
      "d ${dataDir}/pb_data 0750 ${user} ${group}"
    ];

    systemd.services.wannashare = {
      description = "WannaShare PocketBase Backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = dataDir;
        ExecStart = "${dataDir}/wannashare serve --http=127.0.0.1:${toString port}";
        Restart = "always";
        RestartSec = "5s";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
      };
    };
  };
}
