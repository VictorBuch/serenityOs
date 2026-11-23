{
  flake.modules.nixos.homelab =
    {
      config,
      pkgs,
      ...
    }:
    let
      port = config.homelab.records.figcraft.port;
      settings = (pkgs.formats.toml { }).generate "figcraft-server.toml" {
        listen = "0.0.0.0:${toString port}";
        data = "/var/lib/figcraft-server";
        public_url = "ws://${config.homelab.nixosIp}:${toString port}/";
      };

      # Outside access: swap the record and settings above for these, then rebuild.
      # Link tokens are the only auth and the app speaks raw WebSocket, so it must be
      # "public"; Pangolin's SSO screen would block it.
      #
      # homelab.records.figcraft = {
      #   port = 47900;
      #   exposure = "public";
      # };
      #
      # settings = (pkgs.formats.toml { }).generate "figcraft-server.toml" {
      #   listen = "127.0.0.1:${toString port}";
      #   data = "/var/lib/figcraft-server";
      #   public_url = "wss://${config.homelab.records.figcraft.subdomain}.${config.homelab.domain}/";
      #   trusted_proxy = "127.0.0.1";
      # };
    in
    {
      homelab.records.figcraft = {
        port = 47900;
        exposure = "lan";
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
