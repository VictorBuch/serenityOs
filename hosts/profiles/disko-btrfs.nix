# Shared btrfs disk layout for disko-provisioned hosts.
#
# Usage from a host configuration.nix:
#
#   imports = [
#     (import ../profiles/disko-btrfs.nix { device = "/dev/nvme0n1"; })
#   ];
#
# Layout: GPT, 512M vfat ESP at /boot, remainder as btrfs with subvols:
#   @     -> /
#   @home -> /home
#   @nix  -> /nix
#   @log  -> /var/log
# Mount options: compress=zstd,noatime on every subvol.
{ device }:
{ ... }:
{
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
