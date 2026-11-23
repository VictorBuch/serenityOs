{
  flake.modules.homeManager.activitywatch =
    { lib, pkgs, ... }:
    {
      xdg.desktopEntries.activitywatch = {
        name = "ActivityWatch";
        exec = "xdg-open http://localhost:5600";
        icon = "${pkgs.activitywatch}/share/icons/hicolor/scalable/apps/activitywatch.svg";
        categories = [ "Utility" ];
      };

      services.activitywatch = {
        enable = true;
        watchers.awatcher = {
          package = pkgs.awatcher;
          extraOptions = [
            "--config"
            "${(pkgs.formats.toml { }).generate "awatcher.toml" {
              awatcher.filters =
                lib.mapAttrsToList
                  (name: match: {
                    match-app-id = match;
                    replace-app-id = name;
                  })
                  {
                    REAPER = "reaper";
                    "DaVinci Resolve" = "(?i).*resolve.*";
                    "$1" = "ai\\.storyteller\\.(.*)";
                    RetroArch = "(?i).*retroarch.*";
                    ES-DE = "(?i).*es[-_]de.*";
                    PCSX2 = "(?i).*pcsx2.*";
                    RPCS3 = "(?i).*rpcs3.*";
                    Eden = "(?i)(dev\\.eden_emu\\.)?eden";
                  }
                ++ [ { match-app-id = ".*"; } ];
            }}"
          ];
        };
      };
    };
}
