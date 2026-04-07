{ mkModule, ... }:

mkModule {
  name = "zoom";
  category = "communication";
  packages = { pkgs, ... }: [ pkgs.zoom-us ];
  description = "Zoom video conferencing";
}
