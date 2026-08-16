#!/bin/bash
# Monitor 1 — dictámenes de Juan (oilycoyote) en HYL-WAI#132
# Dedupe por hash del contenido con los timestamps ISO retirados (el comentario
# canónico del daemon se edita en sitio y `since` lo devolvería siempre).
ISSUE=132
SEEN_FILE="$(dirname "$0")/.m1-seen"
: > "$SEEN_FILE"
SINCE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Sembrar: marcar como visto todo lo que ya existe ahora mismo.
seed=$(gh api "repos/aguayo-co/HYL-WAI/issues/$ISSUE/comments?per_page=100" \
  --jq '.[] | select(.user.login=="oilycoyote") | (.body | gsub("[\n\r]"; " "))' 2>/dev/null)
if [ -n "$seed" ]; then
  while IFS= read -r body; do
    [ -z "$body" ] && continue
    printf '%s' "$body" | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}\.?[0-9]*Z?//g' | shasum | cut -d' ' -f1 >> "$SEEN_FILE"
  done <<< "$seed"
fi

while true; do
  sleep 75
  out=$(gh api "repos/aguayo-co/HYL-WAI/issues/$ISSUE/comments?since=$SINCE&per_page=100" \
    --jq '.[] | select(.user.login=="oilycoyote") | "\(.created_at)|\(.html_url)|\(.body | gsub("[\n\r]"; " "))"' 2>/dev/null) || continue
  [ -z "$out" ] && continue
  while IFS='|' read -r created url body; do
    [ -z "$body" ] && continue
    h=$(printf '%s' "$body" | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}\.?[0-9]*Z?//g' | shasum | cut -d' ' -f1)
    grep -q "^$h$" "$SEEN_FILE" 2>/dev/null && continue
    echo "$h" >> "$SEEN_FILE"
    echo "[#132 · Juan] $created $url :: $(printf '%s' "$body" | cut -c1-200)"
  done <<< "$out"
done
