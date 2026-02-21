{
  pkgs,
  lib,
  config,
  options,
  ...
}:

{

  imports = [
    ../nixos/system/user.nix
    ./configs.nix
    ./storage.nix
    ./database-backups.nix
    ./maintenance.nix
    ./oci-containers/uptime-kuma.nix
    ./oci-containers/crafty.nix
    ./oci-containers/deluge-vpn.nix
    ./oci-containers/wallos.nix
    ./oci-containers/tinyauth.nix
    ./oci-containers/tdarr.nix
    ./oci-containers/invoiceplane.nix
    ./oci-containers/invoice-ninja.nix
    ./oci-containers/reactive-resume.nix
    ./services/dashboard.nix
    ./services/streaming.nix
    ./services/nginx-proxy.nix
    ./services/cloudflare-tunnels.nix
    ./services/authelia.nix
    ./services/adguard.nix
    ./services/filebrowser.nix
    ./services/nextcloud.nix
    ./services/immich.nix
    ./services/mealie.nix
    ./services/hyperhdr.nix
    ./services/music-assistant.nix
    ./services/home-assistant.nix
    ./services/caddy.nix
    ./services/pocket-id.nix
    ./services/gitea.nix
    ./services/tailscale.nix
    ./services/it-tools.nix
    ./services/paperless.nix
    ./services/wannashare.nix
    ./lab.nix
  ];

  # maintenance.enable inherits from modules/common/maintenance.nix
  dashboard.homarr.enable = lib.mkDefault false;
  dashboard.glance.enable = lib.mkDefault false;
  uptime-kuma.enable = lib.mkDefault false;
  streaming.enable = lib.mkDefault false;
  mealie.enable = lib.mkDefault false;
  crafty.enable = lib.mkDefault false;
  immich.enable = lib.mkDefault false;
  wallos.enable = lib.mkDefault false;
  tinyauth.enable = lib.mkDefault false;
  tdarr.enable = lib.mkDefault false;
  invoiceplane.enable = lib.mkDefault false;
  invoice-ninja.enable = lib.mkDefault false;
  reactive-resume.enable = lib.mkDefault false;
  cloudflare-tunnel.enable = lib.mkDefault false;
  nginx-reverse-proxy.enable = lib.mkDefault false;
  caddy.enable = lib.mkDefault false;
  deluge-vpn.enable = lib.mkDefault false;
  authelia.enable = lib.mkDefault false;
  adguard.enable = lib.mkDefault false;
  filebrowser.enable = lib.mkDefault false;
  nextcloud.enable = lib.mkDefault false;
  pocket-id.enable = lib.mkDefault false;
  gitea.enable = lib.mkDefault false;
  tailscale.enable = lib.mkDefault false;
  it-tools.enable = lib.mkDefault false;
  paperless.enable = lib.mkDefault false;
  wannashare.enable = lib.mkDefault false;
}
