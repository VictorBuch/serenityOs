{
  flake.modules.nixos.es-de =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.es-de ];
    };
}
