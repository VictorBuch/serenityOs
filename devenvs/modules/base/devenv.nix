{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.serenity.cmds = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Lines describing the commands this environment provides, shown by `cmds`.";
  };

  config = {
    packages = with pkgs; [ jq ];

    serenity.cmds = lib.mkBefore "cmds              List the commands this environment provides";

    scripts.cmds.exec =
      let
        lines = lib.filter (l: l != "") (lib.splitString "\n" config.serenity.cmds);
        doc = pkgs.writeText "devenv-cmds" (
          "\nCommands provided by this environment:\n\n" + lib.concatStringsSep "\n" lines + "\n"
        );
      in
      "exec cat ${doc}";

    enterShell = lib.mkBefore ''
      echo "▸ ''${DEVENV_ROOT##*/} — run 'cmds' to list available commands"
    '';
  };
}
