{ mkModule, ... }:

mkModule {
  name = "blender";
  category = "media";
  packages = { pkgs, ... }: [ pkgs.blender ];
  description = "Blender 3D modeling";
}
