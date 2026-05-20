#!/usr/bin/env bash
set -euo pipefail

APP_NAME="XCopy"
BUNDLE_ID="${XCOPY_BUNDLE_ID:-com.local.XCopy}"
MIN_SYSTEM_VERSION="14.0"
CODE_SIGN_IDENTITY="${XCOPY_CODESIGN_IDENTITY:-}"
NOTARY_APPLE_ID="${XCOPY_NOTARY_APPLE_ID:-}"
NOTARY_TEAM_ID="${XCOPY_NOTARY_TEAM_ID:-}"
NOTARY_PASSWORD="${XCOPY_NOTARY_PASSWORD:-}"
NOTARY_KEYCHAIN_PROFILE="${XCOPY_NOTARY_KEYCHAIN_PROFILE:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DMG_ROOT="$DIST_DIR/dmg-root"
APP_BUNDLE="$DMG_ROOT/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_FILE="$APP_RESOURCES/AppIcon.icns"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

if hdiutil info | /usr/bin/grep -F -q "image-path      : $DMG_PATH"; then
  echo "$DMG_PATH is currently mounted. Eject it before packaging." >&2
  exit 1
fi

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"

cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

swift "$ROOT_DIR/script/generate_app_icon.swift" "$ICON_FILE"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

ln -s /Applications "$DMG_ROOT/Applications"

if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
  echo "Signing $APP_NAME.app with $CODE_SIGN_IDENTITY..."
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$CODE_SIGN_IDENTITY" \
    "$APP_BUNDLE"
else
  echo "No XCOPY_CODESIGN_IDENTITY set; applying ad-hoc signature for local validation only."
  codesign \
    --force \
    --sign - \
    "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
  echo "Signing $APP_NAME.dmg with $CODE_SIGN_IDENTITY..."
  codesign \
    --force \
    --timestamp \
    --sign "$CODE_SIGN_IDENTITY" \
    "$DMG_PATH"
  codesign --verify --verbose=2 "$DMG_PATH"
fi

if [[ -n "$NOTARY_KEYCHAIN_PROFILE" || -n "$NOTARY_APPLE_ID" || -n "$NOTARY_TEAM_ID" || -n "$NOTARY_PASSWORD" ]]; then
  if [[ -z "$CODE_SIGN_IDENTITY" ]]; then
    echo "Notarization requires XCOPY_CODESIGN_IDENTITY." >&2
    exit 1
  fi

  echo "Submitting $APP_NAME.dmg for notarization..."
  if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
    xcrun notarytool submit "$DMG_PATH" \
      --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
      --no-s3-acceleration \
      --timeout 10m \
      --wait
  else
    if [[ -z "$NOTARY_APPLE_ID" || -z "$NOTARY_TEAM_ID" || -z "$NOTARY_PASSWORD" ]]; then
      echo "Notarization requires either XCOPY_NOTARY_KEYCHAIN_PROFILE or XCOPY_NOTARY_APPLE_ID, XCOPY_NOTARY_TEAM_ID, and XCOPY_NOTARY_PASSWORD." >&2
      exit 1
    fi

    xcrun notarytool submit "$DMG_PATH" \
      --apple-id "$NOTARY_APPLE_ID" \
      --team-id "$NOTARY_TEAM_ID" \
      --password "$NOTARY_PASSWORD" \
      --no-s3-acceleration \
      --timeout 10m \
      --wait
  fi

  echo "Stapling notarization ticket..."
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

echo "Created $DMG_PATH"
