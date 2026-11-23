{
  flake.modules.nixos.homelab =
    {
      config,
      pkgs,
      ...
    }:
    let
      record = config.homelab.records.figcraft;
      settings = (pkgs.formats.toml { }).generate "figcraft-server.toml" {
        listen = "127.0.0.1:${toString record.port}";
        data = "/var/lib/figcraft-server";
        public_url = "wss://${record.subdomain}.${record.domain}/";
        trusted_proxy = "127.0.0.1";
      };
    in
    {
      homelab.records.figcraft = {
        port = 47900;
        exposure = "public";
      };

      systemd.services.figcraft-server = {
        description = "FigCraft collaboration server";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.figcraft-server}/bin/figcraft-server --config ${settings}";
          DynamicUser = true;
          StateDirectory = "figcraft-server";
          KillSignal = "SIGTERM";
          TimeoutStopSec = 30;
          Restart = "on-failure";
          RestartSec = 2;
          LimitNOFILE = 4096;
          UMask = "0077";
          MemoryHigh = "60%";
          MemoryMax = "75%";
          IPAddressAllow = "localhost";
          IPAddressDeny = "any";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          CapabilityBoundingSet = "";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = "@system-service";
          SystemCallErrorNumber = "EPERM";
        };
      };
    };
}
