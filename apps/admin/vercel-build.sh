#!/usr/bin/env bash
set -euo pipefail

echo "==> PWD: $(pwd)"
echo "==> Listing files:"
ls -la

echo "==> Downloading Flutter stable..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz

export PATH="$PWD/flutter/bin:$PATH"

# منع أي رسائل/تفاعل مزعج داخل CI
flutter config --no-analytics --no-cli-animations
flutter config --enable-web

echo "==> Flutter/Dart versions:"
flutter --version
dart --version || true

echo "==> Pub get..."
flutter pub get -v

echo "==> Build web..."
flutter build web --release --base-href "/" -v

echo "==> Build output:"
ls -la build || true
ls -la build/web || true