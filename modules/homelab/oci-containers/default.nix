args@{ config, pkgs, lib, mkCategory, ... }:

mkCategory {
  _file = toString ./.;
  name = "oci-containers";
  description = "Homelab OCI containers";
} args
