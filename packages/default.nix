{ pkgs }:
{
  pam = pkgs.callPackage ./pam { };
  lute-v3 = pkgs.callPackage ./lute-v3 { };
}
