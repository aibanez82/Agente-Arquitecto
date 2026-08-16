#!/bin/bash
# Monitor 3 — pushes en los remotos de ejecutores + HYL-WAI.
# Compara TODAS las refs de origin (así aparecen ramas nuevas), distingue avance
# de REESCRITA con merge-base --is-ancestor, y salta el ref pelado `origin`
# (refs/remotes/origin/HEAD, que es alias de la rama por defecto).
REPOS="/Users/AIP/claude-projects/Agente-n8n
/Users/AIP/claude-projects/Dashboard_SeguroAuto
/Users/AIP/claude-projects/HYL-WAI
/Users/AIP/claude-projects/Agente_QATest_Qualitas
/Users/AIP/claude-projects/Agente-MejorasConversacion
/Users/AIP/claude-projects/Agente-Conciliacion"

STATE="$(dirname "$0")/.m3-state"

snapshot() {
  echo "$REPOS" | while IFS= read -r repo; do
    [ -d "$repo/.git" ] || continue
    git -C "$repo" fetch --all --prune -q 2>/dev/null || true
    git -C "$repo" for-each-ref --format="$(basename "$repo")|%(refname:short)|%(objectname)" refs/remotes/origin 2>/dev/null
  done
}

snapshot | grep -v '|origin|' > "$STATE"

while true; do
  sleep 90
  new=$(snapshot | grep -v '|origin|')
  [ -z "$new" ] && continue
  while IFS='|' read -r name ref sha; do
    [ -z "$ref" ] && continue
    old=$(grep "^$name|$ref|" "$STATE" 2>/dev/null | cut -d'|' -f3)
    repo=$(echo "$REPOS" | grep "/$name\$" | head -1)
    if [ -z "$old" ]; then
      echo "[push] $name RAMA NUEVA $ref -> $sha :: $(git -C "$repo" log -1 --format=%s "$sha" 2>/dev/null | cut -c1-140)"
    elif [ "$old" != "$sha" ]; then
      if git -C "$repo" merge-base --is-ancestor "$old" "$sha" 2>/dev/null; then
        echo "[push] $name $ref -> $sha :: $(git -C "$repo" log -1 --format=%s "$sha" 2>/dev/null | cut -c1-140)"
      else
        echo "[ALERTA REESCRITA] $name $ref: $old -> $sha (no es descendiente; force-push sobre rama acreditada)"
      fi
    fi
  done <<< "$new"
  echo "$new" > "$STATE"
done
