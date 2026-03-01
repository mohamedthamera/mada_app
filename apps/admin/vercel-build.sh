#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.29.0"  # stable حديث (لازم يعطي Dart 3.10+)

echo "==> Downloading Flutter $FLUTTER_VERSION"
curl -L -o flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
tar -xJf flutter.tar.xz

# Fix Git 'dubious ownership' inside the Flutter repo on Vercel
git config --global --add safe.directory "$PWD/flutter" || true

export PATH="$PWD/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

echo "==> Dart version:"
dart --version || true

flutter pub get
flutter build web --release
