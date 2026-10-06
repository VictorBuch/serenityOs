{
  config,
  lib,
  pkgs,
  ...
}:

let
  nirirun = pkgs.writeShellScriptBin "nirirun" ''
    PATH=${lib.makeBinPath [ pkgs.jq ]}:$PATH
    ${builtins.readFile ./nirirun}
  '';
in
{
  options = {
    home.desktop.compositor.niri.enable = lib.mkEnableOption "Enables niri home manager";
  };

  config = lib.mkIf config.home.desktop.compositor.niri.enable {
    home.liveSeams = {
      niri.path = ".config/niri/config.kdl";
      niri-cfg.path = ".config/niri/cfg";
    };
    home.packages = [ nirirun ];

    xdg.configFile."niri-mimeapps.list".text = ''
      [Default Applications]
      inode/directory=org.gnome.Nautilus.desktop
    '';

    home.activation.niriNoctaliaColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run touch ${config.xdg.configHome}/niri/noctalia.kdl
    '';
  };
}
