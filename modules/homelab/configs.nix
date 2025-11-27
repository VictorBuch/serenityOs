{
  pkgs,
  lib,
  config,
  options,
  ...
}:
let
  hl = config.homelab;
in
{
  options.homelab = {
    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/pool/media";
      description = "Directory for media files (movies, TV shows, downloads)";
    };
    immichDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/pool/immich";
      description = "Directory for Immich photo storage";
    };
    nextcloudDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/pool/nextcloud";
      description = "Directory for Nextcloud data";
    };
    paperlessDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/pool/paperless";
      description = "Directory for Paperless-ngx document storage";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "victorbuch.com";
    };
    domain-local = lib.mkOption {
      type = lib.types.str;
      default = "local.victorbuch.com";
    };
    nixosIp = lib.mkOption {
      type = lib.types.str;
      default = "192.168.0.243";
    };
  };

  config = {
    # No additional packages or configuration needed
    # Storage configuration is handled by storage.nix
  };
}
