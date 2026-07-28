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

  # xdg-desktop-portal-wlr 0.8.3 stalls screencasts after the first frame: sharing a
  # screen shows a frozen still, sharing a window stays black. Upstream's own 0.8.3
  # release notes say "This version will sometimes stall screen recording. Please wait
  # for the next patch release before upgrading."
  #
  # 0.8.3 contains exactly one functional commit, c613a8b "screencast: drive the
  # Pipewire graph by ourselves", which is the regression. Traced on jayne/mango as:
  # one frame exported, then `pipewire: out of buffers` / `unable to export buffer`
  # and no further capture. Not compositor-specific — grim and wf-recorder are fine
  # because they use wlr-screencopy, while the portal takes the ext-image-copy-capture
  # path that 0.8.3 broke, and there is no config switch between the two.
  #
  # Pin to v0.8.2, the last release before that commit. It still carries 896cee8
  # "Fix screensharing on pipewire 1.6.x", which we need (system runs PipeWire 1.6.8).
  # master (544e114) only adds a guard on top of the regression instead of reverting
  # it, so it is not a safe target yet.
  #
  # Drop this once nixpkgs ships the upstream patch release that fixes the stall.
  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (_old: {
    version = "0.8.2";
    src = final.fetchFromGitHub {
      owner = "emersion";
      repo = "xdg-desktop-portal-wlr";
      rev = "01171a150b705cf07066ebc0fb7e1ff537027bec";
      hash = "sha256-HITf/hgiASWvn/z49mzS8IS1vuyXwdk1JiAOOHRSQMo=";
    };
  });

  # music-assistant 2.8.4 airplay/chromecast providers import sendspin_bridge,
  # which requires aiosendspin. Upstream nixpkgs provider deps map omits it.
  # Preserve .override interface (NixOS module calls cfg.package.override { providers = ... }),
  # and inject aiosendspin after each override.
  music-assistant =
    let
      base = prev.music-assistant;
      injectDep = drv: drv.overrideAttrs (old: {
        propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
          final.python313Packages.aiosendspin
        ];
      });
    in
    (injectDep base) // {
      override = args: injectDep (base.override args);
    };
}
