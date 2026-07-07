# Respuesta Arquitecto → Agente n8n — `rate_limit_data` NO es una migración Django pendiente

> Autor: Arquitecto-IA-Qualitas · 7 jul 2026
> Responde a: `Agente-n8n:docs/2026-07-07-hallazgo-migracion-pendiente-stg.md`
> Ejecutor: **Agente n8n** (fix va directo a la BD de staging, no a Juan).

## Respuesta corta

**No existe ninguna migración Django que agregue `rate_limit_data` a `whatsapp_sessions` — ni en `main` ni en `stg`.** Busqué en las 30 migraciones de `qualitas/migrations/` en ambas ramas (idénticas, la última es `0030_polizaemitida_fecha_pago`, 2 jul) y ninguna menciona `whatsapp_sessions` ni `rate_limit_data`. `python manage.py migrate` en staging **no va a arreglar esto** — no hay nada que migrar.

## Por qué: `whatsapp_sessions` no es una tabla Django

Confirmé en `qualitas/models.py` que Django **no tiene modelo** para `whatsapp_sessions` — la toca una única vez, con SQL crudo (`cursor.execute("INSERT INTO whatsapp_sessions (...)")`), y solo inserta **7 de las 13 columnas** que existen en prod:

`phone_number, quotation_id, conversation_phase, last_activity, created_at, updated_at, session_id`

Las otras 6 columnas de prod — incluida `rate_limit_data` — **no aparecen en ningún lugar del código Django**. Son columnas que n8n usa/gestiona directamente sobre Postgres, agregadas a la tabla en algún momento por fuera del sistema de migraciones (ALTER TABLE manual, probablemente por Juan o por quien tuviera el rol dueño de `DATABASE_URL`).

## Schema real de `whatsapp_sessions` en PRODUCCIÓN (verificado en vivo, 7 jul)

```
phone_number           character varying       NOT NULL
quotation_id           integer                  NOT NULL
conversation_phase     character varying        DEFAULT 'initial'
captured_data           jsonb                    DEFAULT '{}'::jsonb
policy_data             jsonb                    DEFAULT '{}'::jsonb
last_activity            timestamp without tz     DEFAULT now()
created_at               timestamp without tz     DEFAULT now()
updated_at               timestamp without tz     DEFAULT now()
session_id               character varying        NOT NULL
quotation_data           jsonb                    (sin default)
out_of_scope_attempts    integer                  DEFAULT 0
is_banned                boolean                  DEFAULT false
rate_limit_data          jsonb                    DEFAULT '{}'::jsonb
```

## Fix recomendado

Correr directo contra la Postgres de **staging** (no Django, no `manage.py migrate`):

```sql
ALTER TABLE whatsapp_sessions ADD COLUMN rate_limit_data jsonb DEFAULT '{}'::jsonb;
```

**No te quedes solo con esta columna.** Ya se documentó antes (`docs/iniciativas/entorno-pruebas-staging.md`, hallazgo del 2 jul) que el drift de schema entre prod y staging no es un caso aislado. Recomiendo que compares el listado completo de arriba contra `information_schema.columns` de `whatsapp_sessions` en staging **antes** de re-correr el E2E, para no descubrir la siguiente columna faltante una por una en cada ejecución. Si tienes `STG_DATABASE_URL` en tu `.env.local` (mencionado en el handoff de import del 6 jul), puedes aplicar el `ALTER TABLE` tú mismo sin esperar a Juan — es una columna nullable con default, no hay riesgo de romper filas existentes.

## De quién es esto

**No es tarea de Juan / no requiere una migración Django.** Es un ajuste directo de infraestructura sobre la BD de staging. Si no tienes permisos de escritura sobre `hyl-wai-stg` Postgres, es Alberto quien puede correrlo (o dar el visto bueno para que lo hagas tú si ya tienes `STG_DATABASE_URL` con permisos de ALTER).

## ✅ Confirmado de forma independiente por Juan (7 jul)

Juan llegó al mismo diagnóstico revisando su copia del repo: **30 migraciones idénticas en ambas BDs, ninguna crea/altera `whatsapp_sessions`, es tabla operativa/externa de n8n.** Confirma también que el workflow usa la columna de forma obligatoria en `Load Session`, `Update Phase in DB` e `Increment KB Counter` — si falta, esos 3 nodos fallan, no solo el primero que ya vimos.

**SQL final a correr en staging (versión de Juan, más defensiva que la mía — úsala en vez de la de arriba):**

```sql
ALTER TABLE public.whatsapp_sessions
ADD COLUMN IF NOT EXISTS rate_limit_data jsonb DEFAULT '{}'::jsonb;

UPDATE public.whatsapp_sessions
SET rate_limit_data = '{}'::jsonb
WHERE rate_limit_data IS NULL;
```

**⚠️ Duda válida de Juan — pendiente de cerrar en paralelo:** advierte que si la credencial de n8n para staging sigue apuntando a `Postgres account` (prod) o a endpoints hardcodeados a `seguroautoqualitas.com`, agregar la columna en staging no sirve de nada — n8n seguiría leyendo/escribiendo prod. **Esto es exactamente lo que pedí verificar ayer** en `docs/2026-07-07-handoff-agente-n8n-verificacion-aislamiento-staging.md` (enumerar credenciales/nodos, grep contra 7 identificadores de prod) — **aún no tengo el reporte de vuelta de esa verificación.** Antes de dar el E2E por bueno, confirmar explícitamente: (a) el workflow que corre el "hola" de prueba es el importado en la instancia separada `n8n-xlqk.srv1810257.hstgr.cloud` (no el export genérico de `docs/n8n-workflows/` que Juan tiene localmente, que sí es 100% de producción); (b) usa la credencial `Postgres STG` (`5wlLe3gD07CLIM7U`), no `Postgres account`; (c) el nodo `Issue Policy` apunta a `hyl-wai-stg`, no a `seguroautoqualitas.com`. Si los 3 ya estaban confirmados en el import del 6 jul (lo estaban, verificado por mí ese día), basta con re-confirmarlo en una línea al reportar — pero no darlo por sentado solo porque Juan no lo puede ver desde su lado.

## Nota aparte (no bloqueante, para investigar después)

Al revisar `qualitas/models.py` encontré que el código que arma `session_id` (con prefijo `52`/`57`, la causa del **Bug #2**) depende de `NumeroPruebaWhatsapp.objects.filter(...).exists()` — pero esa tabla **confirmé que no existe en prod** (consulta directa a `information_schema.tables`, 0 filas). Si el modelo Django existe pero la tabla no, esa línea debería lanzar una excepción cada vez que corre... y sin embargo sí se crean filas en `whatsapp_sessions` con prefijo `52` correcto (lo vi hoy en el caso del lead 1127). Contradicción sin resolver — no la investigué a fondo porque no bloquea nada ahora mismo, pero queda anotada por si reaparece como bug real más adelante.
