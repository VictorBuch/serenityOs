{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.chaptarr;
  mediaDir = config.homelab.mediaDir;
  user = config.user;
  uid = toString config.user.uid;
  configDir = "/home/${user.userName}/chaptarr";
in
{
  options.homelab.chaptarr.enable = lib.mkEnableOption "Chaptarr ebook and audiobook collection manager";

  config = lib.mkIf cfg.enable {
    # Host networking on the image's default port; the container is not told it.
    homelab.records.chaptarr = {
      port = 8789;
      exposure = "private";
      tile = {
        title = "Chaptarr";
        icon = "sh:chaptarr";
        group = "media";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${configDir} 0775 ${user.userName} ${user.group}"
    ];

    virtualisation.oci-containers.containers.chaptarr = {
      image = "chaptarr/chaptarr:latest";
      autoStart = true;
      environment = {
        PUID = uid;
        PGID = toString config.users.groups.multimedia.gid;
        UMASK = "002";
        TZ = config.time.timeZone;
      };
      volumes = [
        "${configDir}:/config"
        "${mediaDir}:${mediaDir}"
      ];
      extraOptions = [ "--network=host" ];
    };

    systemd.services.docker-chaptarr = {
      after = [ "mnt-pool.mount" ];
      requires = [ "mnt-pool.mount" ];
    };
  };
}
