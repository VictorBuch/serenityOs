args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  _file = toString ./.;
  name = "fzf";
  description = "Fuzzy finder";
  homeConfig = { config, pkgs, lib, ... }: {
    home.packages = with pkgs; [
      fzf
    ];
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };
  };
} args
