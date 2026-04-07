{ mkModule, ... }:

mkModule {
  name = "zed";
  category = "development";
  packages = { pkgs, ... }: [ pkgs.zed-editor ];
  description = "zed-editor";
}
