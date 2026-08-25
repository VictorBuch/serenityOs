# One writable wallpaper directory, filled with symlinks from the packs below.
# skwd-wall picks from it, noctalia draws whatever skwd picks.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.wallpapers;

  isImage = name: builtins.match ".*[.](jpg|jpeg|png|webp)" (lib.toLower name) != null;

  entriesFor =
    pack:
    let
      dir = if pack.subdir == null then pack.src else pack.src + "/${pack.subdir}";
      names = lib.filter isImage (
        lib.attrNames (lib.filterAttrs (_: type: type == "regular") (builtins.readDir dir))
      );
    in
    map (
      name:
      lib.nameValuePair "${cfg.directory}/${pack.name}-${name}" {
        source = dir + "/${name}";
      }
    ) names;

  packType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Filename prefix for this pack's symlinks.";
      };
      src = lib.mkOption {
        type = lib.types.path;
        description = "Directory holding the images.";
      };
      subdir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Subdirectory of src to read instead of src itself.";
      };
    };
  };
in
{
  options.wallpapers = {
    directory = lib.mkOption {
      type = lib.types.str;
      default = "Pictures/Wallpapers";
      description = "Pool directory, relative to $HOME.";
    };

    path = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${config.home.homeDirectory}/${cfg.directory}";
      description = "Absolute path to the pool directory.";
    };

    packs = lib.mkOption {
      type = lib.types.listOf packType;
      default = [
        {
          name = "serenity";
          src = ./wallpapers;
        }
        {
          name = "nord";
          src = inputs.wallpapers-nord;
        }
      ];
      description = "Image sources symlinked into the pool.";
    };
  };

  config.home.file = lib.listToAttrs (lib.concatMap entriesFor cfg.packs);
}
