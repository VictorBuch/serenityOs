{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.sparkyfitness;
  sf = config.services.sparkyfitness;
  record = config.homelab.records.sparkyfitness;
in
{
  options.homelab.sparkyfitness = {
    enable = lib.mkEnableOption "SparkyFitness nutrition/fitness tracker";
    public = lib.mkEnableOption "public Pangolin access (also closes signups)";
  };

  config = lib.mkIf cfg.enable {
    homelab.records.sparkyfitness = {
      subdomain = "fitness";
      kind = "static";
      root = "${sf.frontendPackage}";
      inherit (sf) port;
      exposure = if cfg.public then "public" else "private";
      caddy.extraRoutes = ''
        handle /health-data* {
          rewrite * /api{uri}
          reverse_proxy ${record.upstream}
        }
        @sparkyBackend path /api/* /uploads/* /mcp*
        handle @sparkyBackend {
          reverse_proxy ${record.upstream}
        }
      '';
      tile = {
        title = "SparkyFitness";
        icon = "sh:sparkyfitness";
        group = "productivity";
      };
    };

    sops.secrets = {
      "sparkyfitness/db_password" = { };
      "sparkyfitness/app_db_password" = { };
      "sparkyfitness/api_encryption_key" = { };
      "sparkyfitness/better_auth_secret" = { };
    };

    sops.templates."sparkyfitness.env" = {
      content = ''
        SPARKY_FITNESS_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/db_password"}
        SPARKY_FITNESS_APP_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/app_db_password"}
        SPARKY_FITNESS_API_ENCRYPTION_KEY=${config.sops.placeholder."sparkyfitness/api_encryption_key"}
        BETTER_AUTH_SECRET=${config.sops.placeholder."sparkyfitness/better_auth_secret"}
      '';
      mode = "0400";
      restartUnits = [
        "sparkyfitness-db-init.service"
        "sparkyfitness.service"
      ];
    };

    services.sparkyfitness = {
      enable = true;
      frontendUrl = record.url;
      environmentFile = config.sops.templates."sparkyfitness.env".path;
      database.package = pkgs.postgresql_17;
      nginx.enable = false;
      extraEnvironment.SPARKY_FITNESS_DISABLE_SIGNUP = lib.boolToString cfg.public;
    };

    services.postgresql.package = lib.mkForce sf.database.package;
  };
}
