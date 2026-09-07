#!/usr/bin/env bash
# Guarda de privilegios del Dashboard — caza el default-deny ANTES de que llegue a PROD.
#
# Por qué existe: `dashboard_rw` es una CREDENCIAL de Heroku, y el Postgres de STG
# (essential-0) no admite credenciales adicionales -- la API responde 403
# "Cannot create new credentials for essential-tier addons", y el usuario de STG no tiene
# CREATEROLE. Conclusión: la topología de privilegios de PROD NO se puede reproducir en STG.
# Esta guarda sustituye a ese entorno: compara el código contra el catálogo REAL de PROD.
#
# Uso:  DATABASE_URL=<PROD> ./guarda-privilegios-dashboard.sh [rev] [repo]
# Sale 1 si algún objeto que el código consulta no es legible por dashboard_rw.
set -u
REV="${1:-origin/main}"
REPO="${2:-$HOME/claude-projects/Dashboard_SeguroAuto}"
ROL="${ROL:-dashboard_rw}"
DB="${DATABASE_URL:?falta DATABASE_URL (la de PROD)}"

ACL=$(mktemp); trap 'rm -f "$ACL"' EXIT
psql "$DB" -Atc "
  select c.relname||'|'||has_table_privilege('$ROL',c.oid,'SELECT')::text
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
   where n.nspname='public' and c.relkind in ('r','v','m','p') order by 1;" > "$ACL" || exit 2

# has_table_privilege sobre pg_class no filtra por privilegios, al revés que information_schema.
[ -s "$ACL" ] || { echo "FALLO: el catálogo volvió vacío. Una lectura que falla no acredita nada."; exit 2; }
echo "catálogo de PROD: $(wc -l < "$ACL" | tr -d ' ') objetos en public · rol: $ROL · código: $REV"

# OJO: se usa `git grep -P`, no `-E`. El motor de -E NO soporta \b y no casa NADA sin dar
# error -- una lectura que falla en silencio. El control positivo de abajo existe por eso.
CTRL="conversation_control_v1"
if ! git -C "$REPO" grep -qP "(FROM|JOIN|INTO)\s+(public\.)?${CTRL}\b" "$REV" -- apps packages </dev/null; then
  echo "FALLO DE MÉTODO: el control positivo ($CTRL) no aparece. La guarda no acredita nada."; exit 2
fi

# PASO 0 · objetos que el CÓDIGO nombra y que NO existen en la base.
# Punto ciego encontrado el 6 sep 2026: esta guarda enumeraba el catálogo y preguntaba
# "¿lo usa el código?". Así, una tabla que el código consulta y que NO EXISTE nunca aparece
# -- no está en pg_class, luego no se comprueba. `dashboard_control_commands` llevaba desde
# el 11 de agosto sin crearse en PROD y esta guarda no podía verlo.
# `to_regclass` NO filtra por privilegios: un NULL aquí es ausencia real, no falta de permiso.
ausentes=0
for obj in $(git -C "$REPO" grep -hoP "(?<=FROM public\.)[a-z0-9_]+|(?<=JOIN public\.)[a-z0-9_]+|(?<=INTO public\.)[a-z0-9_]+|(?<=UPDATE public\.)[a-z0-9_]+" "$REV" -- apps packages </dev/null 2>/dev/null | sort -u); do
  existe=$(psql "$DB" -Atc "select coalesce(to_regclass('public.$obj')::text,'NO');" 2>/dev/null)
  if [ "$existe" = "NO" ]; then
    printf "  AUSENTE   %-46s el código lo consulta y NO EXISTE en la base\n" "$obj"
    ausentes=$((ausentes+1))
  fi
done
[ "$ausentes" -eq 0 ] && echo "  (sin objetos ausentes)"
echo

fail=0; tot=0
# El bucle lee de fd 3: si git grep leyera de stdin se comería la lista y el bucle moriría
# en la primera vuelta -- que es exactamente el fallo que tuvo la primera versión.
while IFS='|' read -r obj sel <&3; do
  n=$(git -C "$REPO" grep -nP "(FROM|JOIN|INTO)\s+(public\.)?${obj}\b" "$REV" -- apps packages </dev/null 2>/dev/null \
      | grep -vcE ':[0-9]+:[[:space:]]*(//|\*)')
  [ "${n:-0}" -gt 0 ] || continue
  tot=$((tot+1))
  if [ "$sel" = "true" ]; then printf "  OK        %-46s %s consulta(s)\n" "$obj" "$n"
  else printf "  DENEGADO  %-46s %s consulta(s)\n" "$obj" "$n"; fail=$((fail+1)); fi
done 3< "$ACL"

echo "consultados: $tot · denegados: $fail · ausentes: $ausentes"
[ "$ausentes" -eq 0 ] || { echo "FAIL: $ausentes objeto(s) que el código consulta y NO EXISTEN."; exit 1; }
[ "$fail" -eq 0 ] || { echo "FAIL: $fail objeto(s) que el código consulta y $ROL no puede leer."; exit 1; }
echo "PASS"
