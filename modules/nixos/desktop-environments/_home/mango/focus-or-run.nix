{
  pkgs,
  lib,
  config,
  ...
}:

let
  focus-or-run = pkgs.writeShellApplication {
    name = "mango-focus-or-run";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      # Usage: mango-focus-or-run <appid-regex> <pinned-tag> <command> [args...]
      #
      # mango IPC has no focus-by-appid dispatch and `mmsg -g -c` only reports
      # the focused client. Wrapper scripts (zen-beta, figma-linux) exec into
      # different proc names, so pgrep is unreliable. Strategy: view pinned tag,
      # cycle focusstack and read focused appid each step; if no match after a
      # full cycle, scan all tags as fallback; if still nothing, launch.
      if [ $# -lt 3 ]; then
          echo "Usage: mango-focus-or-run <appid-regex> <pinned-tag> <command> [args...]" >&2
          exit 1
      fi

      app_re="$1"
      tag="$2"
      shift 2

      get_appid() {
          mmsg -g -c 2>/dev/null | awk '$2 == "appid" {print $3; exit}'
      }

      try_tag() {
          mmsg -d view,"$1" >/dev/null 2>&1 || true
          first=""
          for _ in 1 2 3 4 5 6 7 8; do
              cur=$(get_appid)
              if [ -n "$cur" ] && echo "$cur" | grep -qiE "$app_re"; then
                  return 0
              fi
              # Empty tag or cycled back to first seen window — give up.
              if [ -z "$cur" ]; then
                  return 1
              fi
              if [ -z "$first" ]; then
                  first="$cur"
              elif [ "$cur" = "$first" ]; then
                  return 1
              fi
              mmsg -d focusstack,next >/dev/null 2>&1 || true
          done
          return 1
      }

      # 1. Try the pinned tag.
      if try_tag "$tag"; then exit 0; fi

      # 2. Fallback: scan every tag (handles app on wrong tag).
      for t in 1 2 3 4 5 6 7 8 9; do
          [ "$t" = "$tag" ] && continue
          if try_tag "$t"; then exit 0; fi
      done

      # 3. Not running anywhere — view pinned tag and launch.
      mmsg -d view,"$tag" >/dev/null 2>&1 || true
      setsid "$@" >/dev/null 2>&1 &
    '';
  };
in
{
  options = {
    home.desktop-environments.mango.focus-or-run.enable =
      lib.mkEnableOption "Enable focus-or-run helper for mango";
  };

  config = lib.mkIf config.home.desktop-environments.mango.focus-or-run.enable {
    home.packages = [ focus-or-run ];
  };
}
