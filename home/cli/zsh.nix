{
  config,
  pkgs,
  lib,
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

{
  options = {
    home.cli.zsh.enable = lib.mkEnableOption "Enables zsh home manager";
  };

  config = lib.mkIf config.home.cli.zsh.enable {
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
    };
  };
}
