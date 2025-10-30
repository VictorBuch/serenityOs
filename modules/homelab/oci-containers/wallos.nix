args@{ config, pkgs, lib, mkApp, ... }:

let
  user = config.user;
  uid = toString config.user.uid;
in

mkApp {
  _file = toString ./.;
  name = "wallos";
  description = "Wallos subscription tracker";
  packages = pkgs: [];  # No packages for services

  extraConfig = {
    networking.firewall.allowedTCPPorts = [ 8282 ];

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/wallos 775 ${user.userName} ${user.group}"
      "d /home/${user.userName}/wallos/db 775 ${user.userName} ${user.group}"
      "d /home/${user.userName}/wallos/logos 775 ${user.userName} ${user.group}"
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
      autoStart = true;
    };
  };
} args
