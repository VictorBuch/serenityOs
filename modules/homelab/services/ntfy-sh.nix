{
  lib,
  config,
  ...
}:

let
  cfg = config.ntfy-sh;
  domain = config.homelab.domain;
in
{
  options.ntfy-sh = {
    enable = lib.mkEnableOption "Enables ntfy-sh push notification service";
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.${domain}";
        listen-http = ":8090";
        behind-proxy = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 8090 ];
  };
}
