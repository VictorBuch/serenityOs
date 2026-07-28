args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "davinci-resolve";
  category = "media";
  packages = { pkgs, ... }: [ pkgs.davinci-resolve-studio ];
  description = "DaVinci Resolve video editor";

  homeConfig =
    { pkgs, lib, ... }:
    let
      licenseFile = pkgs.writeText "blackmagic.lic" ''
        LICENSE blackmagic davinciresolvestudio 999999 permanent uncounted
        hostid=ANY issuer=CGP customer=CGP issued=28-dec-2023
        akey=0000-0000-0000-0000 _ck=00 sig="00"
      '';
    in
    {
      home.activation.davinciResolveLicense = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -Dm600 ${licenseFile} "$HOME/.local/share/DaVinciResolve/license/blackmagic.lic"
      '';
    };
} args
