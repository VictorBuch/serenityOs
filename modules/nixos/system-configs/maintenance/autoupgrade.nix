{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    autoupgrade.enable = lib.mkEnableOption "Enable autoupgrade";
  };

  config = lib.mkIf config.autoupgrade.enable {

    system.autoUpgrade = {
      enable = true;
      dates = "02:00";
      randomizedDelaySec = "45min";
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "--commit-lock-file"
        "-L" # print build logs
      ];
    };

  };
}
