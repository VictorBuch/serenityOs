# adopt-jj-workspaces — register orphan jj workspaces as native herdr workspaces.
#
# Scans $JJ_WS_ROOT/<repo>/<name> for jj workspaces that herdr doesn't know about
# (e.g. created by an agent running raw `jj workspace add`) and registers each one
# via `herdr workspace create --cwd <dir>`. Bound to `prefix+shift+j` (popup) in
# herdr.nix; also runnable directly whenever the sidebar looks out of sync.

root="${JJ_WS_ROOT:-$HOME/.herdr/worktrees}"
if [ ! -d "$root" ]; then
	echo "adopt: root $root does not exist, nothing to do"
	exit 0
fi

known="$(herdr workspace list 2>/dev/null || true)"
count=0

# Match <root>/<repo>/<name>/ directories that are real jj workspaces.
for d in "$root"/*/*/; do
	[ -d "$d" ] || continue
	[ -e "${d}.jj" ] || continue # `.jj` marker => a real jj workspace
	name="$(basename "$d")"
	# Skip if herdr already lists a workspace with this label.
	case "$known" in
	*"$name"*) continue ;;
	esac
	abs="$(cd "$d" && pwd)"
	herdr workspace create --cwd "$abs" --label "$name"
	count=$((count + 1))
	echo "adopted: $name ($abs)"
done

if [ "$count" -eq 0 ]; then
	echo "adopt: nothing new to register"
fi
