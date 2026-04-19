args@{
  config,
  mkModule,
  ...
}:

mkModule {
  name = "syncthing";
  category = "utilities";
  linuxPackages =
    { pkgs, ... }:
    [
      pkgs.syncthing
      pkgs.gnomeExtensions.syncthing-toggle
    ];
  description = "Syncthing file synchronization (Linux only)";
  linuxExtraConfig = {
    services.syncthing = {
      enable = true;
      dataDir = "/home/${config.user.userName}"; # default location for new folders
      configDir = "/home/${config.user.userName}/.config/syncthing";
      user = "${config.user.userName}";
      group = "users";
      openDefaultPorts = true;
    };
  };
} args
