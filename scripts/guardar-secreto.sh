#!/bin/bash
# Guarda (o sustituye) una variable en .env.local. El valor NO se pasa por
# argumento ni queda en el historial del shell: lo pide la terminal, sin eco.
# Uso:  scripts/guardar-secreto.sh NOMBRE_VARIABLE
set -eu
[ $# -eq 1 ] || { echo "uso: $0 NOMBRE_VARIABLE" >&2; exit 2; }
DIR=$(cd -- "$(dirname -- "$0")/.." && pwd)
ENV="$DIR/.env.local"
K="$1"
case "$K" in [A-Z_]*) : ;; *) echo "nombre inválido: $K" >&2; exit 2;; esac
[ -f "$ENV" ] || { echo "no existe $ENV" >&2; exit 1; }

printf 'Pega el valor de %s y pulsa Enter (no se verá en pantalla):\n> ' "$K"
IFS= read -r -s V
echo
[ -n "$V" ] || { echo "valor vacío: no se ha guardado nada" >&2; exit 1; }

cp "$ENV" "$ENV.bak"
grep -v "^${K}=" "$ENV.bak" > "$ENV" || true
printf '%s=%s\n' "$K" "$V" >> "$ENV"
chmod 600 "$ENV"
echo "OK · $K guardado (${#V} caracteres). Respaldo en .env.local.bak"
