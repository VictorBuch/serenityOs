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

    # All CI deploys run as `wanna-share-releaser` (see gitea.nix — the
    # gitea-runner-nix/docker services force that as User=). That user is in
    # the `wannashare` group, so file operations on /var/lib/wannashare need
    # no sudo — only systemctl and privileged file installs do.
    security.sudo.extraRules = [
      {
        users = [ "wanna-share-releaser" ];
        commands = [
          # Backend service
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare";
            options = [ "NOPASSWD" ];
          }
          # Site service
          {
            command = "/run/current-system/sw/bin/systemctl stop wannashare-site";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl start wannashare-site";
            options = [ "NOPASSWD" ];
          }
          # Firebase credentials install (root-only destination)
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
        # `+` prefix runs as root so we can reclaim ownership after CI's sudo mv
        # leaves the dir owned by gitea-runner.
        ExecStartPre = "+${pkgs.coreutils}/bin/chown -R ${user}:${group} ${siteDir}";
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
