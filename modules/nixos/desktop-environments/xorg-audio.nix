{ config, lib, ... }:

# A lightweight Xorg session kept around purely as an escape hatch for plugin GUIs.
#
# Windows plugin editors are X11 windows that yabridge embeds into the DAW's window. Under
# Wayland that goes through XWayland, and the embedding is where the IK Multimedia GUIs
# tend to freeze or stop repainting (yabridge.nix works around it with editor_xembed). On
# a real X server the embedding is native and none of that applies.
#
# GNOME 50 dropped its Xorg session, so this cannot be "GNOME on X11" -- XFCE is the
# smallest thing that still ships one. SDDM (enabled by the Session module) picks the xsession up
# automatically; pick "Xfce" from the session menu at login.
{
  options.desktop.extraSessions.xorg-audio.enable = lib.mkEnableOption ''
    lightweight Xorg session for audio work (native X11 plugin embedding, no
    xwayland-satellite). Select "Xfce" at the SDDM session picker
  '';

  config = lib.mkIf config.desktop.extraSessions.xorg-audio.enable {
    # Already true when GNOME is enabled, but this session must not depend on that.
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;
  };
}
