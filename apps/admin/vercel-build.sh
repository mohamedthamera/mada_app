#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.27.4"

echo "=== Installing Flutter SDK $FLUTTER_VERSION ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
dart --version

echo "=== Creating env.dev from Vercel Environment Variables ==="
cat > env.dev <<EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
EOF

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