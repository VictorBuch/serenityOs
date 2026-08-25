# Pangolin cutover runbook

Replaces Cloudflare Tunnels + TinyAuth with self-hosted Pangolin on `wash`
(Netcup VPS). Cloudflare stays as plain DNS. Pocket ID stays as OIDC IdP.
Caddy stays as internal vhost router on mal (LAN path + PHP-FPM/static/hermes).

Everything in the repo is already prepared:

- `hosts/wash/` — VPS host running `services.pangolin` (+ Traefik + gerbil)
- `secrets/vps.yaml` — wash-only vault, complete (server secret + CF token)
- `modules/homelab/services/newt.nix` — `homelab.newt` (enabled on mal, needs secrets)
- `modules/homelab/services/caddy.nix` — reworked: LE wildcard certs via
  ACME DNS-01 (no more CF origin certs), TinyAuth forward_auth removed
- `modules/homelab/services/adguard.nix` — LAN rewrites (wash IP set)

The wash age private key is at `~/.config/sops/age/wash.key` on inara
(public key already in `.sops.yaml`). Keep it until the install is done.

---

## Phase 0 — Cloudflare API token ✅ DONE (2026-08-10)

Existing `cloudflare/api_token` verified via `scripts/check-cf-token.sh`:
DNS:Edit works on both zones; token copied into `secrets/vps.yaml`.
(Script + this note deletable after cutover.)

## Phase 1 — Order VPS + install

1. Order **Netcup VPS 500 G12** (x86_64). Note the public IPv4 → `89.58.12.15`.
2. Cloudflare DNS: add **unproxied** (grey cloud) A record
   `pangolin.victorbuch.com → 89.58.12.15`.
3. Netcup SCP: boot the **rescue system**, note root password, confirm disk:
   `lsblk` → if the disk is `/dev/vda` (not `/dev/sda`), edit `hosts/wash/disko.nix`.
4. Stage the age key and install from this repo:

```sh
mkdir -p /tmp/wash-extra-files/var/lib/sops-nix
cp ~/.config/sops/age/wash.key /tmp/wash-extra-files/var/lib/sops-nix/key.txt
chmod 600 /tmp/wash-extra-files/var/lib/sops-nix/key.txt

nix run github:nix-community/nixos-anywhere -- \
  --flake .#wash \
  --generate-hardware-config nixos-generate-config hosts/wash/hardware-configuration.nix \
  --extra-files /tmp/wash-extra-files \
  root@89.58.12.15
```

1. Commit the regenerated `hosts/wash/hardware-configuration.nix`; delete
   `/tmp/wash-extra-files`.
2. Verify: `ssh wash@89.58.12.15`, then
   `systemctl status pangolin gerbil traefik`, `ss -ulpn | grep 51820`.
3. Browse `https://pangolin.victorbuch.com` → complete initial setup
   (create the server-admin account). Cert must be a valid LE wildcard.

## Phase 2 — Connect mal

1. Pangolin UI: create org → create **Site** "mal" (type: Newt). Copy the
   generated Newt ID + secret.
2. `sops secrets/secrets.yaml` → add:

   ```yaml
   pangolin:
     newt_id: <id>
     newt_secret: <secret>
   ```

3. On mal: `sudo nixos-rebuild switch --flake .#mal`
   (this rebuild also applies the Caddy rework: LE wildcard certs get issued
   via DNS-01, TinyAuth gate disappears from Caddy — see coexistence note below)
4. Verify: site "mal" shows **online** in Pangolin UI; `journalctl -u newt -f`.

⚠️ **Coexistence window**: after this rebuild the CF tunnel serves the
formerly TinyAuth-protected apps **without any auth screen** until the
Pangolin resources exist and DNS is flipped. Do Phases 2–5 in one evening.

## Phase 3 — Pocket ID IdP + first resources (Pangolin UI)

1. Pocket ID (`https://id.victorbuch.com`) → create OIDC client "Pangolin"
   (placeholder callback for now). Copy client id + secret.
2. Pangolin UI → Server Admin → Identity Providers → Add OAuth2/OIDC:
   - Auth URL: `https://id.victorbuch.com/authorize`
   - Token URL: `https://id.victorbuch.com/api/oidc/token`
   - Scopes: `openid profile email`, identifier path: `preferred_username`
   - If the page is license-gated: request the free personal EE key from
     Fossorial (fossorial.io), enter under Server Admin → License.
