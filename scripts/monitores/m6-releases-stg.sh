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
# Ciclos seguidos sin lectura antes de gritar. 3 x 180s = ~9 min: filtra el
# hipo puntual de red y no tarda en cantar una credencial caida.
UMBRAL_FALLOS=3

# La credencial se carga AQUI, no se hereda. El monitor corre como proceso de
# fondo con el entorno de su arranque: un `export HEROKU_API_KEY=...` hecho en
# una llamada de Bash no persiste ni llega hasta aqui. El 23 ago la CLI perdio
# la sesion, se recupero con el token de .env.local, y el monitor siguio ciego
# igualmente porque nadie se lo habia dado a EL. Un monitor que depende de que
# alguien recuerde exportarle algo esta roto por diseno.
# .env.local esta gitignorado: aqui solo viaja la ruta, nunca el valor.
if [ -z "$HEROKU_API_KEY" ]; then
  ENVF="$(cd "$(dirname "$0")/../.." && pwd)/.env.local"
  [ -f "$ENVF" ] && HEROKU_API_KEY=$(grep -m1 '^HEROKU_API_KEY=' "$ENVF" | cut -d= -f2- | tr -d '"'"'"' ')
  export HEROKU_API_KEY
fi

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
    # Si la lectura falla, NO callar. `leer` devuelve vacio tanto si Heroku no
    # contesta como si la CLI perdio la sesion, y el `continue` de la v2 dejaba
    # el monitor ciego para siempre sin decir nada: silencio y "no hay releases"
    # se ven igual desde fuera. Paso el 23 ago -- la CLI se deslogueo y m6 dejo
    # de vigilar PROD y STG sin un solo aviso, justo durante la promocion.
    # Avisa una vez al cruzar el umbral y otra al recuperarse; no en cada ciclo.
    if [ -z "$cur" ]; then
      n=$(cat "$DIR/.m6-fallos-$a" 2>/dev/null || echo 0)
      n=$((n + 1)); printf '%s\n' "$n" > "$DIR/.m6-fallos-$a"
      [ "$n" = "$UMBRAL_FALLOS" ] && echo "[m6 CIEGO] $a: $UMBRAL_FALLOS lecturas seguidas sin respuesta (~$((UMBRAL_FALLOS * 3)) min). Probable sesion de la CLI de Heroku caida: 'heroku auth:whoami'. NO se esta vigilando este entorno."
      continue
    fi
    prev_n=$(cat "$DIR/.m6-fallos-$a" 2>/dev/null || echo 0)
    if [ "$prev_n" -ge "$UMBRAL_FALLOS" ] 2>/dev/null; then
      echo "[m6 recuperado] $a: vuelve a leerse. Estado actual: $cur"
    fi
    printf '0\n' > "$DIR/.m6-fallos-$a"
    ant=$(cat "$DIR/.m6-$a" 2>/dev/null)
    if [ -n "$ant" ] && [ "$cur" != "$ant" ]; then
      echo "[release $a] $cur (antes: $ant)"
    fi
    printf '%s\n' "$cur" > "$DIR/.m6-$a"
  done
done
