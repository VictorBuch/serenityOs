args@{ config, pkgs, lib, mkCategory, ... }:

mkCategory {
  _file = toString ./.;
  name = "services";
  description = "Homelab services";
} args
