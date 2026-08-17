#!/bin/bash
# Gate de la higiene de CLAUDE.md — protocolo: docs/protocolos/higiene-claude-md.md
#
# Por cada ancla de scripts/anclas-claude-md.txt exige UNA de estas dos:
#   (a) el texto sigue en CLAUDE.md; o
#   (b) tiene destino declarado, el texto está EN ese destino, y CLAUDE.md conserva el
#       puntero al destino.
# Cualquier otra cosa es un ancla huérfana: fallo, y no se mergea.
#
# Uso:  bash scripts/verifica-claude-md.sh          (desde la raíz del repo)
# Sale 0 si todo pasa, 1 si hay alguna huérfana.

cd "$(dirname "$0")/.." || exit 2
CLAUDE="CLAUDE.md"
ANCLAS="scripts/anclas-claude-md.txt"
[ -f "$CLAUDE" ] || { echo "FATAL: no encuentro $CLAUDE"; exit 2; }
[ -f "$ANCLAS" ] || { echo "FATAL: no encuentro $ANCLAS"; exit 2; }

ok=0; movidas=0; fallos=0

while IFS= read -r linea; do
  case "$linea" in ""|"#"*|"##"*) continue;; esac
  if [[ "$linea" == *"|"* ]]; then
    texto="${linea%%|*}"; destino="${linea#*|}"
  else
    texto="$linea"; destino=""
  fi
  texto="$(echo "$texto" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  destino="$(echo "$destino" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$texto" ] && continue

  if grep -qF -- "$texto" "$CLAUDE"; then
    ok=$((ok+1)); continue
  fi

  if [ -n "$destino" ]; then
    if [ ! -f "$destino" ]; then
      echo "FALLO  [$texto] — destino declarado no existe: $destino"; fallos=$((fallos+1)); continue
    fi
    if ! grep -qF -- "$texto" "$destino"; then
      echo "FALLO  [$texto] — no está en CLAUDE.md NI en su destino $destino"; fallos=$((fallos+1)); continue
    fi
    if ! grep -qF -- "$destino" "$CLAUDE"; then
      echo "FALLO  [$texto] — está en $destino pero CLAUDE.md perdió el puntero"; fallos=$((fallos+1)); continue
    fi
    movidas=$((movidas+1)); continue
  fi

  echo "FALLO  [$texto] — desaparecido de CLAUDE.md y sin destino declarado"
  fallos=$((fallos+1))
done < "$ANCLAS"

bytes=$(wc -c < "$CLAUDE" | tr -d ' ')
echo "---"
echo "CLAUDE.md: $bytes bytes (techo 30 KB = 30720)"
echo "anclas en CLAUDE.md: $ok · movidas con puntero: $movidas · huérfanas: $fallos"
[ "$bytes" -gt 30720 ] && { echo "FALLO  — por encima del techo"; fallos=$((fallos+1)); }
[ "$fallos" -gt 0 ] && { echo "GATE: FALLA"; exit 1; }
echo "GATE: PASA"
