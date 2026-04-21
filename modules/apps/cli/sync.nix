args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "sync";
  category = "cli";
  description = "Fetch, rebuild, push-on-success wrapper for this flake";
  packages =
    { pkgs, ... }:
    [
      pkgs.jujutsu
      (pkgs.writeShellScriptBin "sync" ''
        # sync — fetch, rebuild, push-on-success for this flake.
        #
        #   sync
        #    │
        #    ├─ find_flake_root     cd up until flake.nix
        #    ├─ detect_host         hostname (strip .local on darwin)
        #    ├─ jj git fetch        fail → exit 1
        #    ├─ divergence_check
        #    │    ├─ equal          noop
        #    │    ├─ remote ahead   jj bookmark set main -r main@origin
        #    │    ├─ local ahead    noop
        #    │    └─ diverged       exit 1 + rebase hint
        #    ├─ rebuild             sudo {nixos,darwin}-rebuild switch --flake .#HOST
        #    │    └─ exit != 0      exit 1
        #    └─ push
        #         ├─ @- ahead of main   print hint, exit 0 (no push)
        #         ├─ push ok            exit 0
        #         └─ push fail          WARN, exit 2

        set -euo pipefail

        die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
        warn() { printf 'WARN:  %s\n' "$*" >&2; }
        info() { printf '==> %s\n' "$*"; }

        find_flake_root() {
          local d
          d=$(pwd)
          while [ "$d" != "/" ]; do
            if [ -f "$d/flake.nix" ]; then
              printf '%s\n' "$d"
              return 0
            fi
            d=$(dirname "$d")
          done
          return 1
        }

        detect_host() {
          local h
          h=$(hostname)
          # darwin's `hostname` may return FQDN like "inara.local"
          h=''${h%.local}
          printf '%s\n' "$h"
        }

        # Count revisions in a revset. Returns 0 if revset is empty or errors.
        count_revset() {
          jj log -r "$1" --no-graph -T 'change_id ++ "\n"' 2>/dev/null \
            | grep -c . \
            || true
        }

        main() {
          local root host
          root=$(find_flake_root) || die "no flake.nix found walking up from $(pwd)"
          cd "$root"
          host=''${1:-$(detect_host)}

          info "flake root: $root"
          info "host:       $host"

          # Bail early if main bookmark doesn't exist.
          jj log -r "main" --no-graph -T "" >/dev/null 2>&1 \
            || die "no 'main' bookmark exists locally. Run: jj bookmark create main -r @-"

          info "jj git fetch"
          jj git fetch || die "fetch failed (network? auth?)"

          # Divergence detection using revset math.
          local remote_ahead local_ahead
          remote_ahead=$(count_revset "main..main@origin")
          local_ahead=$(count_revset "main@origin..main")

          if [ "$remote_ahead" -gt 0 ] && [ "$local_ahead" -gt 0 ]; then
            die "main diverged from origin ($local_ahead local, $remote_ahead remote). Resolve: jj rebase -b main -d main@origin"
          elif [ "$remote_ahead" -gt 0 ]; then
            info "fast-forwarding main bookmark ($remote_ahead commits)"
            jj bookmark set main -r "main@origin"
          elif [ "$local_ahead" -gt 0 ]; then
            info "local main ahead of origin ($local_ahead commits)"
          else
            info "main bookmark in sync with origin"
          fi

          info "rebuilding: $host"
          if [ "$(uname)" = "Darwin" ]; then
            sudo darwin-rebuild switch --flake ".#$host" \
              || die "darwin-rebuild failed — no push"
          else
            sudo nixos-rebuild switch --flake ".#$host" \
              || die "nixos-rebuild failed — no push"
          fi

          # Push gate: if @- is ahead of main bookmark, user forgot to mark their work.
          local parent_ahead
          parent_ahead=$(count_revset "main..@-")
          if [ "$parent_ahead" -gt 0 ]; then
            warn "main bookmark behind @- by $parent_ahead commit(s)"
            warn "hint: mark your work for push: jj bookmark move main --to @-   (then re-run sync)"
            info "rebuild done, nothing pushed"
            exit 0
          fi

          info "jj git push"
          if ! jj git push; then
            warn "rebuild succeeded but push failed. This host is now ahead of remote."
            warn "fix auth/network then retry: jj git push"
            exit 2
          fi

          info "done"
        }

        main "$@"
      '')
    ];
} args
