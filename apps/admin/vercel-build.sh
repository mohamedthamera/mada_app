#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.41.3"

# Install Flutter (and Dart) inside Vercel environment
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" flutter_sdk
export PATH="$PWD/flutter_sdk/bin:$PATH"

flutter --version
dart --version

# We are already inside apps/admin (Root Directory)
flutter pub get
flutter build web --release
