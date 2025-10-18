{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    nvidia.enable = lib.mkEnableOption "Enable Nvidia GPU driver support";
  };

  config = lib.mkIf config.nvidia.enable {
    hardware.graphics = {
      enable = true;
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

  };
}
