{
  lib,
  config,
  ...
}:

let
  cfg = config.homelab.ntfy-sh;
  domain = config.homelab.domain;
in
{
  options.homelab.ntfy-sh = {
    enable = lib.mkEnableOption "Enables ntfy-sh push notification service";
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.${domain}";
        listen-http = ":8033";
        behind-proxy = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 8033 ];
  };
}
