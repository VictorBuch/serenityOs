args@{ config, pkgs, lib, mkModule, ... }:

let
  aliases = {
    v = "sudo nvim ";
    vi = "sudo nvim ";
    lg = "lazygit";
    n = "nvim ~/serenityOs/ ";
    y = "yazi";
    s = "sesh connect (sesh list --icons | fzf --ansi)";
    nr = "pnpm run ";
    nrd = "pnpm run dev";
    ni = "pnpm install";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
    nfu = "nix flake update";
    oc = "opencode";
    # Condition ~/Videos/convert_queue for DaVinci Resolve Studio. Takes
    # optional file arguments; with none it drains the queue folder.
    dvc = "davinci-convert";
  };
in

mkModule {
  name = "nushell";
  category = "cli";
  description = "Nushell modern shell";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      isLinux = pkgs.stdenv.hostPlatform.isLinux;
    in
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
          environmentVariables = {
            EDITOR = "nvim";
          };
          extraEnv = "	  ";

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
            figlet -tk ${config.home.username} | lolcat -p 3

            # Two Claude Code instances with separate accounts/config dirs.
            # CLAUDE_CONFIG_DIR isolates auth + settings per instance.
            # claudep = personal account, claudew = work account.
            def --wrapped ccp [...args] {
              with-env { CLAUDE_CONFIG_DIR: ($env.HOME | path join ".claude-personal") } {
                claude ...$args
              }
            }
            def --wrapped ccw [...args] {
              with-env { CLAUDE_CONFIG_DIR: ($env.HOME | path join ".claude-work") } {
                claude ...$args
              }
            }
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
