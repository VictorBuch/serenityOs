{
  config,
  lib,
  ...
}:
let
  cfg = config.home.liveSeams;

  seamModule = lib.types.submodule (
    { name, ... }:
    {
      options = {
        path = lib.mkOption {
          type = lib.types.str;
          description = "Path to the seam, relative to $HOME.";
        };
        comment = lib.mkOption {
          type = lib.types.str;
          default = "#";
          description = "Comment prefix the seam's own file format uses.";
        };
        precedence = lib.mkOption {
          type = lib.types.str;
          default = "Loaded after the generated config, so settings here win.";
          description = "One line saying how this seam beats the file Nix owns.";
        };
        reload = lib.mkOption {
          type = lib.types.str;
          description = "What the user does to make an edit take effect, e.g. a keybind or a command.";
        };
      };
    }
  );

  header =
    seam:
    lib.concatStringsSep "\n" [
      "${seam.comment} Live Seam -- not managed by Nix. ${seam.precedence}"
      "${seam.comment} Apply with ${seam.reload}."
    ];

  create = seam: ''
    seam="$HOME/${seam.path}"
    if [ ! -e "$seam" ]; then
      mkdir -p "$(dirname "$seam")"
      printf '%s\n' ${lib.escapeShellArg (header seam)} > "$seam"
    fi
  '';
in
{
  options.home.liveSeams = lib.mkOption {
    type = lib.types.attrsOf seamModule;
    default = { };
    description = ''
      Files the Shell or the user may write at runtime, referenced by `include`
      or `source` from a file Nix owns. Declared here; created on activation if
      absent, and never touched again.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    home.activation.liveSeams = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (map create (lib.attrValues cfg))
    );
  };
}
