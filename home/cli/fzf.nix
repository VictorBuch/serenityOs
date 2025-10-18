{
  config,
  options,
  pkgs,
  lib,
  ...
}:

{

  options = {
    home.cli.fzf.enable = lib.mkEnableOption "Enables fzf home manager";
  };

  config = lib.mkIf config.home.cli.fzf.enable {
    home.packages = with pkgs; [
      fzf
    ];
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
