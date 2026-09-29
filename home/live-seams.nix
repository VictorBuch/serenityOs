{
  config,
  lib,
  ...
}:
{
  options.home.liveSeams = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.path = lib.mkOption {
          type = lib.types.str;
          description = "Path to the seam, relative to $HOME and to serenityOs/dotfiles.";
        };
      }
    );
    default = { };
    description = ''
      Files included or sourced from a file Nix owns, symlinked to
      ~/serenityOs/dotfiles/<path> so edits are live and tracked in git.
    '';
  };

  config.home.file = lib.mapAttrs' (
    _: seam:
    lib.nameValuePair seam.path {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/serenityOs/dotfiles/${seam.path}";
    }
  ) config.home.liveSeams;
}
