{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.corectrl.enable = lib.mkEnableOption "Enables CoreCtrl";
  };

  config = lib.mkIf config.apps.gaming.corectrl.enable {

    programs.corectrl.enable = true;

    hardware.amdgpu.overdrive = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
}
