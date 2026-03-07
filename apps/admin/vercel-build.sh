#!/usr/bin/env bash
set -e

FLUTTER_VERSION="3.41.3"

git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" flutter
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
dart --version

cat > env.dev <<EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
EOF

flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"