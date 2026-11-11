# TODO

- [ ] SMART tests on Mal - send summary to ntfy
- [ ] Migrate auth to Authentik (single user store for friends)
      Pangolin is an OIDC _consumer_ only — its users just gate the proxy, they
      can't log into apps. Pocket ID is passkey-only, so it stays admin-only:
      non-technical friends will not enrol a passkey.

  Authentik gives one username+password per person, plus an LDAP outpost —
  and LDAP is the only thing that makes Jellyfin work on native TV clients
  (Android TV / Roku / Infuse can't run any browser redirect flow, so OIDC
  alone never fixes them). Collapses the per-user-per-app credentials
  currently kept in Bitwarden.
