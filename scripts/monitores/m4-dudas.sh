#!/bin/bash
# Monitor 4 — dudas de ejecutores en Agente-Arquitecto:dudas/ de origin/main.
# Fichero sin su -respuesta.md = duda pendiente. Se responde SIEMPRE por fichero.
REPO=/Users/AIP/claude-projects/Agente-Arquitecto
SEEN="$(dirname "$0")/.m4-seen"

pendientes() {
  git -C "$REPO" fetch origin main -q 2>/dev/null || true
  todos=$(git -C "$REPO" ls-tree --name-only origin/main dudas/ 2>/dev/null)
  # El sufijo -rN cuenta: una `-respuesta-r2.md` es respuesta mía, no duda nueva,
  # y una duda queda cubierta por cualquier revisión de su respuesta.
  echo "$todos" | grep -v 'README.md' | grep -vE -- '-respuesta(-r[0-9]+)?\.md$' | while IFS= read -r f; do
    [ -z "$f" ] && continue
    base="${f%.md}"
    echo "$todos" | grep -qE "^${base}-respuesta(-r[0-9]+)?\.md$" || echo "$f"
  done
}

pendientes > "$SEEN"

while true; do
  sleep 60
  now=$(pendientes)
  [ -z "$now" ] && continue
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -qx "$f" "$SEEN" 2>/dev/null && continue
    echo "[duda PENDIENTE] $f"
  done <<< "$now"
  echo "$now" > "$SEEN"
done
