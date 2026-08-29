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
    # No emitir ECO de lo que publico YO en el canal de ordenes. Los handoffs, los
    # GO y sus correcciones los escribo yo en `main` del repo del ejecutor, y m3
    # me los devolvia como si fueran entrega suya: el 23 ago fueron ~10 avisos de
    # cero valor, y Alberto pidio que dejaran de salir. No se puede filtrar por
    # autor de git -- todos los agentes firman como aibanez82 -- asi que durante un
    # tiempo se filtro por el prefijo del asunto (`handoff(`, `GO(`), inequivoco:
    # ningun ejecutor se escribe un handoff a si mismo ni se da un GO.
    # v3 (28 ago, noche): el filtro por prefijo de asunto se me quedo corto en
    # cuanto empece a publicar `adenda(...)` -- el 28 por la noche me devolvio mi
    # propia adenda del #232 treinta segundos despues de publicarla. Ampliar la
    # lista de prefijos seria repetir el error: cada vocablo nuevo mio abriria el
    # agujero otra vez. Se filtra por lo que SI es estable, el trailer con el que
    # firmo mis commits (`feedback_autoria_tres_planos_trailer_agente`), y los
    # prefijos quedan solo como red para los commits viejos que no lo llevan.
    cuerpo=$(git -C "$repo" log -1 --format=%B "$sha" 2>/dev/null)
    case "$cuerpo" in
      *"Agente: Arquitecto-IA-Qualitas"*)
        continue ;;
    esac
    asunto=$(git -C "$repo" log -1 --format=%s "$sha" 2>/dev/null)
    case "$asunto" in
      handoff\(*|GO\(*|adenda\(*|correccion\(F*)
        continue ;;
    esac

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
