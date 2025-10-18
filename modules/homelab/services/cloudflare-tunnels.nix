{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  hl = config.homelab;
  dom = hl.domain;
  nixosIp = hl.nixosIp;
in
{

  options = {
    cloudflare-tunnel.enable = lib.mkEnableOption "Enables the cloudflare tunnel service";
  };

  config = lib.mkIf config.cloudflare-tunnel.enable {

    services.cloudflared = {
      enable = true;
      tunnels."7cd014d0-a9b0-4fc5-82e5-393486bba01a" = {
        credentialsFile = config.sops.templates."cloudflared-credentials".path;
        default = "http_status:404";
        ingress = {
          "*.${dom}" = {
            service = "https://127.0.0.1:443";
            originRequest = {
              # Send subdomain as SNI to match wildcard certificate (*.victorbuch.com)
              originServerName = "*.${dom}";
            };
          };
        };
      };
    };
  };
}
