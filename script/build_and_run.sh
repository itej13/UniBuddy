#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="UniBuddy"
BUNDLE_ID="com.tejasdas.UniBuddy"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ -f "$ROOT_DIR/.env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env.local"
  set +a
fi

# Configure these in .env.local. See .env.example.
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com}"
GOOGLE_REVERSED_CLIENT_ID="${GOOGLE_REVERSED_CLIENT_ID:-com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID}"
GOOGLE_HOSTED_DOMAIN="${GOOGLE_HOSTED_DOMAIN:-}"

patch_google_signin_keychain() {
  swift package resolve >/dev/null
  local signin_file="$ROOT_DIR/.build/checkouts/GoogleSignIn-iOS/GoogleSignIn/Sources/GIDSignIn.m"
  if [[ -f "$signin_file" ]] && ! grep -q "UniBuddy file-based keychain patch" "$signin_file"; then
    perl -0pi -e 's/GTMKeychainStore \*keychainStore =\n        \[\[GTMKeychainStore alloc\] initWithItemName:kGTMAppAuthKeychainName\];/\/\/ UniBuddy file-based keychain patch: SwiftPM-built local app bundles do not\n    \/\/ have a provisioning profile for data-protection keychain access groups.\n    GTMKeychainAttribute *fileBasedKeychain = [GTMKeychainAttribute useFileBasedKeychain];\n    NSSet *keychainAttributes = [NSSet setWithObject:fileBasedKeychain];\n    GTMKeychainStore *keychainStore =\n        [[GTMKeychainStore alloc] initWithItemName:kGTMAppAuthKeychainName\n                               keychainAttributes:keychainAttributes];/s' "$signin_file"
  fi
}

patch_google_signin_keychain
swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

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
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>$GOOGLE_REVERSED_CLIENT_ID</string>
      </array>
    </dict>
  </array>
  <key>GIDClientID</key>
  <string>$GOOGLE_CLIENT_ID</string>
  <key>GIDHostedDomain</key>
  <string>$GOOGLE_HOSTED_DOMAIN</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
