{
  config,
  pkgs,
  lib,
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

{
  options = {
    home.cli.nushell.enable = lib.mkEnableOption "Enables nushell home manager";
  };

  config = lib.mkIf config.home.cli.nushell.enable {
    home.packages = with pkgs; [
      nushell
    ];

    programs.nushell = {
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

    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
