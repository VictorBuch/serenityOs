# TODO

- [x] Easier live update dotfiles for Jayne
- [x] Icons, file managers and other services seem very scattered and not very unified. Lets fix that for Jayne
- [ ] Install / configure crowd sec on wash
  - Installed and running (agent + LAPI + CAPI + firewall bouncer). Remaining: the allowlist.
- [ ] Give Claude the public IP I browse and SSH from, so crowdsec can allowlist it.
  Get it with `curl -4 -sS ifconfig.me`, then paste this prompt:

  > Allowlist <IP> in crowdsec on wash. Add an `s02Enrich` parser whitelist in
  > `hosts/wash/configuration.nix` for locally generated alerts, and a `cscli
  > allowlists` entry for decisions pulled from the CAPI community blocklist —
  > a parser whitelist cannot override those. Home is CGNAT (T-Mobile CZ) so the
  > address moves and is shared with strangers: prefer the enclosing ISP range
  > over the single address.

  Why this matters: the firewall bouncer drops banned addresses in the INPUT
  chain on every port, not just 80/443. If `crowdsecurity/base-http-scenarios`
  flags your own address (http-probing fires on a handful of 404s), you lose
  SSH to wash at the same moment, and recovery is the netcup VNC console.
  Until it is in place, do not test the edge by curling nonexistent paths.
- [ ] Copyparty instead of nextcloud, i just need a simple file upload/download ui like a NAS service
- [x] try <https://github.com/liixini/skwd-wall> for nice wallpapers
- [x] find more wallpapers
- [x] try to implement self expiring overrides <https://jezenthomas.com/2026/07/nix-overrides-that-expire-themselves/>
