{
  pkgs,
  lib,
  options,
  config,
  ...
}:

let
  storage = config.homelab.storage;
  user = config.user;
  uid = toString config.user.uid;
in

{
  options.uptime-kuma.enable = lib.mkEnableOption "Enables the monitoring service uptime kuma";

  config = lib.mkIf config.uptime-kuma.enable {
    networking.firewall.allowedTCPPorts = [ 3001 ];

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/uptime-kuma 775 ${user.userName} ${user.group}"
    ];

    virtualisation.oci-containers.containers.uptime-kuma = {
      image = "louislam/uptime-kuma:latest";
      ports = [ "3001:3001" ];
      volumes = [
        "/home/${user.userName}/uptime-kuma:/app/data/"
      ];
      autoStart = true;
    };
  };
}
