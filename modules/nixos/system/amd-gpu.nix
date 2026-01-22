{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    amd-gpu.enable = lib.mkEnableOption "Enable AMD GPU driver support";
  };

  config = lib.mkIf config.amd-gpu.enable {
    boot.initrd.kernelModules = [ "amdgpu" ];

    # AMD GPU kernel parameters for performance
    boot.kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff" # Enable all power features
      "amdgpu.gpu_recovery=1" # Enable GPU recovery
    ];

    # Enable openGL
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        clinfo
      ];
    };

    services.xserver.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];

    # CPU performance governor for AMD systems
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  };
}
