{
  flake.modules.nixos.feedback =
    { pkgs, ... }:
    {
      # psarc2feedpak rides along: it converts Rocksmith songs into feedback's .feedpak format.
      environment.systemPackages = [
        pkgs.feedback-desktop
        pkgs.psarc2feedpak
      ];
    };
}
