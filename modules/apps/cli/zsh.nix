args@{
  config,
  pkgs,
  lib,
  mkApp,
  ...
}:

let
  aliases = {
    v = "sudo nvim ";
    vi = "sudo nvim ";
    zshrc = "sudo nvim ~/.zshrc";
    lg = "lazygit";
    en = "nvim ~/serenityOs/ ";
    r = "source ~/.zshrc";
    ".." = "(cd ..) && (ls)";
  };
in

mkApp {
  _file = toString ./.;
  name = "zsh";
  description = "Z shell";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        zsh
      ];

      programs.zsh = {
        enable = true;
        shellAliases = aliases;
        autosuggestion.enable = true;
        initContent = ''
          eval "$(starship init zsh)"
          eval "$(zoxide init zsh)"
        '';
      };
    };
} args
