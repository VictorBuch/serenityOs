{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.newt;
  hl = config.homelab;

  # One Pangolin resource per edge service (see edge-services.nix — shared
  # with caddy.nix so the tunnel path and the LAN path can never drift).
  # Every resource targets Caddy on this host, which fans out by Host header;
  # `protected` becomes Pangolin's SSO auth screen on the public path.
  mkResource = domain: name: service: {
    inherit name;
    protocol = "http";
    full-domain = "${name}.${domain}";
    targets = [
      {
        hostname = "localhost";
        method = "https";
        port = 443;
      }
    ];
    auth.sso-enabled = service.protected or false;
  };
in
{
  options.homelab.newt = {
    enable = lib.mkEnableOption "Newt tunnel client (Pangolin site connector on wash)";

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://pangolin.${hl.domain}";
      description = "Pangolin server endpoint the tunnel connects to";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "pangolin/newt_id" = { };
      "pangolin/newt_secret" = { };
    };

    sops.templates."newt.env" = {
      content = ''
        NEWT_ID=${config.sops.placeholder."pangolin/newt_id"}
        NEWT_SECRET=${config.sops.placeholder."pangolin/newt_secret"}
      '';
      mode = "0400";
    };

    # Outbound-only: wss to pangolin + WireGuard to gerbil, no firewall ports needed
    services.newt = {
      enable = true;
      settings.endpoint = cfg.endpoint;
      environmentFile = config.sops.templates."newt.env".path;

      blueprint.proxy-resources =
        lib.mapAttrs (mkResource hl.domain) config.homelab.edge.services
        // lib.mapAttrs (mkResource hl.smoothlessDomain) config.homelab.edge.wannashareServices;
    };
  };
}
