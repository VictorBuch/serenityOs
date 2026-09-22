{
  lib,
  config,
  ...
}:

let
  cfg = config.homelab.ntfy-sh;
  ntfy = config.homelab.records.ntfy;
in
{
  options.homelab.ntfy-sh = {
    enable = lib.mkEnableOption "Enables ntfy-sh push notification service";
  };

  config = lib.mkIf cfg.enable {
    # Push clients must reach it without an auth screen.
    homelab.records.ntfy = {
      port = 8033;
      exposure = "public";
      openFirewall = true;
      tile = {
        title = "Ntfy";
        icon = "sh:ntfy";
        group = "productivity";
      };
    };

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = ntfy.url;
        listen-http = ":${toString ntfy.port}";
        behind-proxy = true;
      };
    };
  };
}
