args@{ config, pkgs, lib, mkApp, ... }:

let
  storage = config.homelab.storage;
  user = config.user;
  uid = toString config.user.uid;
in

mkApp {
  _file = toString ./.;
  name = "uptime-kuma";
  description = "Uptime Kuma monitoring service";
  packages = pkgs: [];  # No packages for services

  extraConfig = {
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
} args
