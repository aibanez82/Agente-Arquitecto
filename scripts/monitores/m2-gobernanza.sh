#!/bin/bash
# Monitor 2 — TODA la palabra de Juan en HYL-WAI, en un solo proceso.
#
# v3 (23 ago 2026): DEJA DE LLEVAR LISTA DE ISSUES. Hasta hoy la lista era
# `132 135 156 161 128 143` y tenía dos averías a la vez: dos issues cerrados
# (#156 el 21 ago, #143 el 20 ago) seguían costando una llamada por ciclo, y los
# tres issues donde Juan trabaja HOY —#203 (relay de 37 legs), #209 (plan
# aprobado) y #201— no estaban en ella. La spec ya avisaba ("revisar esta lista
# al armar, no heredarla"); revisarla a mano falla porque depende de que alguien
# se acuerde. La lista se sustituye por el endpoint de repo entero:
#
#   /repos/aguayo-co/HYL-WAI/issues/comments?since=…   -> UNA llamada, todos los issues
#
# Un issue que Juan abra mañana nace vigilado. Y cuesta 2 llamadas por ciclo en
# lugar de 6-14.
#
# Cubre además lo que ningún monitor veía: ISSUES NUEVOS abiertos por Juan.
# #203 y #209 los abrió él y nadie avisó.
REPO="aguayo-co/HYL-WAI"
AUTOR="oilycoyote"
SEEN_FILE="$(dirname "$0")/.m2-seen"
: > "$SEEN_FILE"

# Hash del cuerpo SIN timestamps ISO. El comentario «Estado canónico del monitor»
# (marcador seguroauto-monitor:canonical) lo edita el daemon en sitio y su campo
# «Próxima revisión» se reescribe cada ~30 min: dedupe por id+updated_at lo
# emitiría en vacío una y otra vez (visto el 7 ago).
huella() { sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}\.?[0-9]*Z?//g' | shasum | cut -d' ' -f1; }

# Siembra: los comentarios de Juan de los últimos 7 días. No hace falta el
# histórico entero — solo lo que el daemon pueda reeditar y devolver por `since`.
SEMILLA=$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)
gh api "repos/$REPO/issues/comments?since=$SEMILLA&per_page=100" --paginate \
  --jq ".[] | select(.user.login==\"$AUTOR\") | (.body | gsub(\"[\n\r]\"; \" \"))" 2>/dev/null \
  | while IFS= read -r b; do [ -n "$b" ] && printf '%s' "$b" | huella >> "$SEEN_FILE"; done

# Los issues ya existentes no son noticia.
gh issue list --repo "$REPO" --state all --limit 200 --json number \
  --jq '.[] | "issue-\(.number)"' 2>/dev/null >> "$SEEN_FILE"

SINCE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

while true; do
  sleep 120

  # --- 1. Comentarios nuevos de Juan, en cualquier issue del repo ---
  out=$(gh api "repos/$REPO/issues/comments?since=$SINCE&per_page=100" --paginate \
    --jq ".[] | select(.user.login==\"$AUTOR\") | \"\(.issue_url|split(\"/\")|last)|\(.created_at)|\(.html_url)|\(.body | gsub(\"[\n\r]\"; \" \"))\"" 2>/dev/null) || out=""

  if [ -n "$out" ]; then
    nuevos=""
    while IFS='|' read -r num created url body; do
      [ -z "$body" ] && continue
      h=$(printf '%s' "$body" | huella)
      grep -q "^$h$" "$SEEN_FILE" 2>/dev/null && continue
      echo "$h" >> "$SEEN_FILE"
      nuevos="$nuevos$num|$created|$url|$body"$'\n'
    done <<< "$out"

    if [ -n "$nuevos" ]; then
      # Colapsar por issue: el relay de #203 escribe ~40 comentarios al día y un
      # monitor ruidoso se auto-detiene. Más de 3 en un ciclo -> una sola línea.
      echo "$nuevos" | grep -v '^$' | cut -d'|' -f1 | sort -u | while IFS= read -r num; do
        [ -z "$num" ] && continue
        lote=$(echo "$nuevos" | grep "^$num|")
        n=$(echo "$lote" | grep -c '^')
        if [ "$n" -gt 3 ]; then
          ult=$(echo "$lote" | tail -1)
          echo "[#$num · Juan ×$n] última: $(echo "$ult" | cut -d'|' -f4 | cut -c1-160) :: $(echo "$ult" | cut -d'|' -f3)"
        else
          echo "$lote" | while IFS='|' read -r nn created url body; do
            [ -z "$body" ] && continue
            echo "[#$nn · Juan] $created $url :: $(printf '%s' "$body" | cut -c1-200)"
          done
        fi
      done
    fi
  fi

  # --- 2. Issues NUEVOS (los abra quien los abra) ---
  iss=$(gh api "repos/$REPO/issues?since=$SINCE&state=all&per_page=100" --paginate \
    --jq '.[] | select(.pull_request == null) | "\(.number)|\(.user.login)|\(.created_at)|\(.html_url)|\(.title)"' 2>/dev/null) || iss=""
  [ -z "$iss" ] && continue
  while IFS='|' read -r num autor created url titulo; do
    [ -z "$num" ] && continue
    grep -qx "issue-$num" "$SEEN_FILE" 2>/dev/null && continue
    echo "issue-$num" >> "$SEEN_FILE"
    echo "[ISSUE NUEVO #$num · $autor] $created $url :: $(printf '%s' "$titulo" | cut -c1-160)"
  done <<< "$iss"
done
