#!/bin/bash
# Monitor 5 — informes de ejecutores en Agente-Arquitecto:informes/ de origin/main.
# Existe porque una entrega DOCS-ONLY no mueve ninguna rama del ejecutor y el
# monitor 3 no la ve. Excluye README, -respuesta y -acuse (esos los escribo yo).
REPO=/Users/AIP/claude-projects/Agente-Arquitecto
SEEN="$(dirname "$0")/.m5-seen"

lista() {
  git -C "$REPO" fetch origin main -q 2>/dev/null || true
  git -C "$REPO" ls-tree --name-only origin/main informes/ 2>/dev/null \
    | grep -v 'README.md' | grep -v -- '-respuesta\.md$' | grep -v -- '-acuse\.md$'
}

lista > "$SEEN"

while true; do
  sleep 60
  now=$(lista)
  [ -z "$now" ] && continue
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -qx "$f" "$SEEN" 2>/dev/null && continue
    asunto=$(git -C "$REPO" log origin/main -1 --format=%s -- "$f" 2>/dev/null | cut -c1-160)
    echo "[informe NUEVO] $f :: $asunto"
  done <<< "$now"
  echo "$now" > "$SEEN"
done
