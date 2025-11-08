args@{ config, pkgs, lib, mkHomeModule, ... }:

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

mkHomeModule {
  _file = toString ./.;
  name = "zsh";
  description = "Z shell";
  homeConfig = { config, pkgs, lib, ... }: {
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

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      stdlib = ''
        # Source devenv's direnvrc for use_devenv function
        source <(${pkgs.devenv}/bin/devenv direnvrc)
      '';
    };
  };
} args
