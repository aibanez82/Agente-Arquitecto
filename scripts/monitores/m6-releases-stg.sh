#!/bin/bash
# Monitor 6 — releases de Django en Heroku: hyl-wai-stg Y hyl-wai-production.
#
# Es el ÚNICO monitor que ve a Juan DESPLEGAR: los demás ven lo que escribe
# (issues) o lo que empuja a git, no lo que pone a correr. Una rama no es un
# entorno; mergear a `stg` no despliega STG.
#
# v2 (23 ago 2026): entra PROD. Con el #210 abierto —llevar STG a producción y
# dejar los dos entornos como espejo— el release de PROD deja de ser ruido y
# pasa a ser la medida del trabajo: es donde se verá aterrizar cada promoción, y
# donde un rollback cambiaría la línea base sin que nadie lo anuncie.
#
# Vive desde el 13 ago 2026; versionado el 16 ago porque un monitor sin sección
# en la spec es indistinguible de un residuo.
APPS="hyl-wai-stg hyl-wai-production"

leer() {
  env -u NODE_OPTIONS heroku releases -a "$1" -n 1 --json 2>/dev/null \
    | python3 -c "import sys,json; r=json.load(sys.stdin)[0]; print('v%s %s [%s]' % (r['version'], r['description'], r['status']))" 2>/dev/null || true
}

# OJO: NADA de `declare -A`. macOS trae bash 3.2, que no tiene arrays
# asociativos: `declare -A` falla y `prev[$a]=…` degrada a array INDEXADO
# evaluando "$a" como aritmetica -> las dos apps caen en el indice 0 y comparten
# casilla. Sintoma exacto al armar la v2 el 23 ago: el primer ciclo emitio
# `[release hyl-wai-production] v341 … (antes: v239 …)`, y v239 es el valor de
# STG. Un monitor que confunde dos entornos es peor que no tenerlo, porque el
# aviso parece un despliegue de PROD que nunca ocurrio.
#
# Estado en fichero, uno por app. Ademas sobrevive al rearme: tras un /clear el
# monitor nuevo no vuelve a emitir el release que ya estaba.
DIR="$(dirname "$0")"

for a in $APPS; do
  v=$(leer "$a")
  [ -n "$v" ] && printf '%s\n' "$v" > "$DIR/.m6-$a"
done

while true; do
  sleep 180
  for a in $APPS; do
    cur=$(leer "$a")
    [ -z "$cur" ] && continue
    ant=$(cat "$DIR/.m6-$a" 2>/dev/null)
    if [ -n "$ant" ] && [ "$cur" != "$ant" ]; then
      echo "[release $a] $cur (antes: $ant)"
    fi
    printf '%s\n' "$cur" > "$DIR/.m6-$a"
  done
done
