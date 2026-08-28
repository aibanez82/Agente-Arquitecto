#!/usr/bin/env bash
# Regenera la vista ejecutiva del tracker HYL-WAI. Un solo comando, sin nada que editar.
#
#   ./actualizar.sh [fichero-salida.html]
#
# Requiere `gh` autenticado con acceso de lectura a aguayo-co/HYL-WAI (privado).
set -euo pipefail
cd "$(dirname "$0")"
OUT="${1:-tablero-ejecutivo.html}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "1/3  leyendo issues abiertos de aguayo-co/HYL-WAI…"
gh issue list --repo aguayo-co/HYL-WAI --state open --limit 200 \
   --json number,title,labels,assignees,createdAt,updatedAt,comments,body > "$TMP/iss.json"
# Guarda en positivo: cero issues casi siempre significa lectura rota, no tracker limpio.
N=$(python3 -c "import json,sys;print(len(json.load(open('$TMP/iss.json'))))")
[ "$N" -gt 0 ] || { echo "ABORTADO: 0 issues leídos. Comprueba 'gh auth status' — un tracker vacío y una lectura fallida se ven igual."; exit 1; }
echo "     $N issues"

echo "2/3  clasificando (área y entorno: derivados, no campos del tracker)…"
python3 clasificar.py "$TMP/iss.json" "$TMP/out"

echo "3/3  generando $OUT…"
python3 emitir.py "$TMP/out.data.json" "$OUT"
echo
echo "Listo: $OUT"
echo "Publicar en el artefacto existente (misma URL):"
echo "  https://claude.ai/code/artifact/e0d915fd-be3d-4c02-bad9-60e7e7f89fa9"
