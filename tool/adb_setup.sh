#!/usr/bin/env bash
# One-time activation for No Mosi9a, run from a computer with the phone plugged in
# (USB debugging on). Safe to run again; it only grants permissions to this app.
set -euo pipefail

PKG="com.nomosi9a.app"

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install Android platform-tools first (e.g. 'brew install android-platform-tools')." >&2
  exit 1
fi

echo "Waiting for the phone (accept the 'Allow USB debugging' prompt on it)..."
adb wait-for-device

if ! adb shell pm path "$PKG" >/dev/null 2>&1; then
  echo "No Mosi9a is not installed on this phone yet. Install the APK first." >&2
  exit 1
fi

# Lets the app see which app owns which audio session, so it can mute the original sound.
adb shell pm grant "$PKG" android.permission.DUMP
# Skips Android's capture pop-up and keeps working with the screen off (Android 15+).
adb shell appops set "$PKG" PROJECT_MEDIA allow
# Runtime permissions (the app can also ask for these itself).
adb shell pm grant "$PKG" android.permission.RECORD_AUDIO || true
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

echo "Done. Open No Mosi9a and tap the big button."
