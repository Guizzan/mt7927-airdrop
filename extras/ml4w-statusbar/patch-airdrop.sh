#!/usr/bin/env bash
# Adds the AirDrop module (AirDropModule.qml) to ML4W's statusbar: copies the
# QML next to StatusbarWindow.qml and registers "airdrop" in it. Idempotent.
# ML4W updates overwrite the bar, so the installer's user post.sh re-runs this:
#   ~/.config/ml4w-dotfiles-installer/com.ml4w.dotfiles/post.sh
# Usage: patch-airdrop.sh [path/to/StatusbarWindow.qml]

f="${1:-$HOME/.config/quickshell/StatusbarApp/StatusbarWindow.qml}"
[ -f "$f" ] || { echo "patch-airdrop: $f not found" >&2; exit 1; }
cp "$HOME/.config/ml4w-statusbar/AirDropModule.qml" "$(dirname "$f")/AirDropModule.qml"
grep -q 'CUSTOM-AIRDROP-MODULE' "$f" && { echo "patch-airdrop: already patched"; exit 0; }

anchor_comp='    Component { id: cPowerProfile; PowerProfileModule {} }'
anchor_map='        "powerprofile": cPowerProfile'
grep -qF "$anchor_comp" "$f" && grep -qF "$anchor_map" "$f" || {
    echo "patch-airdrop: anchors not found in $f (upstream changed?)" >&2; exit 1; }

python3 -I - "$f" "$anchor_comp" "$anchor_map" <<'PY'
import sys
path, anchor_comp, anchor_map = sys.argv[1:4]
src = open(path).read()
src = src.replace(anchor_comp, anchor_comp + '''
    // CUSTOM-AIRDROP-MODULE (patch-airdrop.sh)
    Component { id: cAirdrop; AirDropModule {} }''', 1)
src = src.replace(anchor_map, anchor_map + ''',
        "airdrop":      cAirdrop''', 1)
open(path, 'w').write(src)
PY
echo "patch-airdrop: patched $f"
