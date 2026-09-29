#!/usr/bin/env bash
# m7 · lo que espera una decisión del Arquitecto.
# Lee docs/lo-que-espera-mi-decision.md y avisa de lo que lleva demasiado esperando.
# No consulta APIs: el fichero es la fuente. Si el fichero no existe, lo DICE — no calla.
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
DOC="$REPO/docs/lo-que-espera-mi-decision.md"

if [ ! -f "$DOC" ]; then
  echo "m7: NO COMPROBABLE — no existe $DOC (no es 'no hay nada pendiente')"
  exit 0
fi

mias=0
albertos=0
# Filas de la sección "Abierto": empiezan por '| ' y no son cabecera ni separador.
# La columna 4 dice QUIÉN desbloquea: por eso se cuentan por separado. Un contador
# único decía "N esperando una decisión mía" incluyendo las de Alberto, que es
# justo la confusión que este fichero existe para deshacer.
while IFS= read -r linea; do
  case "$linea" in
    '|---'*|'| Desde '*|'| Decidido '*) continue ;;
    '|'*) : ;;
    *) continue ;;
  esac
  desde=$(printf '%s' "$linea" | awk -F'|' '{print $2}' | tr -d ' ')
  [ -z "$desde" ] && continue
  quien=$(printf '%s' "$linea" | awk -F'|' '{print $5}')
  case "$quien" in
    *Alberto*) albertos=$((albertos+1)) ;;
    *) mias=$((mias+1)) ;;
  esac
done < <(sed -n '/^## Abierto/,/^## Cerrado/p' "$DOC")

total=$((mias+albertos))
if [ "$total" -eq 0 ]; then
  echo "m7: nada esperando una decisión · $DOC"
  exit 0
fi
echo "m7: $mias esperando una decisión MÍA · $albertos esperando a ALBERTO · $DOC"
sed -n '/^## Abierto/,/^## Cerrado/p' "$DOC" | grep '^| ' | grep -v '^|---' | grep -v '^| Desde ' \
  | awk -F'|' '{marca = ($5 ~ /Alberto/) ? "[ALBERTO]" : "[mía]   "; printf "   %s desde %s · %s\n", marca, $2, substr($3,1,80)}'
