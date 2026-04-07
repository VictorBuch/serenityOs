args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "slack";
  category = "communication";
  packages = { pkgs, ... }: [ pkgs.slack ];
  description = "Slack team communication";
} args
