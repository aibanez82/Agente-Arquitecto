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

declare -A prev
for a in $APPS; do prev[$a]=$(leer "$a"); done

while true; do
  sleep 180
  for a in $APPS; do
    cur=$(leer "$a")
    [ -z "$cur" ] && continue
    if [ -n "${prev[$a]}" ] && [ "$cur" != "${prev[$a]}" ]; then
      echo "[release $a] $cur (antes: ${prev[$a]})"
    fi
    prev[$a]="$cur"
  done
done
