{ mkModule, ... }:

mkModule {
  name = "cli-tools";
  category = "utilities";
  packages = { pkgs, ... }: [
    pkgs.pam-cli
  ];
  description = "Command-line development and management tools";
}
