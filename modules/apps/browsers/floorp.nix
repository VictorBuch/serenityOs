{ mkModule, ... }:

mkModule {
  name = "floorp";
  category = "browsers";
  packages = { pkgs, ... }: [ pkgs.floorp ];
  description = "Floorp web browser";
}
