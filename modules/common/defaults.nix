let
  shared =
    { lib, ... }:
    {
      time.timeZone = lib.mkDefault "Europe/Copenhagen";
      programs.zsh.enable = true;
      sops = {
        defaultSopsFile = lib.mkDefault ../../secrets/secrets.yaml;
        defaultSopsFormat = "yaml";
      };
    };
in
{
  flake.modules.darwin.base = shared;
  flake.modules.nixos.base = {
    imports = [ shared ];
    i18n.defaultLocale = "en_DK.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "da_DK.UTF-8";
      LC_IDENTIFICATION = "da_DK.UTF-8";
      LC_MEASUREMENT = "da_DK.UTF-8";
      LC_MONETARY = "da_DK.UTF-8";
      LC_NAME = "da_DK.UTF-8";
      LC_NUMERIC = "da_DK.UTF-8";
      LC_PAPER = "da_DK.UTF-8";
      LC_TELEPHONE = "da_DK.UTF-8";
      LC_TIME = "da_DK.UTF-8";
    };
    console.keyMap = "dk-latin1";
  };
}
