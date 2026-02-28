#!/usr/bin/env bash
set -e

curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz | tar xJ
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
flutter build web --release
