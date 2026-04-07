{ mkModule, ... }:

mkModule {
  name = "signal";
  category = "communication";
  packages = { pkgs, ... }: [ pkgs.signal-desktop ];
  description = "Private and secure messaging app";
}
