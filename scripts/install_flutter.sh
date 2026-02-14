#!/usr/bin/env bash
set -euo pipefail

# Define Flutter version and directory
FLUTTER_VERSION="3.27.1" # Using a recent stable version
FLUTTER_DIR="$HOME/.flutter_sdk"

# Install Flutter if not cached
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Downloading Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
  echo "Using cached Flutter..."
fi

# Add to PATH
export PATH="$FLUTTER_DIR/bin:$PATH"

# Setup environment
echo "Setting up Flutter..."
flutter config --no-analytics
flutter doctor -v

# Create .env from environment variables if missing
if [ ! -f .env ]; then
  echo "Generating .env file from environment variables..."
  echo "SUPABASE_URL=$SUPABASE_URL" >> .env
  echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
fi

# Install dependencies and build
echo "Building Web App..."
flutter pub get
flutter build web --release --wasm --no-tree-shake-icons

echo "Build complete!"
