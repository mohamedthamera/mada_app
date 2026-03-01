#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.29.2"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
URL="https://github.com/flutter/flutter/releases/download/${FLUTTER_VERSION}-stable/${ARCHIVE}"

echo "==> Downloading Flutter ${FLUTTER_VERSION} ..."
curl -L -o "$ARCHIVE" "$URL"

echo "==> Extracting..."
tar -xf "$ARCHIVE"

export PATH="$PWD/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

flutter config --enable-web
flutter pub get
flutter build web --release --base-href "/"