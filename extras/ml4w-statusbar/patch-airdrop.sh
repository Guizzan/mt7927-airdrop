#!/usr/bin/env bash
# Adds AirDrop to ML4W's statusbar: copies AirDropModule.qml next to
# StatusbarWindow.qml, registers the "airdrop" module, and keeps the bar
# revealed while the AirDrop panel is open (`qs ipc call airdropbar opened` /
# `closed`, sent by airdrop-app). Idempotent: each part has its own marker.
# ML4W updates overwrite the bar, so the installer's user post.sh re-runs this:
#   ~/.config/ml4w-dotfiles-installer/com.ml4w.dotfiles/post.sh
# Usage: patch-airdrop.sh [path/to/StatusbarWindow.qml]

f="${1:-$HOME/.config/quickshell/StatusbarApp/StatusbarWindow.qml}"
[ -f "$f" ] || { echo "patch-airdrop: $f not found" >&2; exit 1; }
cp "$HOME/.config/ml4w-statusbar/AirDropModule.qml" "$(dirname "$f")/AirDropModule.qml"

python3 -I - "$f" <<'PY'
import sys
path = sys.argv[1]
src = open(path).read()
done = []

def patch(marker, anchor, addition, before=False):
    global src
    if marker in src:
        return
    if src.count(anchor) != 1:
        sys.exit(f"patch-airdrop: anchor for {marker} not found (upstream changed?)")
    src = src.replace(anchor, (addition + anchor) if before else (anchor + addition), 1)
    done.append(marker)

# The module itself
patch("CUSTOM-AIRDROP-MODULE",
      "    Component { id: cPowerProfile; PowerProfileModule {} }",
      "\n    // CUSTOM-AIRDROP-MODULE (patch-airdrop.sh)\n    Component { id: cAirdrop; AirDropModule {} }")
patch("cAirdrop,", '        "powerprofile": cPowerProfile', ',\n        "airdrop":      cAirdrop')

# Stay revealed while the AirDrop panel is open
patch("CUSTOM-AIRDROP-REVEAL",
      "        || root.barExpanded || root.trayMenuOpen || root.calendarOpen",
      "\n        || root.airdropOpen // CUSTOM-AIRDROP-REVEAL (patch-airdrop.sh)")
patch("airdropbar",
      "    property bool pointerHeld: false\n",
      """
    // CUSTOM (patch-airdrop.sh): the AirDrop panel (airdrop-app) drops down
    // under the bar and keeps it revealed until it closes.
    property bool airdropOpen: false
    IpcHandler {
        target: "airdropbar"
        function opened(): void { root.airdropOpen = true }
        function closed(): void { root.airdropOpen = false }
    }
""")

open(path, "w").write(src)
print("patch-airdrop:", ("patched " + ", ".join(done)) if done else "already patched")
PY
