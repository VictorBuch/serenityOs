{
  pkgs,
  lib,
  options,
  config,
  ...
}:

let
  user = config.user;
  uid = toString config.user.uid;
in

{
  options.wallos.enable = lib.mkEnableOption "Enables the wallos subscription tracker container";

  config = lib.mkIf config.wallos.enable {
    networking.firewall.allowedTCPPorts = [ 8282 ];

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/wallos 775 ${uid} ${user.group}"
      "d /home/${user.userName}/wallos/db 775 ${uid} ${user.group}"
      "d /home/${user.userName}/wallos/logos 775 ${uid} ${user.group}"
    ];

    virtualisation.oci-containers.containers.wallos = {
      image = "bellamy/wallos:latest";
      ports = [ "8282:80" ];
      volumes = [
        "/home/${user.userName}/wallos/db:/var/www/html/db"
        "/home/${user.userName}/wallos/logos:/var/www/html/images/uploads/logos"
      ];
      environment = {
        TZ = "Europe/Prague";
      };
      user = "${uid}:${user.group}";
      autoStart = true;
    };
  };
}
