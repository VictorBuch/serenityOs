# TODO

- [x] Easier live update dotfiles for Jayne
- [x] Icons, file managers and other services seem very scattered and not very unified. Lets fix that for Jayne
- [x] Install / configure crowd sec on wash
- [x] Copyparty instead of nextcloud, i just need a simple file upload/download ui like a NAS service
- [x] try <https://github.com/liixini/skwd-wall> for nice wallpapers
- [x] find more wallpapers
- [x] try to implement self expiring overrides <https://jezenthomas.com/2026/07/nix-overrides-that-expire-themselves/>
- [ ] Migrate auth to Authentik (single user store for friends)
      Pangolin is an OIDC _consumer_ only — its users just gate the proxy, they
      can't log into apps. Pocket ID is passkey-only, so it stays admin-only:
      non-technical friends will not enrol a passkey.

  Authentik gives one username+password per person, plus an LDAP outpost —
  and LDAP is the only thing that makes Jellyfin work on native TV clients
  (Android TV / Roku / Infuse can't run any browser redirect flow, so OIDC
  alone never fixes them). Collapses the per-user-per-app credentials
  currently kept in Bitwarden.
