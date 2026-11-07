#!/bin/sh
# Compila um .metal isolado; registra em build/falhas.txt se falhar.
f="$1"; n=$(basename "$f" .metal)
if xcrun -sdk iphoneos metal -c -std=metal3.0 -target air64-apple-ios17.0 \
     -IShaders "$f" -o "build/air/$n.air" 2> "build/err/$n.txt"; then
  rm -f "build/err/$n.txt"
else
  echo "$f" >> build/falhas.txt
fi
