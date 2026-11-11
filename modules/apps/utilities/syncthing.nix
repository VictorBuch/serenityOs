{
  flake.modules.nixos.syncthing =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.syncthing
        pkgs.gnomeExtensions.syncthing-toggle
      ];
      services.syncthing = {
        enable = true;
        dataDir = "/home/${config.user.userName}"; # default location for new folders
        configDir = "/home/${config.user.userName}/.config/syncthing";
        user = "${config.user.userName}";
        group = "users";
        openDefaultPorts = true;
      };
    };
}
