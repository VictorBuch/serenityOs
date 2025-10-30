args@{ config, pkgs, lib, mkHomeCategory, ... }:

mkHomeCategory {
  _file = toString ./.;
  name = "terminals";
} args
