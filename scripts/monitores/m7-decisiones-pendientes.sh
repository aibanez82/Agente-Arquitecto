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

pendientes=0
# Filas de la sección "Abierto": empiezan por '| ' y no son cabecera ni separador
while IFS= read -r linea; do
  case "$linea" in
    '|---'*|'| Desde '*|'| Decidido '*) continue ;;
    '|'*) : ;;
    *) continue ;;
  esac
  desde=$(printf '%s' "$linea" | awk -F'|' '{print $2}' | tr -d ' ')
  [ -z "$desde" ] && continue
  pendientes=$((pendientes+1))
done < <(sed -n '/^## Abierto/,/^## Cerrado/p' "$DOC")

echo "m7: $pendientes cosas esperando una decisión mía · $DOC"
if [ "$pendientes" -gt 0 ]; then
  sed -n '/^## Abierto/,/^## Cerrado/p' "$DOC" | grep '^| ' | grep -v '^|---' | grep -v '^| Desde ' \
    | awk -F'|' '{printf "   desde %s · %s\n", $2, substr($3,1,90)}'
fi
