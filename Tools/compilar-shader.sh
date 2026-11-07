#!/bin/sh
# Compila um .metal isolado. Se falhar, tenta a versao reparada por
# Tools/reparar_shader.py; se ela compilar, substitui o arquivo. Senao,
# registra em build/falhas.txt.
f="$1"; n=$(basename "$f" .metal)
cc() { xcrun -sdk iphoneos metal -c -std=metal3.0 -target air64-apple-ios17.0 \
         -IShaders "$1" -o "build/air/$n.air" 2> "$2"; }
if cc "$f" "build/err/$n.txt"; then
  rm -f "build/err/$n.txt"; exit 0
fi
case "$n" in fx_*) ;; *) echo "$f" >> build/falhas.txt; exit 0;; esac
mkdir -p build/rep
if python3 -I Tools/reparar_shader.py "$f" "build/rep/$n.metal" && \
   cc "build/rep/$n.metal" "build/err/$n.rep.txt"; then
  cp "build/rep/$n.metal" "$f"
  rm -f "build/err/$n.txt" "build/err/$n.rep.txt"
  echo "$f" >> build/reparados.txt
else
  echo "$f" >> build/falhas.txt
fi
