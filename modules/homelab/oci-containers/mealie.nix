# Deprecated
{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  storage = config.homelab.storage;
  user = config.user;
  uid = toString config.user.uid;
in

{

  options = {
    mealie.enable = lib.mkEnableOption "Enables the mealie container";
  };

  config = lib.mkIf config.mealie.enable {

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/mealie 0770 ${uid} 911"
    ];

    networking.firewall.allowedTCPPorts = [ 9925 ];
    networking.firewall.allowedUDPPorts = [ 9925 ];

    virtualisation.oci-containers.containers.mealie = {
      image = "ghcr.io/mealie-recipes/mealie:v3.0.2";
      ports = [ "9925:9000" ];
      volumes = [
        "/home/${user.userName}/mealie:/app/data/"
      ];
      autoStart = true;
      environment = {
        ALLOW_SIGNUP = "false";
        TZ = "Europe/Copenhagen";
        MAX_WORKERS = "1";
        WEB_CONCURRENCY = "1";
        PUID = "1000";
        PGUI = "1000";
      };
    };
  };
}
