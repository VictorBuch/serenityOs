{
  flake.modules.nixos.virtualbox =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.virtualbox ];
    };
}
