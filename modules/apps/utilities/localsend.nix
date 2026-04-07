{ mkModule, ... }:

mkModule {
  name = "localsend";
  category = "utilities";
  linuxPackages = _: [ ];
  darwinPackages = { pkgs, ... }: [ pkgs.localsend ];
  linuxExtraConfig = {
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
  description = "LocalSend - share files locally";
}
