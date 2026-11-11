{
  config,
  inputs,
  self,
  withSystem,
  ...
}:
let
  inherit (inputs) nixpkgs nix-darwin;

  mkHost =
    {
      name,
      class ? "nixos",
      system ? if class == "darwin" then "aarch64-darwin" else "x86_64-linux",
      hostConfig ? ../../hosts/${name}/configuration.nix,
      features ? [ ],
      extraModules ? [ ],
    }:
    let
      darwin = class == "darwin";
      builder = if darwin then nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
      inherit (config.flake) modules;
      feature =
        n:
        assert modules.${class} ? ${n} || modules.homeManager ? ${n} || throw "${name}: no feature ${n}";
        nixpkgs.lib.optional (modules.${class} ? ${n}) modules.${class}.${n}
        ++ nixpkgs.lib.optional (modules.homeManager ? ${n}) {
          home-manager.sharedModules = [ modules.homeManager.${n} ];
        };
    in
    withSystem system (
      { pkgs, pkgs-stable, ... }:
      builder {
        inherit system pkgs;
        modules = [
          modules.${class}.base
          { _module.args = { inherit inputs pkgs-stable; }; }
          { imports = nixpkgs.lib.concatMap feature features; }
          hostConfig
          (
            if darwin then
              inputs.home-manager.darwinModules.default
            else
              inputs.home-manager.nixosModules.default
          )
          (if darwin then inputs.sops-nix.darwinModules.sops else inputs.sops-nix.nixosModules.sops)
        ]
        ++ extraModules;
      }
    );

  hosts = [
    {
      name = "jayne";
      features = [
        "audacity"
        "decent-sampler"
        "easyeffects"
        "feedback"
        "mass"
        "reaper"
        "sone"
        "spotify"
        "vlc"
        "yabridge"
        "zen"
        "fzf"
        "git"
        "herdr"
        "jujutsu"
        "notes"
        "nushell"
        "opencode"
        "sesh"
        "starship"
        "zsh"
        "discord"
        "slack"
        "agent-browser"
        "claude"
        "common"
        "devenv-init"
        "docker"
        "android-studio"
        "vscode"
        "zed"
        "ghostty"
        "kitty"
        "neovim"
        "tmux"
        "bottles"
        "qemu"
        "eden"
        "gamemode"
        "heroic"
        "minecraft"
        "ps2"
        "ps3"
        "retroarch"
        "steam"
        "sunshine"
        "wine"
        "logitech"
        "blender"
        "craft-apps"
        "davinci-resolve"
        "ffmpeg"
        "fladder"
        "handbrake"
        "lazyvim"
        "calibre"
        "figma"
        "obsidian"
        "stylix"
        "cli-tools"
        "handy"
        "localsend"
        "syncthing"
        "system-tools"
        "sddm"
        "mango"
        "gnome"
        "niri"
        "hyprland"
        "kde"
        "networking"
        "nvidia-gpu"
        "user"
        "amd-gpu"
        "security"
        "envfs"
        "audio-performance"
      ];
    }
    {
      name = "mal";
      features = [
        "fzf"
        "git"
        "nushell"
        "sesh"
        "starship"
        "tmux"
        "user"
        "homelab"
        "homelab-facts"
      ];
      extraModules = [
        inputs.wannashare.nixosModules.default
        inputs.sparkyfitness.nixosModules.sparkyfitness
        inputs.tv-learn.nixosModules.tv-learn
      ];
    }
    {
      name = "wash";
      features = [
        "fzf"
        "git"
        "nushell"
        "starship"
        "user"
        "homelab-facts"
      ];
      extraModules = [
        inputs.disko.nixosModules.disko
      ];
    }
    {
      name = "inara";
      features = [
        "fzf"
        "git"
        "jujutsu"
        "notes"
        "nushell"
        "opencode"
        "sesh"
        "starship"
        "discord"
        "signal"
        "slack"
        "zoom"
        "claude"
        "common"
        "devenv-init"
        "android-studio"
        "vscode"
        "neovim"
        "tmux"
        "ffmpeg"
        "lazyvim"
        "logseq"
        "obsidian"
        "cli-tools"
        "localsend"
      ];
      class = "darwin";
    }
  ];

  hostsOfClass =
    class:
    builtins.listToAttrs (
      map (host: {
        inherit (host) name;
        value = mkHost host;
      }) (builtins.filter (host: (host.class or "nixos") == class) hosts)
    );
in
{
  flake = {
    nixosConfigurations = hostsOfClass "nixos";
    darwinConfigurations = hostsOfClass "darwin";

    checks.x86_64-linux.inara = withSystem "x86_64-linux" (
      { pkgs, ... }:
      pkgs.writeText "inara" (
        builtins.unsafeDiscardStringContext self.darwinConfigurations.inara.system.drvPath
      )
    );

    checks.x86_64-linux.shell-actions =
      self.nixosConfigurations.jayne.config.home-manager.users.jayne.home.desktop.shell.check;
  };
}
