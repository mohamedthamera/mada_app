#!/usr/bin/env bash
set -euo pipefail

FLUTTER_TAR="flutter_linux_stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"

echo "==> Downloading Flutter (stable)..."
curl -L -o "$FLUTTER_TAR" "$FLUTTER_URL"

echo "==> Extracting..."
tar -xf "$FLUTTER_TAR"

export PATH="$PWD/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

flutter config --enable-web
flutter pub get
flutter build web --release --base-href "/"