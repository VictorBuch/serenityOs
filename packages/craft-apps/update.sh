#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
# Pins every craft app to its latest GitHub release: ./packages/craft-apps/update.sh
set -euo pipefail

cd "$(dirname "$0")"
apps=(photocraft filmcraft lightcraft pdfcraft figcraft vectorcraft effectcraft)

out='{}'
for app in "${apps[@]}"; do
  release=$(curl -fsSL "https://api.github.com/repos/storytold/$app/releases/latest")
  version=$(jq -r '.tag_name | ltrimstr("v")' <<<"$release")
  asset=$(jq -e --arg n "$app-$version-linux-x86_64.tar.gz" '.assets[] | select(.name == $n)' <<<"$release")
  assetId=$(jq -r .id <<<"$asset")
  hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r '.digest | ltrimstr("sha256:")' <<<"$asset")")
  old=$(jq -r --arg a "$app" '.[$a].version // "none"' sources.json 2>/dev/null || echo none)
  [[ $old != "$version" ]] && echo "$app $old -> $version"
  out=$(jq --arg a "$app" --arg v "$version" --argjson i "$assetId" --arg h "$hash" '.[$a] = {version: $v, assetId: $i, hash: $h}' <<<"$out")
done

echo "$out" >sources.json
