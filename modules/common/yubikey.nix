# YubiKey support -- cross-platform packages and Linux services
{
  config,
  pkgs,
  lib,
  isLinux ? false,
  ...
}:
{
  options.yubikey.enable = lib.mkEnableOption "YubiKey support";

  config = lib.mkIf config.yubikey.enable {
    environment.systemPackages = with pkgs; [
      yubikey-manager # ykman CLI
      yubikey-personalization # ykinfo / yubico-piv-tool
      age-plugin-yubikey # age encryption backed by YubiKey PIV
      pam_u2f # pamu2fcfg registration tool
    ];

    # Linux-only services
    services.udev.packages = lib.mkIf isLinux [
      pkgs.yubikey-personalization
      pkgs.libu2f-host
    ];

    services.pcscd.enable = lib.mkIf isLinux true;

    programs.gnupg.agent = lib.mkIf isLinux {
      enable = true;
      enableSSHSupport = false; # We use FIDO2 SSH keys directly, not GPG agent
    };
  };
}
