args@{
  mkModule,
  ...
}:

mkModule {
  name = "logseq";
  category = "productivity";
  description = "logseq note-taking app";

  # macOS: use homebrew cask (nixpkgs build has recurring breakage).
  casks = [ "logseq" ];

  # Linux: nixpkgs logseq has broken plugin support
  # (Electron sandbox + /nix/store blocks plugin native modules / helpers).
  # Use Flathub build — runs in FHS, plugins work.
  # After first switch, run once:
  #   flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  #   flatpak install flathub com.logseq.Logseq
  linuxPackages = { ... }: [ ]; # no system package; flatpak provides it
  linuxExtraConfig = {
    services.flatpak.enable = true;
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
    };
  };
} args
