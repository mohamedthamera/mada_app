#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.41.3" 

# Install Flutter (and Dart) inside Vercel build environment
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" flutter
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
dart --version

# Build Flutter Web (admin)
cd apps/admin
flutter pub get
flutter build web --release
