# Netcup VPS 500 G12 — virtio-blk, confirmed /dev/vda via rescue lsblk
# (the tiny /dev/vdb is Netcup metadata, untouched)
(import ../profiles/disko-btrfs.nix { device = "/dev/vda"; })
