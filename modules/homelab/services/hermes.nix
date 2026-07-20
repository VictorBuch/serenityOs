{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.homelab.hermes;
  signalPort = cfg.signal.port;
  signalConfigDir = "/var/lib/signal-cli";
in
{
  options.homelab.hermes = {
    enable = lib.mkEnableOption "Hermes Agent gateway (NousResearch/hermes-agent)";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        hermes-agent package to run. null keeps the upstream module's default
        (inputs.hermes-agent.packages.''${system}.default).
      '';
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "anthropic/claude-haiku-4-5";
      description = ''
        Model string written to config.yaml as `model.default`.
        Provider-prefixed form; `model.provider` is pinned to "anthropic".
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/some-env";
      description = ''
        Path to a KEY=VALUE file holding secrets (ANTHROPIC_API_KEY).
        Contents are appended to $HERMES_HOME/.env by the activation script
        and read by hermes at startup — see notes in this file about why this
        is not a systemd EnvironmentFile.

        Leave null to use the sops template built from the
        `hermes/anthropic_api_key` secret in secrets/secrets.yaml.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        HERMES_LOG_LEVEL = "info";
      };
      description = "Non-secret environment variables merged into $HERMES_HOME/.env.";
    };

    signal = {
      enable = lib.mkEnableOption "signal-cli JSON-RPC daemon for the Signal platform" // {
        default = true;
      };

      account = lib.mkOption {
        type = lib.types.str;
        example = "+4512345678";
        description = "Signal account (E.164 phone number) the linked device belongs to.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Loopback port for the signal-cli HTTP/JSON-RPC daemon.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ANTHROPIC_API_KEY. Stored as a bare key in secrets.yaml and rendered into
    # a KEY=VALUE env file by sops-nix; the hermes activation script appends it
    # to $HERMES_HOME/.env. Only used when environmentFile is left at null.
    sops.secrets."hermes/anthropic_api_key" = lib.mkIf (cfg.environmentFile == null) {
      restartUnits = [ "hermes-agent.service" ];
    };

    sops.templates."hermes-env" = lib.mkIf (cfg.environmentFile == null) {
      content = ''
        ANTHROPIC_API_KEY=${config.sops.placeholder."hermes/anthropic_api_key"}
      '';
      restartUnits = [ "hermes-agent.service" ];
    };

    assertions = [
      {
        assertion = !cfg.signal.enable || cfg.signal.account != "";
        message = "homelab.hermes.signal.account must be set when signal.enable = true";
      }
    ];

    services.hermes-agent = {
      enable = true;
      package = lib.mkIf (cfg.package != null) cfg.package;

      # user/group "hermes", stateDir /var/lib/hermes are upstream defaults.
      # Upstream tmpfiles-creates .hermes/{cron,sessions,logs,memories,plugins}
      # under stateDir and keeps them across rebuilds/reboots.
      stateDir = "/var/lib/hermes";

      settings = {
        model = {
          default = cfg.model;
          provider = "anthropic";
        };
      };

      environmentFiles = [
        (if cfg.environmentFile != null then cfg.environmentFile else config.sops.templates."hermes-env".path)
      ];

      environment = lib.optionalAttrs cfg.signal.enable {
        SIGNAL_HTTP_URL = "http://127.0.0.1:${toString signalPort}";
        SIGNAL_ACCOUNT = cfg.signal.account;
      }
      // cfg.extraEnvironment;

      # Tools the agent shells out to for the health-check jobs.
      extraPackages = with pkgs; [
        curl
        jq
        systemd
      ];
    };

    # Extra hardening on top of upstream's (NoNewPrivileges, ProtectSystem=strict,
    # PrivateTmp, ReadWritePaths=[stateDir workingDirectory]).
    # Deliberately NOT set: MemoryDenyWriteExecute (breaks node/python JIT the
    # agent spawns) and a strict SystemCallFilter (the agent runs arbitrary
    # terminal commands).
    systemd.services.hermes-agent = {
      after = lib.optional cfg.signal.enable "signal-cli.service";
      wants = lib.optional cfg.signal.enable "signal-cli.service";
      serviceConfig = {
        StateDirectory = "hermes";
        StateDirectoryMode = "2770";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        RemoveIPC = true;
        # Network access must stay open — Anthropic API + signal-cli loopback.
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        IPAddressDeny = lib.mkDefault [ ];
      };
    };

    # signal-cli daemon. Not packaged as a NixOS module in nixpkgs, so declared here.
    # Runs as the hermes user so `hermes` and `signal-cli` share the link data.
    systemd.services.signal-cli = lib.mkIf cfg.signal.enable {
      description = "signal-cli JSON-RPC daemon (Hermes Signal gateway)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        User = config.services.hermes-agent.user;
        Group = config.services.hermes-agent.group;
        StateDirectory = "signal-cli";
        StateDirectoryMode = "0700";
        WorkingDirectory = signalConfigDir;
        Environment = [ "HOME=${signalConfigDir}" ];

        ExecStart = lib.concatStringsSep " " [
          "${pkgs.signal-cli}/bin/signal-cli"
          "--config ${signalConfigDir}"
          "-a ${cfg.signal.account}"
          "daemon"
          "--http 127.0.0.1:${toString signalPort}"
        ];

        Restart = "always";
        RestartSec = 5;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ signalConfigDir ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };
  };
}
