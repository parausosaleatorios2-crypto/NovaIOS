#!/usr/bin/env bash
# Regera os .metal a partir dos XMLs de efeito.
# Rode sempre que mudar um XML em Resources/effects/.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Traduzindo GLSL -> MSL..."
python3 -I Tools/glsl2msl.py Resources/effects \
        -o Shaders \
        --relatorio Docs/relatorio-shaders.csv
echo
echo "Pronto. Confira Docs/relatorio-shaders.csv para os que pedem revisão."
