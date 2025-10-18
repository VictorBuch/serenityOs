{
  config,
  options,
  pkgs,
  lib,
  ...
}:

{

  options = {
    home.cli.git.enable = lib.mkEnableOption "Enables git home manager";
  };

  config = lib.mkIf config.home.cli.git.enable {
    home.packages = with pkgs; [
      git
    ];

    programs.git = {
      userEmail = "victorbuch@protonmail.com";
      userName = "VictorBuch";
    };
  };
}