3. Paste Pangolin's generated callback URL back into the Pocket ID client.
4. Create resource `id.victorbuch.com` → target `localhost:443`, method
   https, site mal — **no auth** (it is the IdP; gating it deadlocks login).
5. Create test resource `status.victorbuch.com` (same target, **SSO on**).
   Cloudflare DNS: specific unproxied A `status.victorbuch.com → 89.58.12.15`
   (specific record beats the wildcard still pointing at the tunnel).
6. From **mobile data**: `https://status.victorbuch.com` → Pangolin auth
   screen → Pocket ID passkey → Uptime Kuma.

## Phase 4 — LAN path

1. Wash IP already set in `modules/homelab/services/adguard.nix` — this
   applies with the Phase 2 rebuild.
2. AdGuard runs with `mutableSettings = true`, which *merges* the declarative
   rewrites into the state file on every start — no UI step needed, but the
   merge also overwrites whatever the UI holds. Each rewrite must carry
   `enabled = true;`; without it AdGuard stores the rewrite disabled and
   ignores it (this is what silently broke the LAN path after cutover).
   - `*.victorbuch.com` → `192.168.0.243`
   - `pangolin.victorbuch.com` → `89.58.12.15`
3. Verify on LAN: `dig @192.168.0.243 photos.victorbuch.com` → `192.168.0.243`;
   browser gets valid LE cert from Caddy, no auth screen, apps load
   (immich, paperless, hermes agent, nextcloud).

## Phase 5 — Full resource inventory (declarative, already in repo)

Resources are **generated from `modules/homelab/services/edge-services.nix`**
via the newt blueprint (`modules/homelab/services/newt.nix`) — the same list
that drives Caddy, so LAN path and tunnel path cannot drift. 39 resources,
all targeting `localhost:443` https on site "mal"; `protected = true` maps
to Pangolin's SSO auth screen.

They are pushed when newt connects (the Phase 2 rebuild). In this phase just
**verify in the Pangolin UI** that all 39 appear with the right auth flags,
and that they coexist cleanly with the two hand-made Phase 3 resources
(`id`, `status`) — delete the hand-made ones if the blueprint duplicated them.

Adding a service later: one entry in edge-services.nix, rebuild mal. Done —
both paths.

Not recreated: `auth.victorbuch.com` (TinyAuth is gone).

## Phase 6 — DNS flip + retire tunnel

1. Cloudflare DNS (TTL 300, keep old values noted for rollback):
   - `*.victorbuch.com`: tunnel CNAME → **unproxied A** `89.58.12.15`
   - `*.smoothless.org`: tunnel CNAME → **unproxied A** `89.58.12.15`
2. `hosts/mal/configuration.nix`:
   - `cloudflare-tunnel.enable = false;`
   - delete the `tinyauth = { ... };` block
3. Rebuild mal.
4. **Rollback if needed**: flip both wildcard records back to the tunnel
   CNAME, set `cloudflare-tunnel.enable = true`, rebuild mal.

### Verification (from mobile data, NOT LAN/Tailscale)

- **Immich app: upload one video > 150 MB — the whole point of this migration**
- HA companion app connects; Jellyfin + Plex stream
- Nextcloud sync + one >1 GB upload (WebDAV through tunnel)
- git clone/push via git.victorbuch.com; ntfy push arrives
- SSO resources: auth screen exactly once, session spans resources
- Pocket ID passkey login end-to-end
- Websockets: hermes chat, HA, crafty console
- wannashare + suboptimal load

## Phase 7 — Cleanup (after ~1 week stable) NEXT STEP

- Delete `modules/homelab/services/cloudflare-tunnels.nix` and
  `modules/homelab/oci-containers/tinyauth.nix`
- `hosts/mal/configuration.nix`: remove `cloudflared-credentials` sops
  template + `cloudflare/tunnel/*` secret declarations
- `sops secrets/secrets.yaml`: delete `cloudflare/tunnel/*`, `tinyauth/*`,
  `cloudflare/ssl/*`, `cloudflare/wannashare/ssl/*`
- Cloudflare dashboard: delete the tunnel object
- Pocket ID: delete the TinyAuth OIDC client
- Delete this file
