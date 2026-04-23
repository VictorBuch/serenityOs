{
  config,
  pkgs,
  lib,
  ...
}:

let
  dataDir = "/var/lib/wannashare";
  siteDir = "${dataDir}/site";
  user = "wannashare";
  group = "wannashare";
  backendPort = 8099;
  sitePort = 3005;
  nodejs = pkgs.nodejs_22;
in
{
  options.homelab.wannashare.enable = lib.mkEnableOption "Enables WannaShare PocketBase backend + Nuxt SSR site";

  config = lib.mkIf config.homelab.wannashare.enable {

    environment.systemPackages = with pkgs; [
      go
      nodejs
    ];

    users.users.wanna-share-releaser = {
      isNormalUser = true;
      group = "wanna-share-releaser";
      description = "WannaShare Deployment User";
      shell = pkgs.bashInteractive;
      extraGroups = [ "wannashare" "docker" ];
    };
    users.groups.wanna-share-releaser = { };

    security.sudo.extraRules = [
      {
        users = [ "wanna-share-releaser" ];
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
            command = "/run/current-system/sw/bin/install -m 640 -o wannashare -g wannashare /tmp/firebase-credentials.json /var/lib/wannashare/firebase-credentials.json";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm -f /tmp/firebase-credentials.json";
            options = [ "NOPASSWD" ];
          }
        ];
      }
      # Backend deploy (split into its own rule — sudoers has a per-line length limit)
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
        ];
      }
      # Site (Nuxt SSR) deploy
      {
        users = [ "gitea-runner" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare-site";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare-site";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/rm -rf /var/lib/wannashare/site";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mv /tmp/wannashare-site-new /var/lib/wannashare/site";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/chown -R wannashare:wannashare /var/lib/wannashare/site";
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
      "d ${siteDir} 0770 ${user} ${group}"
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
        ExecStart = "${dataDir}/wannashare-backend serve --http=127.0.0.1:${toString backendPort}";

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ dataDir ];
      };
    };

    systemd.services.wannashare-site = {
      description = "WannaShare Nuxt SSR Site";
      after = [ "network.target" "wannashare.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NODE_ENV = "production";
        HOST = "127.0.0.1";
        PORT = toString sitePort;
        NUXT_PUBLIC_API_BASE = "https://db-wannashare.smoothless.org";
      };

      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = siteDir;
        ExecStart = "${nodejs}/bin/node ${siteDir}/server/index.mjs";
        Restart = "on-failure";
        RestartSec = 5;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ dataDir ];
      };

      unitConfig = {
        # Bundle may be missing on first boot before CI runs. Don't spam logs.
        ConditionPathExists = "${siteDir}/server/index.mjs";
      };
    };
  };
}
