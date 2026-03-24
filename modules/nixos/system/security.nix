# YubiKey security: PAM U2F sudo, screen lock on removal
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.yubikey-security.enable = lib.mkEnableOption "YubiKey PAM U2F and screen lock";

  config = lib.mkIf config.yubikey-security.enable {
    # PAM U2F -- touch YubiKey as a sufficient factor for sudo and login
    security.pam.u2f = {
      enable = true;
      control = "sufficient"; # Touch alone grants auth; password is fallback if key absent
      settings = {
        cue = true; # Print "Please touch your YubiKey" prompt
        origin = "pam://serenityOs";
        appid = "pam://serenityOs";
        authfile = "/etc/u2f-mappings";
      };
    };

    security.pam.services = {
      sudo.u2fAuth = true;
      login.u2fAuth = true;
      polkit-1.u2fAuth = true; # GUI privilege escalation dialogs
      hyprlock.u2fAuth = true; # Screen lock unlock
    };

    # Lock screen when any YubiKey is physically removed
    services.udev.extraRules = ''
      ACTION=="remove", \
      ENV{ID_BUS}=="usb", \
      ENV{ID_MODEL_ID}=="0407", \
      ENV{ID_VENDOR_ID}=="1050", \
      ENV{ID_VENDOR}=="Yubico", \
      RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };
}
