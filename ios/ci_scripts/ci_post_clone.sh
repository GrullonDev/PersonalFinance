#!/bin/sh

# ci_post_clone.sh — Xcode Cloud post-clone hook
#
# Xcode Cloud clones the repo and then executes this script BEFORE any build
# phase (Archive, Test, etc.). We use it to:
#   1. Install Flutter from the stable channel
#   2. Run `flutter pub get` so all Dart packages resolve and the
#      Generated.xcconfig / .symlinks are written to disk
#   3. Run `pod install` so CocoaPods can integrate every Flutter plugin
#      (firebase_messaging, local_auth_darwin, etc.) into the Xcode project
#
# Required Xcode Cloud environment variables (set in the workflow):
#   FLUTTER_VERSION  — e.g. "3.41.8"  (pin to the version used locally)
#
# References:
#   https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -euo pipefail   # exit on error, unset var, or pipe failure

# ── 0. Helpers ────────────────────────────────────────────────────────────────
log() { echo "[ci_post_clone] $*"; }
fail() { echo "[ci_post_clone] ERROR: $*" >&2; exit 1; }

# ── 1. Resolve Flutter version ────────────────────────────────────────────────
# Allow the workflow to pin an exact version; fall back to stable channel.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.8}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="$HOME/flutter"
FLUTTER="$FLUTTER_HOME/bin/flutter"

log "Flutter version requested: $FLUTTER_VERSION (channel: $FLUTTER_CHANNEL)"

# ── 2. Install Flutter SDK if not already cached ──────────────────────────────
# Xcode Cloud does NOT cache $HOME between runs by default, so we always
# download. If the workflow enables caching on $HOME/flutter, the `if` guard
# prevents a redundant clone.
if [ ! -f "$FLUTTER" ]; then
  log "Cloning Flutter $FLUTTER_VERSION ..."
  git clone \
    --depth 1 \
    --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git \
    "$FLUTTER_HOME"
else
  log "Flutter SDK already present at $FLUTTER_HOME — skipping clone."
fi

# Add Flutter and Dart to PATH for the rest of this script.
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# Pre-download the engine artifacts (needed for pub and pod steps).
log "Running flutter precache (iOS)..."
flutter precache --ios

# ── 3. Resolve Dart / pub dependencies ───────────────────────────────────────
# REPO_ROOT is two levels up from ios/ci_scripts/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
log "Project root: $REPO_ROOT"

log "Running flutter pub get..."
flutter pub get --directory="$REPO_ROOT"

# ── 4. Install CocoaPods dependencies ────────────────────────────────────────
# Xcode Cloud agents ship with a system Ruby + CocoaPods, but the version may
# differ from local. Install/update gems into the user prefix to be safe.
log "Ensuring CocoaPods gem is available..."
gem install cocoapods --user-install --no-document 2>/dev/null || true
export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

cd "$REPO_ROOT/ios"
log "Running pod install..."
pod install --repo-update

log "Done. Flutter + CocoaPods setup complete."
