args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "firefox";
  category = "browsers";
  packages = { pkgs, ... }: [ pkgs.firefox ];
  description = "Mozilla Firefox web browser";
} args
