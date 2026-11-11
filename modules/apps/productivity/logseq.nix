{
  # Linux: nixpkgs logseq has broken plugin support
  # (Electron sandbox + /nix/store blocks plugin native modules / helpers).
  # Use Flathub build — runs in FHS, plugins work.
  # After first switch, run once:
  #   flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  #   flatpak install flathub com.logseq.Logseq
  flake.modules.nixos.logseq = {
    services.flatpak.enable = true;
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
    };
  };

  # macOS: use homebrew cask (nixpkgs build has recurring breakage).
  flake.modules.darwin.logseq.homebrew.casks = [ "logseq" ];
}
