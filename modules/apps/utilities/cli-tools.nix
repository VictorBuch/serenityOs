args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "cli-tools";
  packages = pkgs: [
    # pkgs.pam-cli  # Temporarily disabled - requires network to build Go modules
  ];
  description = "Command-line development and management tools";
} args
