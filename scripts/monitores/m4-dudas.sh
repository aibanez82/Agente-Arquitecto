#!/bin/bash
# Monitor 4 — dudas de ejecutores en Agente-Arquitecto:dudas/ de origin/main.
# Fichero sin contestacion = duda pendiente. Se responde SIEMPRE por fichero.
#
# v2 (25 sep 2026). La v1 clasificaba por el SUFIJO del nombre: todo lo que
# acabara en `-respuesta.md` era contestacion mia y se descartaba. Dos averias
# opuestas, las dos vivas a la vez y medidas hoy:
#
#   · `2026-09-18-n8n-contadores-onerror-corta-respuesta.md` es una DUDA —su
#     asunto es que el contador corta la respuesta— y el filtro la tomo por
#     contestacion mia. Siete dias invisible.
#   · `2026-09-18-n8n-338-256-RESPUESTA.md` era contestacion mia y el patron,
#     sensible a mayusculas, no la reconocia: la duda seguia «pendiente» con la
#     respuesta publicada al lado.
#
# El sufijo era un proxy del acto de responder. **La direccion esta escrita
# dentro del documento** —`**De:** Agente n8n · **Para:** Arquitecto` frente a
# `**De:** Arquitecto-IA-Qualitas`— y ahi es donde hay que leerla.
#
# El emparejamiento se conserva para el caso normal porque es barato y no falla
# cuando los dos ficheros existen. Solo cuando NO hay pareja —que es donde la v1
# se equivocaba— se abre el documento y se mira quien lo firma. Cuatro
# contestaciones mias de agosto contestan a dudas que llegaron por otra via y
# nunca se ficheraron: sin esta lectura saldrian como pendientes para siempre, y
# un canal con cuatro falsos permanentes ensena a no mirarlo.
REPO=/Users/AIP/claude-projects/Agente-Arquitecto
SEEN="$(dirname "$0")/.m4-seen"

listar() {
  git -C "$REPO" fetch origin main -q 2>/dev/null || true
  git -C "$REPO" ls-tree --name-only origin/main dudas/ 2>/dev/null | grep -v 'README.md'
}

# `mia` | `ajena`, leyendo la cabecera del documento. Se llama solo para los
# ficheros ambiguos, no para todos.
autor() {
  cab=$(git -C "$REPO" show "origin/main:$1" 2>/dev/null | head -12)
  [ -z "$cab" ] && { echo ajena; return; }
  de=$(printf '%s\n' "$cab" | grep -m1 -- '\*\*De:\*\*' | sed -E 's/.*\*\*De:\*\*//; s/\*\*Para:\*\*.*//')
  if [ -n "$de" ]; then
    printf '%s' "$de" | grep -qi 'arquitecto' && echo mia || echo ajena
    return
  fi
  # Sin linea `De:` (formato viejo): la direccion viaja en el titulo.
  printf '%s\n' "$cab" | grep -qE '(→|->)[[:space:]]*Arquitecto' && { echo ajena; return; }
  printf '%s\n' "$cab" | grep -qE '^# Respuesta|Arquitecto[^→]*(→|->)'  && { echo mia;   return; }
  # Ilegible. Se trata como duda a proposito: una pendiente de mas se ve y se
  # corrige; una de menos no la ve nadie.
  echo ajena
}

# Clasifica la lista que llega por stdin. Aislado de `listar` a proposito: asi
# se ejercita con fixtures y se ven los dos casos —el que debe salir y el que
# debe callarse—, que es la unica prueba que acredita un filtro.
clasificar() {
  todos=$(cat)
  printf '%s\n' "$todos" | while IFS= read -r f; do
    [ -z "$f" ] && continue

    # ¿Prolonga el nombre de una duda que existe? Entonces es su contestacion.
    base=$(printf '%s' "$f" | sed -E 's/-respuesta(-r[0-9]+)?\.md$//I')
    if [ "$base.md" != "$f" ]; then
      printf '%s\n' "$todos" | grep -qxF "$base.md" && continue
      # Sin pareja: aqui es donde la v1 adivinaba. Se lee el documento.
      [ "$(autor "$f")" = "mia" ] && continue
    fi

    # Llegados aqui, `$f` es una duda. ¿Tiene contestacion publicada?
    d="${f%.md}"
    esc=$(printf '%s' "$d" | sed 's/[.[\*^$]/\\&/g')
    printf '%s\n' "$todos" | grep -qiE "^${esc}-respuesta(-r[0-9]+)?\.md$" || echo "PENDIENTE $f"
  done
}

estado() { listar | clasificar; }

# Modo prueba: no toca red ni fichero de estado.
[ "$1" = "--clasificar" ] && { clasificar; exit 0; }

estado > "$SEEN"

while true; do
  sleep 60
  now=$(estado)
  [ -z "$now" ] && continue
  while IFS= read -r linea; do
    [ -z "$linea" ] && continue
    grep -qx "$linea" "$SEEN" 2>/dev/null && continue
    echo "[duda PENDIENTE] ${linea#PENDIENTE }"
  done <<< "$now"
  echo "$now" > "$SEEN"
done
