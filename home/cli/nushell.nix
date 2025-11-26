args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  isLinux,
  ...
}:

let
  aliases = {
    v = "sudo nvim ";
    vi = "sudo nvim ";
    lg = "lazygit";
    n = "nvim ~/serenityOs/ ";
    y = "yazi";
    s = "sesh connect (sesh list --icons | fzf --ansi)";
  };
in

mkHomeModule {
  _file = toString ./.;
  name = "nushell";
  description = "Nushell modern shell";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      isLinux,
      ...
    }:
    {
      home.packages = with pkgs; [
        nushell
        figlet
        lolcat
      ];
      programs = {

        nushell = {
          enable = true;
          shellAliases = aliases;

          # Set up Nix environment for Darwin (nushell doesn't auto-source /etc/bashrc)
          # On NixOS, the system handles PATH correctly including /run/wrappers/bin
          envFile.text = lib.optionalString (!isLinux) ''
            # Add Nix paths to PATH
            $env.PATH = ($env.PATH | split row (char esep) | prepend [
              "${config.home.homeDirectory}/.nix-profile/bin"
              "/etc/profiles/per-user/${config.home.username}/bin"
              "/run/current-system/sw/bin"
              "/nix/var/nix/profiles/default/bin"
              "/opt/homebrew/bin"
            ])

            # Nix environment variables
            $env.NIX_PATH = "nixpkgs=flake:nixpkgs"
            $env.NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"
          '';

          settings = {
            show_banner = false;
            completions.external = {
              enable = true;
              max_results = 200;
            };
          };
          extraConfig = ''
            figlet -f slant -tk ${config.home.username} | lolcat -p 3
          '';
        };

        zoxide = {
          enable = true;
          enableNushellIntegration = true;
        };

        direnv = {
          enable = true;
          enableNushellIntegration = true;
          nix-direnv.enable = true;
          stdlib = ''
            # Source devenv's direnvrc for use_devenv function
            source <(${pkgs.devenv}/bin/devenv direnvrc)
          '';
        };
      };
    };
} args
