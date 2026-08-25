args@{
  config,
  pkgs,
  lib,
  inputs,
  mkModule,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  upstream = inputs.skwd-wall.packages.${system}.default;
  paper = inputs.skwd-wall.inputs.skwd-daemon.packages.${system}.default;

  skwd = pkgs.symlinkJoin {
    name = "skwd-wall-with-qtmultimedia";
    paths = [ upstream ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in skwd skwd-daemon skwd-wall; do
        wrapProgram "$out/bin/$bin" \
          --prefix NIXPKGS_QT6_QML_IMPORT_PATH : ${pkgs.qt6.qtmultimedia}/lib/qt-6/qml \
          --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtmultimedia}/lib/qt-6/plugins
      done
    '';
  };
in
mkModule {
  name = "skwd-wall";
  platforms = [ "linux" ];
  category = "theming";
  description = "Skwd-wall wallpaper selector (picks; noctalia applies and derives the palette)";

  packages = _: [ skwd ];

  homeConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Only these keys are ours. Everything else in config.json stays whatever
      # the app's own settings UI last wrote, so the GUI keeps working.
      videoDir = "${config.home.homeDirectory}/videowalls";

      # Videos are painted by skwd-paper on a layer above noctalia's wallpaper.
      # noctalia still gets an image -- a frame lifted out of the video -- so the
      # palette is derived from whatever is actually on screen.
      setWallpaper = pkgs.writeShellScript "skwd-set-wallpaper" ''
        set -eu
        path="$1"
        ${pkgs.procps}/bin/pkill -x skwd-paper || true

        case "$path" in
          *.mp4 | *.mkv | *.avi | *.mov | *.MP4 | *.MKV | *.AVI | *.MOV) ;;
          *)
            exec noctalia msg wallpaper-set "$path"
            ;;
        esac

        still="${config.xdg.cacheHome}/skwd-wall/still/$(basename "$path").png"
        mkdir -p "$(dirname "$still")"
        ${pkgs.ffmpeg}/bin/ffmpeg -loglevel error -y -ss 1 -i "$path" -frames:v 1 "$still" \
          || ${pkgs.ffmpeg}/bin/ffmpeg -loglevel error -y -i "$path" -frames:v 1 "$still"
        noctalia msg wallpaper-set "$still"

        ${pkgs.wlr-randr}/bin/wlr-randr --json \
          | ${pkgs.jq}/bin/jq -r '.[] | select(.enabled) | .name' \
          | while read -r out; do
              ${pkgs.util-linux}/bin/setsid ${paper}/bin/skwd-paper "$out" "$path" \
                >/dev/null 2>&1 &
            done
      '';

      managed = pkgs.writeText "skwd-wall-managed.json" (
        builtins.toJSON {
          paths.wallpaper = config.wallpapers.path;
          paths.videoWallpaper = videoDir;
          # noctalia owns the palette, so skwd's matugen pipeline stays off and
          # the wallpaper is handed to noctalia instead of skwd's own setter.
          features.matugen = false;
          pickOnlyMode = true;
          externalWallpaperCommand = ''${setWallpaper} "%path%"'';
        }
      );

      seed = pkgs.writeShellScript "skwd-wall-config" ''
        set -eu
        target="${config.xdg.configHome}/skwd-wall/config.json"
        mkdir -p "$(dirname "$target")"
        base="$target"
        [ -f "$target" ] || base="${skwd}/share/skwd-wall/data/config.json.example"
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$base" ${managed} > "$target.new"
        mv "$target.new" "$target"
        chmod u+w "$target"
      '';
    in
    {
      home.activation.skwdWallConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${videoDir}
        run ${seed}
      '';
    };
} args
