{
  pkgs,
  lib,
  config,
  ...
}:

let
  tag-toggle = pkgs.writeShellApplication {
    name = "mango-tag-toggle";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      # Usage: mango-tag-toggle [--carry]
      carry=0
      if [ "''${1:-}" = "--carry" ]; then
          carry=1
      fi

      current=$(mmsg get all-monitors 2>/dev/null \
          | jq -r '.monitors[] | select(.active) | .active_tags[0] // empty' \
          | head -n1 || true)

      if [ "$current" = "2" ]; then
          other=1
      else
          other=2
      fi

      if [ "$carry" = "1" ]; then
          mmsg dispatch tag,"$other" >/dev/null 2>&1 || true
      else
          mmsg dispatch view,"$other" >/dev/null 2>&1 || true
      fi
    '';
  };
in
{
  options = {
    home.desktop.compositor.mango.tag-toggle.enable =
      lib.mkEnableOption "Enable tag-toggle helper for mango";
  };

  config = lib.mkIf config.home.desktop.compositor.mango.tag-toggle.enable {
    home.packages = [ tag-toggle ];
  };
}
