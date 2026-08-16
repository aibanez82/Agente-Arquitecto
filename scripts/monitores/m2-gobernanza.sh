#!/bin/bash
# Monitor 2 — gobernanza e iniciativa viva. #140 quedó CERRADO el 4 ago, así que
# este monitor apunta a los issues vivos: #135 (funnel/estados), #156 (Descuentos,
# nuestro lado) y #161 (worker de descuentos, de Juan). Emite comentarios de Juan.
ISSUES="135 156 161 128 143"
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
