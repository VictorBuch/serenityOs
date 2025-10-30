args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  _file = toString ./.;
  name = "sesh";
  description = "Session manager for tmux";
  homeConfig = { config, pkgs, lib, ... }: {
    programs.sesh = {
      enable = true;
      enableTmuxIntegration = true;
      enableAlias = false;
      tmuxKey = "s";
    };
  };
} args
