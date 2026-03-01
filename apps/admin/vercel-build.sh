#!/usr/bin/env bash
set -euo pipefail

echo "==> Downloading latest Flutter (stable)..."

FLUTTER_TAR="flutter_linux_stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"

curl -L -o "$FLUTTER_TAR" "$FLUTTER_URL"
tar -xf "$FLUTTER_TAR"

export PATH="$PWD/flutter/bin:$PATH"

echo "==> Flutter & Dart versions:"
flutter --version
dart --version

flutter config --enable-web
flutter pub get
flutter build web --release --base-href "/"