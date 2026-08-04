{
  inputs,
  ...
}:
final: prev: {
  # AI coding agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};

  # nixCats-style wrapped neovim. Module + lua live in modules/apps/neovim/_nixcats/.
  nixcatsNeovim =
    let
      module = final.lib.modules.importApply ../modules/apps/neovim/_nixcats/module.nix inputs;
      wrapper = inputs.nix-wrapper-modules.lib.evalModule module;
    in
    wrapper.config.wrap { pkgs = final; };

  # Herdr: mouse-first terminal multiplexer (flake ships only a package)
  herdr = inputs.herdr.packages.${final.stdenv.hostPlatform.system}.default;

  # Add the pam package (renamed to avoid conflict with linux-pam)
  pam-cli = final.callPackage ../packages/pam { };

  # Lute v3 - language learning web application
  lute-v3 = final.callPackage ../packages/lute-v3 { };

  # Wine 9.20 pinned for audio/yabridge compatibility
  # Wine 9.22+ has GUI issues with yabridge: https://github.com/robbert-vdh/yabridge/issues/382
  # Uses the nixpkgs-wine920 flake input with stagingFull for maximum Windows compatibility
  wine921 =
    let
      wine920Pkgs = import inputs.nixpkgs-wine920 {
        system = final.stdenv.hostPlatform.system;
        config = {
          allowUnfree = true;
        };
      };
    in
    wine920Pkgs.wineWowPackages.stagingFull;
}
