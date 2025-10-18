{
  pkgs,
  lib,
  options,
  config,
  ...
}:
let
  user = config.user;
  uid = toString config.user.uid; # ghost user UID
  gid = "mealie";
in
{
  options.mealie.enable = lib.mkEnableOption "Enables mealie service";

  config = lib.mkIf config.mealie.enable {

    # Create dedicated mealie group
    users.groups.mealie = {
      name = "mealie";
      gid = 998;
    };

    # Create mealie system user
    users.users.mealie = {
      isSystemUser = true;
      uid = 998;
      group = "mealie";
      extraGroups = [ "users" ];
      home = "/var/lib/mealie";
      shell = pkgs.bash;
    };

    # Add ghost user to mealie group for management access
    users.users.${user.userName}.extraGroups = [ "mealie" ];

    systemd.tmpfiles.rules = [
      "d /home/${user.userName}/mealie 0770 mealie mealie"
    ];

    networking.firewall.allowedTCPPorts = [ 9000 ];
    networking.firewall.allowedUDPPorts = [ 9000 ];

    sops.templates."mealie" = {
      content = ''
        DB_ENGINE=postgres
        POSTGRES_USER=mealie
        POSTGRES_PASSWORD=${config.sops.placeholder."mealie/db_password"}
        POSTGRES_DB=mealie

      '';
      owner = "mealie";
      group = "mealie";
      mode = "0600";
    };

    services.mealie = {
      enable = true;
      port = 9000;
      listenAddress = "0.0.0.0";
      settings = {
        PUID = 998;
        GUID = 998;
      };
      credentialsFile = config.sops.templates."mealie".path;
      database.createLocally = true;
    };
    nixpkgs.overlays = [
      (self: super: {
        mealie = super.mealie.overrideAttrs (oldAttrs: {
          doCheck = false;
          doInstallCheck = false;
        });
      })
    ];
  };
}
