{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  storage = config.homelab.mediaDir;
  user = config.user;
  uid = toString config.user.uid;
in

{

  options = {
    crafty.enable = lib.mkEnableOption "Enables the crafty minecraft server controller";
  };

  config = lib.mkIf config.crafty.enable {
    networking.firewall.allowedTCPPorts = [
      8443
      8123
    ];
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 25500;
        to = 25600;
      }
    ];

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/crafty 0770 ${uid} ${user.group}"
      "d /home/${user.userName}/crafty/logs 0770 ${uid} ${user.group}"
      "d /home/${user.userName}/crafty/servers 0770 ${uid} ${user.group}"
      "d /home/${user.userName}/crafty/config 0770 ${uid} ${user.group}"
      "d /home/${user.userName}/crafty/import 0770 ${uid} ${user.group}"
      "d ${storage}/crafty 0770 ${uid} ${user.group}"
      "d ${storage}/crafty/backups 0770 ${uid} ${user.group}"
    ];
    virtualisation.oci-containers.containers.crafty = {
      image = "registry.gitlab.com/crafty-controller/crafty-4:latest";
      autoStart = true;
      environment = {
        TZ = "Europe/Copenhagen";
      };
      user = "${uid}:${user.group}";
      ports = [
        "8443:8443"
        "8123:8123"
        "25500-25600:25500-25600"
      ];
      volumes = [
        "${storage}/crafty/backups:/crafty/backups"
        "/home/${user.userName}/crafty/logs:/crafty/logs"
        "/home/${user.userName}/crafty/servers:/crafty/servers"
        "/home/${user.userName}/crafty/config:/crafty/config"
        "/home/${user.userName}/crafty/import:/crafty/import"
      ];
    };
  };
}
