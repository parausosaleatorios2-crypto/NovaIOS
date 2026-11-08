#!/bin/sh
# Compila um .metal isolado. Se falhar, tenta a versao reparada por
# Tools/reparar_shader.py: primeiro o reparo completo, depois o basico (sem as
# regras extras de Tools/reparar_glsl_extra.py) — uma regra nova nunca derruba
# um shader que ja reparava. Se alguma versao compilar, substitui o arquivo;
# senao, registra em build/falhas.txt.
f="$1"; n=$(basename "$f" .metal)
cc() { xcrun -sdk iphoneos metal -c -std=metal3.0 -target air64-apple-ios17.0 \
         -IShaders "$1" -o "build/air/$n.air" 2> "$2"; }
if cc "$f" "build/err/$n.txt"; then
  rm -f "build/err/$n.txt"; exit 0
fi
case "$n" in fx_*) ;; *) echo "$f" >> build/falhas.txt; exit 0;; esac
mkdir -p build/rep
for modo in "" "--basico"; do
  if python3 -I Tools/reparar_shader.py "$f" "build/rep/$n.metal" $modo && \
     cc "build/rep/$n.metal" "build/err/$n.rep.txt"; then
    cp "build/rep/$n.metal" "$f"
    rm -f "build/err/$n.txt" "build/err/$n.rep.txt"
    echo "$f" >> build/reparados.txt
    exit 0
  fi
done
echo "$f" >> build/falhas.txt
