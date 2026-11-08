#!/bin/sh
# Compila um .metal para macOS (sonda de efeitos do CI). Falha nao interrompe.
f="$1"; n=$(basename "$f" .metal)
xcrun -sdk macosx metal -c -std=metal3.0 -target air64-apple-macos14.0 \
  -IShaders "$f" -o "build/airmac/$n.air" 2>/dev/null || echo "$f" >> build/falhas-mac.txt
