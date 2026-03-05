#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.41.3"

echo "==> PWD: $(pwd)"
echo "==> Listing files:"
ls -la

# Install Flutter (and Dart) inside Vercel build environment
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" flutter_sdk
export PATH="$PWD/flutter_sdk/bin:$PATH"

flutter --version
dart --version

# Build Flutter Web (we are already inside apps/admin on Vercel)
flutter pub get
flutter build web --release
