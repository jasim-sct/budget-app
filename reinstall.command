#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Budget Lite — one-click reinstall.
# Rebuilds, re-signs (fresh 7-day certificate), and installs to any connected
# iPhone. Double-click this file in Finder, or run it from a scheduled job.
#
# Requirements each run:
#   • iPhone connected (USB cable, or same Wi-Fi) AND UNLOCKED
#   • This Mac powered on with Xcode available
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

PROJECT="/Users/mac/JS/budget-app"
FLUTTER="/Users/mac/development/flutter/bin/flutter"
LOG="$PROJECT/reinstall.log"

# Known device UDIDs (add more with: xcrun devicectl list devices)
DEVICES=(
  "00008150-00091D962E7B401C"   # iPhone 17 (wired)
  "00008120-00110D2422E2601E"   # Parthiban's iPhone 15 (wireless)
)

stamp() { date "+%Y-%m-%d %H:%M:%S"; }
say()   { echo "[$(stamp)] $*" | tee -a "$LOG"; }

say "──────────────────────────────────────────────"
say "Budget Lite reinstall starting."
cd "$PROJECT" || { say "ERROR: project folder not found."; exit 1; }

say "Building release (fresh signature)…"
if ! "$FLUTTER" build ios --release --no-tree-shake-icons >>"$LOG" 2>&1; then
  say "ERROR: build failed — see $LOG"
  echo; read -r -p "Build failed. Press Return to close." _ 2>/dev/null || true
  exit 1
fi
say "Build OK."

APP="$PROJECT/build/ios/iphoneos/Runner.app"
installed_any=0

for udid in "${DEVICES[@]}"; do
  # Only attempt devices that are actually connected right now.
  if xcrun devicectl list devices 2>/dev/null | grep -q "$udid"; then
    say "Installing to $udid …"
    if xcrun devicectl device install app --device "$udid" "$APP" >>"$LOG" 2>&1; then
      say "✓ Installed to $udid — fresh 7-day clock."
      installed_any=1
    else
      say "✗ Install to $udid failed (phone locked? re-trust needed?). See $LOG"
    fi
  fi
done

if [ "$installed_any" -eq 0 ]; then
  say "No connected/unlocked iPhone found. Connect + unlock, then run again."
fi

say "Done."
echo
# Keep the Terminal window open when double-clicked from Finder.
read -r -p "Press Return to close this window." _ 2>/dev/null || true
