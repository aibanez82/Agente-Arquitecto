#!/bin/bash
# Monitor 2 — TODA la palabra de Juan en un solo proceso. #140 quedó CERRADO el
# 4 ago, así que apunta a los issues vivos: #132 (Contract-First S1, antes monitor
# 1 aparte), #135 (funnel/estados), #156 (Descuentos, nuestro lado), #161 (worker
# de descuentos, de Juan), #128 y #143.
#
# El #132 tenía monitor propio hasta el 16 ago. No lo merecía: la lógica de dedupe
# es idéntica y un issue más en la lista cuesta una llamada por ciclo, no un
# proceso. Un monitor por canal, no por asunto.
ISSUES="132 135 156 161 128 143"
SEEN_FILE="$(dirname "$0")/.m2-seen"
: > "$SEEN_FILE"
SINCE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

for I in $ISSUES; do
  seed=$(gh api "repos/aguayo-co/HYL-WAI/issues/$I/comments?per_page=100" \
    --jq '.[] | select(.user.login=="oilycoyote") | (.body | gsub("[\n\r]"; " "))' 2>/dev/null)
  [ -z "$seed" ] && continue
  while IFS= read -r body; do
    [ -z "$body" ] && continue
    printf '%s' "$body" | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}\.?[0-9]*Z?//g' | shasum | cut -d' ' -f1 >> "$SEEN_FILE"
  done <<< "$seed"
done

while true; do
  sleep 120
  for I in $ISSUES; do
    out=$(gh api "repos/aguayo-co/HYL-WAI/issues/$I/comments?since=$SINCE&per_page=100" \
      --jq '.[] | select(.user.login=="oilycoyote") | "\(.created_at)|\(.html_url)|\(.body | gsub("[\n\r]"; " "))"' 2>/dev/null) || continue
    [ -z "$out" ] && continue
    while IFS='|' read -r created url body; do
      [ -z "$body" ] && continue
      h=$(printf '%s' "$body" | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}\.?[0-9]*Z?//g' | shasum | cut -d' ' -f1)
      grep -q "^$h$" "$SEEN_FILE" 2>/dev/null && continue
      echo "$h" >> "$SEEN_FILE"
      echo "[#$I · Juan] $created $url :: $(printf '%s' "$body" | cut -c1-200)"
    done <<< "$out"
  done
done
