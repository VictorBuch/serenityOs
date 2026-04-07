{ mkModule, ... }:

mkModule {
  name = "audacity";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.audacity ];
  description = "Audacity audio editor";
}
