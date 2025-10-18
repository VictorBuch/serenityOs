{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.user;
in

{

  options = {
    apps.productivity.syncthing.enable = lib.mkEnableOption "Enables Syncthing";
  };

  config = lib.mkIf config.apps.productivity.syncthing.enable {
    environment.systemPackages = with pkgs; [
      syncthing
      gnomeExtensions.syncthing-toggle
    ];

    services.syncthing = {
      enable = true;
      dataDir = "/home/${user.userName}"; # default location for new folders
      configDir = "/home/${user.userName}/.config/syncthing";
      user = "${user.userName}";
      group = "users";
      openDefaultPorts = true;
    };
  };
}
