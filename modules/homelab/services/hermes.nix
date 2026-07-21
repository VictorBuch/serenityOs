{
  lib,
  config,
  pkgs,
  inputs,
  system,
  ...
}:

let
  cfg = config.homelab.hermes;
  signalPort = cfg.signal.port;
  signalConfigDir = "/var/lib/signal-cli";

  # KEY=VALUE env file holding ANTHROPIC_API_KEY (+ SIGNAL_* when enabled).
  # Either the user-provided file or the sops-rendered template. Shared by the
  # gateway and the dashboard unit.
  hermesEnvFile =
    if cfg.environmentFile != null then cfg.environmentFile else config.sops.templates."hermes-env".path;
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

      # The account (E.164 phone number) is NOT a Nix option — it is read at
      # runtime from the sops secret `hermes/signal_phone` so the real number
      # never lands in the world-readable Nix store. Both signal-cli (daemon
      # `-a`) and hermes-agent (SIGNAL_ACCOUNT) consume it from there.

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Loopback port for the signal-cli HTTP/JSON-RPC daemon.";
      };
    };

    discord = {
      enable = lib.mkEnableOption ''
        the Discord platform. Enabled by the bot token in the sops secret
        `hermes/discord_bot_token`; the DM allowlist (comma-separated Discord
        user IDs) comes from `hermes/discord_allowed_users`. The bot connects
        outbound over Discord's gateway — no daemon, webhook or linking needed
      '';
    };

    web = {
      enable = lib.mkEnableOption ''
        the Hermes web dashboard (browser chat UI). Runs `hermes dashboard`
        as a separate systemd unit bound to loopback, so its own auth gate
        stays off — front it with a reverse proxy that provides auth
        (e.g. Caddy + pocket-id). Shares the gateway's config/state
      '';

      port = lib.mkOption {
        type = lib.types.port;
        default = 9119;
        description = "Loopback port for the dashboard HTTP/WebSocket server.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.hermes-agent.packages.${system}.web;
        defaultText = lib.literalExpression "inputs.hermes-agent.packages.\${system}.web";
        description = ''
          Pre-built hermes-web SPA (static dist), served via HERMES_WEB_DIST.
          Must match the hermes-agent input the gateway runs.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ANTHROPIC_API_KEY. Stored as a bare key in secrets.yaml and rendered into
    # a KEY=VALUE env file by sops-nix; the hermes activation script appends it
    # to $HERMES_HOME/.env. Only used when environmentFile is left at null.
    sops.secrets."hermes/anthropic_api_key" = lib.mkIf (cfg.environmentFile == null) {
      restartUnits = [
        "hermes-agent.service"
      ]
      ++ lib.optional cfg.web.enable "hermes-dashboard.service";
    };

    # Signal phone number (E.164). Read at runtime by signal-cli's daemon
    # (`-a`) and by hermes-agent (SIGNAL_ACCOUNT via the env file below).
    # Owned by the hermes user so signal-cli, which runs as that user, can
    # `cat` it from /run/secrets.
    sops.secrets."hermes/signal_phone" = lib.mkIf cfg.signal.enable {
      owner = config.services.hermes-agent.user;
      restartUnits = [
        "signal-cli.service"
        "hermes-agent.service"
      ];
    };

    # Signal DM allowlist (SIGNAL_ALLOWED_USERS): comma-separated E.164
    # numbers permitted to talk to the agent. Kept in sops (separate from the
    # account number) so the roster can grow without touching the account.
    # Consumed only by hermes-agent, so it restarts just that unit.
    sops.secrets."hermes/signal_allowed_users" = lib.mkIf cfg.signal.enable {
      restartUnits = [ "hermes-agent.service" ];
    };

    # Discord bot token (secret) + DM allowlist (comma-separated Discord user
    # IDs). Both feed the hermes-env file below; the adapter reads
    # DISCORD_BOT_TOKEN / DISCORD_ALLOWED_USERS from the environment.
    sops.secrets."hermes/discord_bot_token" = lib.mkIf cfg.discord.enable {
      restartUnits = [ "hermes-agent.service" ];
    };
    sops.secrets."hermes/discord_allowed_users" = lib.mkIf cfg.discord.enable {
      restartUnits = [ "hermes-agent.service" ];
    };

    sops.templates."hermes-env" = lib.mkIf (cfg.environmentFile == null) {
      content = ''
        ANTHROPIC_API_KEY=${config.sops.placeholder."hermes/anthropic_api_key"}
      ''
      + lib.optionalString cfg.signal.enable ''
        SIGNAL_ACCOUNT=${config.sops.placeholder."hermes/signal_phone"}
        SIGNAL_ALLOWED_USERS=${config.sops.placeholder."hermes/signal_allowed_users"}
      ''
      + lib.optionalString cfg.discord.enable ''
        DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes/discord_bot_token"}
        DISCORD_ALLOWED_USERS=${config.sops.placeholder."hermes/discord_allowed_users"}
      '';
      restartUnits = [
        "hermes-agent.service"
      ]
      ++ lib.optional cfg.web.enable "hermes-dashboard.service";
    };

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

      environmentFiles = [ hermesEnvFile ];

      # SIGNAL_ACCOUNT is intentionally NOT set here — it comes from the sops
      # env file (see hermes-env template) so the number stays out of the store.
      environment = lib.optionalAttrs cfg.signal.enable {
        SIGNAL_HTTP_URL = "http://127.0.0.1:${toString signalPort}";
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

        # Account number is read at runtime from the sops secret (command
        # substitution strips the trailing newline) so it never enters the
        # store. A wrapper script is needed because $(...) can't be used in a
        # bare systemd ExecStart= line.
        ExecStart = pkgs.writeShellScript "signal-cli-daemon" ''
          exec ${pkgs.signal-cli}/bin/signal-cli \
            --config ${signalConfigDir} \
            -a "$(cat ${config.sops.secrets."hermes/signal_phone".path})" \
            daemon \
            --http 127.0.0.1:${toString signalPort}
        '';

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

    # Hermes web dashboard (browser chat UI). A separate `hermes dashboard`
    # process from the gateway, bound to loopback so its built-in auth gate
    # stays OFF (trusted mode) — the reverse proxy in front (Caddy +
    # tinyauth/pocket-id) is the only auth layer. Binding non-loopback would
    # force Hermes' own mandatory OAuth, so keep it on 127.0.0.1.
    #
    # It shares the gateway's user, HOME and HERMES_HOME (/var/lib/hermes),
    # so it reads the same config.yaml, .env, sessions and memories. Same
    # lenient hardening as hermes-agent: it runs the agent (PTY/console), so
    # no MemoryDenyWriteExecute or strict SystemCallFilter.
    systemd.services.hermes-dashboard = lib.mkIf cfg.web.enable {
      description = "Hermes web dashboard (browser UI)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "hermes-agent.service"
      ];
      wants = [ "network-online.target" ];

      environment = {
        HOME = "/var/lib/hermes";
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "true";
        # Serve the pre-built SPA from the Nix store; never build at runtime.
        HERMES_WEB_DIST = "${cfg.web.package}";
      };

      serviceConfig = {
        User = config.services.hermes-agent.user;
        Group = config.services.hermes-agent.group;
        StateDirectory = "hermes";
        StateDirectoryMode = "2770";
        WorkingDirectory = "/var/lib/hermes";

        # ANTHROPIC_API_KEY (+ SIGNAL_* — harmless here). Same file the gateway
        # feeds, so the dashboard's agent has the API key without relying on
        # the gateway having written $HERMES_HOME/.env first.
        EnvironmentFile = [ hermesEnvFile ];

        ExecStart = lib.concatStringsSep " " [
          "${config.services.hermes-agent.package}/bin/hermes"
          "dashboard"
          "--no-open"
          "--skip-build"
          "--host 127.0.0.1"
          "--port ${toString cfg.web.port}"
        ];

        Restart = "always";
        RestartSec = 5;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        RemoveIPC = true;
        # Loopback bind + Anthropic API egress.
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };
  };
}
