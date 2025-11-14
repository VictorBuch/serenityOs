{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    maintenance.enable = lib.mkEnableOption "Enable homelab maintenance (GC, auto-upgrade, optimization, boot cleanup)";
  };

  config = lib.mkIf config.maintenance.enable {

    # Automatic Garbage collection cleanup
    # Serenity uses 10-day retention instead of the default 30 days
    nix.gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "30min";
      persistent = true;
      options = "--delete-older-than 10d";
    };

    # Automatic system updates with flake lockfile commits
    system.autoUpgrade = {
      enable = true;
      dates = "02:00";
      randomizedDelaySec = "45min";
      persistent = true;
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "--commit-lock-file"
        "-L" # print build logs
      ];
    };

    # Automatic Nix store optimization (deduplication via hardlinking)
    nix.optimise = {
      automatic = true;
      dates = [ "weekly" ];
      randomizedDelaySec = "45min";
      persistent = true;
    };

    # Limit boot generations to prevent /boot from filling up
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
    boot.loader.grub.configurationLimit = lib.mkDefault 5;

  };
}
