#!/bin/bash
# Monitor 6 — releases de Django en hyl-wai-stg (Heroku).
#
# Es el ÚNICO monitor que ve a Juan desplegar: los demás ven lo que escribe
# (issues) o lo que empuja a git, no lo que pone a correr. Con la cadena
# #161 -> Payments -> #135 viva, un release nuevo de STG cambia contra qué
# estamos midiendo, y un rollback lo cambia sin que nadie lo anuncie.
#
# Vive desde el 13 ago 2026 sin estar escrito en ninguna parte: sobrevivió a un
# /clear y estuvo a punto de morir en la poda del 16 ago por no poder acreditar
# para qué servía. Versionado por eso.
while true; do
  cur=$(env -u NODE_OPTIONS heroku releases -a hyl-wai-stg -n 1 --json 2>/dev/null \
    | python3 -c "import sys,json; r=json.load(sys.stdin)[0]; print('v%s %s [%s]' % (r['version'], r['description'], r['status']))" 2>/dev/null || true)
  if [ -n "$cur" ] && [ -n "$prev" ] && [ "$cur" != "$prev" ]; then
    echo "hyl-wai-stg: $cur (antes: $prev)"
  fi
  [ -n "$cur" ] && prev="$cur"
  sleep 180
done
