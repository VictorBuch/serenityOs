{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.homelab.filesync;
  user = config.user.userName;
  filesDir = config.homelab.filesDir;

  folderPath = name: "${filesDir}/${name}";
in
{
  ###########################################################################
  # The sync half of the NAS, and the reason copyparty alone is not enough:
  # copyparty ships no two-way client (its u2c CLI only mirrors local ->
  # server), so continuous two-way sync of a REAPER project — the thing the
  # Nextcloud desktop client used to do — is Syncthing's job.
  #
  # These folders live under homelab.filesDir, so anything Syncthing pulls up
  # from a laptop is immediately browsable and shareable in copyparty, and
  # anything dropped into copyparty's web UI syncs back down.
  #
  # Syncthing itself is already enabled by services/notes.nix for the notes
  # vault; the options below are set to the same values so the two module
  # definitions merge instead of fighting.
  ###########################################################################
  options.homelab.filesync = {
    enable = mkEnableOption "two-way Syncthing sync of shared folders under homelab.filesDir";

    devices = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        jayne = "JAYNE-DEVICE-ID";
        inara = "INARA-DEVICE-ID";
      };
      description = ''
        Syncthing peers to share these folders with, name -> device ID.
        Grab the ID from each peer's Syncthing UI (Actions -> Show ID).
      '';
    };

    folders = mkOption {
      type = types.listOf types.str;
      default = [ "projects" ];
      description = ''
        Subfolders of homelab.filesDir to keep two-way synced. Each becomes a
        Syncthing folder with the same name.
      '';
    };

    versioning = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Keep a staggered version history of replaced/deleted files in each
        folder's .stversions, which is roughly what Nextcloud's file versions
        gave you. Off means a delete on any peer is a delete everywhere.
      '';
    };

    ignorePatterns = mkOption {
      type = types.listOf types.str;
      default = [
        # REAPER scratch files: regenerated on open, and rewritten constantly
        # while you work. Syncing them means every peer fights over them.
        "(?i)*.reapeaks"
        "(?i)*.reapindex"
        "(?i)*.rpp-bak"
        "(?i)*.rpp-undo"
        "(?i)*-autosave.rpp"
        # OS cruft
        ".DS_Store"
        "._*"
        "Thumbs.db"
        "desktop.ini"
      ];
      description = ''
        Syncthing ignore patterns applied to every folder. Pushed to Syncthing
        declaratively on each rebuild, so edit them here rather than in the
        Syncthing UI.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.folders != [ ];
        message = "homelab.filesync.enable is true but homelab.filesync.folders is empty.";
      }
    ];

    # Syncthing runs as ${user}; `files` group membership plus the setgid bit
    # on filesDir is what lets copyparty read and rewrite what it drops there.
    users.users.${user}.extraGroups = [ "files" ];

    services.syncthing = {
      enable = true;
      user = mkDefault user;
      group = mkDefault config.user.group;
      dataDir = mkDefault "/home/${user}";
      configDir = mkDefault "/home/${user}/.config/syncthing";
      openDefaultPorts = true;
      settings = {
        devices = mapAttrs (_: id: { inherit id; }) cfg.devices;
        folders = listToAttrs (
          map (
            name:
            nameValuePair name {
              path = folderPath name;
              devices = attrNames cfg.devices;
              inherit (cfg) ignorePatterns;
              versioning = mkIf cfg.versioning {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000"; # 30 days
                };
              };
            }
          ) cfg.folders
        );
      };
    };

    # Group-writable output, so files Syncthing lands are editable by copyparty.
    systemd.services.syncthing.serviceConfig.UMask = "0002";

    systemd.tmpfiles.rules = map (name: "d ${folderPath name} 2770 ${user} files -") cfg.folders;

  };
}
