#!/usr/bin/env bash
set -e

# النسخة الحديثة المطلوبة
FLUTTER_VERSION="3.41.6"

echo "=== Installing Flutter SDK $FLUTTER_VERSION ==="
git clone https://github.com/flutter/flutter.git --branch "$FLUTTER_VERSION" --depth 1 "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# تحقق من النسخ
which flutter
flutter --version
dart --version

echo "=== Getting dependencies for shared package ==="
cd ../../packages/shared
flutter pub get

echo "=== Getting dependencies for admin ==="
cd ../../apps/admin
flutter pub get

echo "=== Building Flutter Web ==="
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "=== Build Complete ==="
