{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.homelab.notes;
  user = config.user.userName;
  group = config.user.group;
  home = "/home/${user}";
  notesDir = "${home}/notes";
  quartzDir = "${home}/quartz";
  # Kept in sync with the `notes` static-files vhost in services/caddy.nix.
  publishDir = "/var/www/notes";
in
{
  ###########################################################################
  # Plain-Markdown notetaking vault on mal:
  #   1. Syncthing node holding the canonical ~/notes folder (laptop + phone)
  #   2. Hourly git auto-commit for history (you never run git by hand)
  #   3. Quartz build that publishes notes tagged `publish: true`
  #
  # Serving is handled by Caddy (notes.<domain>), NOT nginx — see
  # services/caddy.nix. External access rides the existing wildcard
  # *.${domain} Cloudflare tunnel + origin cert, so nothing to add there.
  ###########################################################################
  options.homelab.notes = {
    enable = mkEnableOption "plain-Markdown notes vault (Syncthing + git history + Quartz wiki)";

    devices = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        laptop = "LAPTOP-DEVICE-ID";
        phone = "PHONE-DEVICE-ID";
      };
      description = ''
        Syncthing peers to share the notes folder with, name -> device ID.
        Grab the ID from each peer's Syncthing UI (Actions -> Show ID).
        Leave empty to sync nothing yet (the vault still works locally).
      '';
    };

    publishWiki = mkOption {
      type = types.bool;
      default = true;
      description = "Build the Quartz wiki and serve it via Caddy.";
    };
  };

  config = mkIf cfg.enable {
    #########################################################################
    # 1. Syncthing — continuous, silent sync to laptop and phone.
    #    mkDefault so the apps/utilities/syncthing.nix module wins if it is
    #    ever enabled on this host too.
    #########################################################################
    services.syncthing = {
      enable = true;
      user = mkDefault user;
      group = mkDefault group;
      dataDir = mkDefault home;
      configDir = mkDefault "${home}/.config/syncthing";
      openDefaultPorts = true;
      settings = {
        devices = mapAttrs (_: id: { inherit id; }) cfg.devices;
        folders.notes = {
          path = notesDir;
          devices = attrNames cfg.devices;
        };
      };
    };

    #########################################################################
    # 2. Hourly git auto-commit — history without ever touching git yourself.
    #########################################################################
    systemd.services.notes-autocommit = {
      description = "Auto-commit the notes vault";
      path = [ pkgs.git ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        WorkingDirectory = notesDir;
      };
      script = ''
        [ -d .git ] || git init -q
        git add -A
        git diff --cached --quiet || git commit -q -m "auto: $(date -Iseconds)"
      '';
    };
    systemd.timers.notes-autocommit = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };

    #########################################################################
    # 3. Quartz build + publish (served by Caddy, see services/caddy.nix).
    #    One-time setup as ${user}:
    #      git clone https://github.com/jackyzha0/quartz ${quartzDir}
    #      cd ${quartzDir} && npm i && npx quartz create
    #      ln -s ${notesDir} ${quartzDir}/content
    #    Then enable the ExplicitPublish filter in quartz.config.ts so only
    #    notes with `publish: true` frontmatter are built.
    #########################################################################
    systemd.tmpfiles.rules = mkIf cfg.publishWiki [
      "d ${publishDir} 0755 ${user} ${group} -"
    ];

    systemd.services.quartz-build = mkIf cfg.publishWiki {
      description = "Build the Quartz digital garden";
      path = [
        pkgs.nodejs_22
        pkgs.git
      ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        WorkingDirectory = quartzDir;
        ExecStart = "${pkgs.nodejs_22}/bin/npx quartz build -o ${publishDir}";
      };
    };

    # Rebuild every 5 minutes (a paths watcher only fires on direct children,
    # so a timer is the robust choice for a nested vault).
    systemd.timers.quartz-build = mkIf cfg.publishWiki {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "5m";
      };
    };
  };
}
