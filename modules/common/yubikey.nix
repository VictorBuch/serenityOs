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

  config = lib.mkIf config.yubikey.enable (
    lib.mkMerge (
      [
        {
          environment.systemPackages = with pkgs; [
            yubikey-manager # ykman CLI
            yubikey-personalization # ykinfo / yubico-piv-tool
            age-plugin-yubikey # age encryption backed by YubiKey PIV
            pam_u2f # pamu2fcfg registration tool
          ];
        }
      ]
      ++ lib.optionals isLinux [
        # Linux-only: udev rules for YubiKey hotplug
        {
          services.udev.packages = [
            pkgs.yubikey-personalization
            pkgs.libu2f-host
          ];
        }
        # Linux-only: smart card daemon
        { services.pcscd.enable = true; }
        # Linux-only: GPG agent (not needed for FIDO2 SSH, but useful for GPG ops)
        {
          programs.gnupg.agent = {
            enable = true;
            enableSSHSupport = false; # We use FIDO2 SSH keys directly, not GPG agent
          };
        }
      ]
    )
  );
}
