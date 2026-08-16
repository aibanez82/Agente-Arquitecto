#!/bin/bash
# Monitor 4 — dudas de ejecutores en Agente-Arquitecto:dudas/ de origin/main.
# Fichero sin su -respuesta.md = duda pendiente. Se responde SIEMPRE por fichero.
REPO=/Users/AIP/claude-projects/Agente-Arquitecto
SEEN="$(dirname "$0")/.m4-seen"

pendientes() {
  git -C "$REPO" fetch origin main -q 2>/dev/null || true
  todos=$(git -C "$REPO" ls-tree --name-only origin/main dudas/ 2>/dev/null)
  echo "$todos" | grep -v 'README.md' | grep -v -- '-respuesta\.md$' | while IFS= read -r f; do
    [ -z "$f" ] && continue
    base="${f%.md}"
    echo "$todos" | grep -q "^${base}-respuesta.md$" || echo "$f"
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
