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
  port = 8099;
in
{
  options.wannashare.enable = lib.mkEnableOption "Enables WannaShare PocketBase backend";

  config = lib.mkIf config.wannashare.enable {

    environment.systemPackages = with pkgs; [
      go
    ];

    users.users.wanna-share-releaser = {
      isNormalUser = true;
      group = "wanna-share-releaser";
      description = "WannaShare Deployment User";
      shell = pkgs.bashInteractive;
      extraGroups = [ "wannashare" ];
    };
    users.groups.wanna-share-releaser = { };

    security.sudo.extraRules = [
      {
        users = [ "wanna-share-releaser" ];
        commands = [
          # systemctl start stop wannashare - NOPASSWD
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare";
            options = [ "NOPASSWD" ];
          }
        ];

      }
      {
        users = [ "gitea-runner" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mv /tmp/wannashare-new /var/lib/wannashare/wannashare-backend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/chmod +x /var/lib/wannashare/wannashare-backend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm -rf /var/lib/wannashare/web";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mv /tmp/wannashare-web-new /var/lib/wannashare/web";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = dataDir;
    };

    users.users.caddy.extraGroups = [ "wannashare" ];

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0770 ${user} ${group}"
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
        ExecStart = "${dataDir}/wannashare-backend serve --http=127.0.0.1:${toString port}";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
      };
    };
  };
}
