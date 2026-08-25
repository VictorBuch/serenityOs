args@{
  config,
  pkgs,
  lib,
  inputs,
  mkModule,
  ...
}:

let
  skwd = inputs.skwd-wall.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
      managed = pkgs.writeText "skwd-wall-managed.json" (
        builtins.toJSON {
          paths.wallpaper = config.wallpapers.path;
          # noctalia owns the palette, so skwd's matugen pipeline stays off and
          # the wallpaper is handed to noctalia instead of skwd's own setter.
          features.matugen = false;
          pickOnlyMode = true;
          externalWallpaperCommand = ''noctalia msg wallpaper-set "%path%"'';
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
        run ${seed}
      '';
    };
} args
