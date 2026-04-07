args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "fzf";
  category = "cli";
  description = "Fuzzy finder";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.fzf = {
        enable = true;
        package = pkgs.fzf;
        enableZshIntegration = true;
        tmux.enableShellIntegration = true;
      };
    };
} args
