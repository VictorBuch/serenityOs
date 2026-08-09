{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.newt;
  hl = config.homelab;
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
    };
  };
}
