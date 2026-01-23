#!/usr/bin/env bash
set -euo pipefail

echo "[Netlify] Starting Flutter Web build..."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found in PATH. Installing Flutter CLI..."
  FLUTTER_VERSION=3.13.7-stable
  FLUTTER_ROOT="$HOME/.cache/flutter"
  mkdir -p "$FLUTTER_ROOT"
  TMP_DIR=$(mktemp -d)
  echo "Downloading Flutter $FLUTTER_VERSION..."
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}.tar.xz" -o "$TMP_DIR/flutter_linux.tar.xz"
  tar -xf "$TMP_DIR/flutter_linux.tar.xz" -C "$TMP_DIR" --strip-components=1
  mv "$TMP_DIR" "$FLUTTER_ROOT"
  export PATH="$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PATH"
fi

echo "Using Flutter: $(flutter --version)"
flutter --version
flutter doctor -v || true

echo "Enabling web support and preparing project..."
flutter config --enable-web
flutter clean
flutter pub get

echo "Building Flutter Web (release)..."
flutter build web --release
echo "Flutter Web build completed."
