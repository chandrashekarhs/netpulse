#!/bin/bash
set -e

APP="NetPulse"
BUNDLE_ID="com.$(whoami).netpulse"
VERSION="1.2.1"
DMG="${APP}.dmg"
BINARY=".build/release/${APP}"

if [ ! -f "${BINARY}" ]; then
    echo "✗  Binary not found at ${BINARY}. Run 'make build' first."
    exit 1
fi

# ── 1. Generate app icon ──────────────────────────────────────────────────────
echo "→ Generating icon…"
swift Scripts/make_icon.swift
iconutil -c icns AppIcon.iconset -o AppIcon.icns
rm -rf AppIcon.iconset

# ── 2. Build .app bundle ──────────────────────────────────────────────────────
echo "→ Building .app bundle…"
CONTENTS="${APP}.app/Contents"
rm -rf "${APP}.app"
mkdir -p "${CONTENTS}/MacOS" "${CONTENTS}/Resources"

cp "${BINARY}"   "${CONTENTS}/MacOS/${APP}"
cp AppIcon.icns  "${CONTENTS}/Resources/"

cat > "${CONTENTS}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>              <string>${APP}</string>
  <key>CFBundleIdentifier</key>        <string>${BUNDLE_ID}</string>
  <key>CFBundleExecutable</key>        <string>${APP}</string>
  <key>CFBundleVersion</key>           <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundlePackageType</key>       <string>APPL</string>
  <key>LSMinimumSystemVersion</key>    <string>12.0</string>
  <key>NSHighResolutionCapable</key>   <true/>
  <key>CFBundleIconFile</key>          <string>AppIcon</string>
  <key>LSUIElement</key>               <true/>
</dict>
</plist>
PLIST

# ── 3. Code sign ──────────────────────────────────────────────────────────────
# Set DEVELOPER_ID env var for distribution signing, e.g.:
#   export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
# Leave unset for ad-hoc local builds (Gatekeeper warning on first launch).
if [ -n "${DEVELOPER_ID:-}" ]; then
    echo "→ Signing with Developer ID (hardened runtime)…"
    codesign --deep --force --options runtime \
        --entitlements Entitlements.plist \
        --sign "${DEVELOPER_ID}" \
        "${APP}.app"
else
    echo "→ Signing ad-hoc (local build — set DEVELOPER_ID for distribution)…"
    codesign --deep --force --sign - "${APP}.app"
fi

# ── 4. Create DMG ─────────────────────────────────────────────────────────────
echo "→ Creating DMG…"
rm -rf _dmg_stage "${DMG}"
mkdir _dmg_stage
cp -r "${APP}.app" _dmg_stage/
ln -s /Applications _dmg_stage/Applications

hdiutil create \
  -volname "${APP}" \
  -srcfolder _dmg_stage \
  -ov \
  -format UDZO \
  "${DMG}"

rm -rf _dmg_stage "${APP}.app" AppIcon.icns
echo ""
echo "✓  ${DMG} ready."
if [ -n "${DEVELOPER_ID:-}" ]; then
    echo "   Next: notarize with 'xcrun notarytool submit ${DMG} --wait' then 'xcrun stapler staple ${DMG}'."
else
    echo "   Ad-hoc build: users must right-click → Open on first launch."
fi
