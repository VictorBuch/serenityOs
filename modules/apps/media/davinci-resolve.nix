let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.davinci-resolve-studio ];
    };
in
{
  flake.modules.nixos.davinci-resolve = module;
  flake.modules.darwin.davinci-resolve = module;
  flake.modules.homeManager.davinci-resolve =
    { pkgs, lib, ... }:
    let
      licenseFile = pkgs.writeText "blackmagic.lic" ''
        LICENSE blackmagic davinciresolvestudio 999999 permanent uncounted
        hostid=ANY issuer=CGP customer=CGP issued=28-dec-2023
        akey=0000-0000-0000-0000 _ck=00 sig="00"
      '';
    in
    {
      home.desktop.common.davinci-convert.enable = lib.mkDefault true;

      home.activation.davinciResolveLicense = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -Dm600 ${licenseFile} "$HOME/.local/share/DaVinciResolve/license/blackmagic.lic"
      '';
    };
}
