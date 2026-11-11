{
  flake.modules.nixos.figma =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.figma-linux ];
    };
  flake.modules.darwin.figma.homebrew.casks = [ "figma" ];
}
