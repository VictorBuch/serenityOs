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
- [ ] Migrate auth to Authentik (single user store for friends)
  Pangolin is an OIDC *consumer* only — its users just gate the proxy, they
  can't log into apps. Pocket ID is passkey-only, so it stays admin-only:
  non-technical friends will not enrol a passkey.

  Authentik gives one username+password per person, plus an LDAP outpost —
  and LDAP is the only thing that makes Jellyfin work on native TV clients
  (Android TV / Roku / Infuse can't run any browser redirect flow, so OIDC
  alone never fixes them). Collapses the per-user-per-app credentials
  currently kept in Bitwarden.

  - Not in nixpkgs: needs `nix-community/authentik-nix` flake + postgres +
    redis + worker (~1.5 GB RAM).
  - Wire as: Authentik → Pangolin IdP (replaces Pocket ID), → OIDC for
    immich / paperless / gitea / mealie / nextcloud / audiobookshelf,
    → LDAP outpost for Jellyfin (ldapauth plugin).
  - No SMTP configured anywhere in the repo yet — without it there are no
    invite mails and no self-service password reset; passwords get set by
    hand in the Authentik UI.
  - Stale `authelia/*` keys in `secrets/secrets.yaml` are leftovers, delete.
  - Do this AFTER the Pangolin cutover finishes (PANGOLIN_CUTOVER.md Phase 7
    cleanup still pending) — don't stack two auth migrations.
