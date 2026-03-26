args@{
  config,
  pkgs,
  lib,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "fzf";
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
