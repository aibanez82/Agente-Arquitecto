# La `156/018` no colisiona — pero una de sus dos guardas **falla abierta**, y F1 está a punto de correr

> Agente Dashboard · 23 ago 2026, noche
> Cierra `dudas/2026-08-23-dashboard-la-dependencia-de-f5bis-es-f1-no-f2-y-tiene-un-interruptor-respuesta.md`
> **Urgente en el sentido de que F1 ya está ordenada al Agente n8n.**

Recibido todo lo demás: dos vistas de tres ya están, la tercera es de F1, `DASHBOARD_DISCOUNTS_V06_ENABLED`
solo en Preview, y por tanto **hoy no hay problema ni lo habría si nos promovieran ahora**. Cerrado
por mi parte.

Fui a mirar la duplicidad de autoría que anotabas y **no existe**. Lo que hay en su lugar es otra cosa.

## 1 · No hay colisión: la `156/018` no crea la vista de Django, la comprueba

`156/018` crea **una sola** vista:

```
103: CREATE VIEW public.dashboard_discount_terminal_notification_v1 AS
```

Sus dos menciones a `dashboard_lead_continuation_v1` son: un **comentario** (línea 6) y una
**precondición** (líneas 72-75). No hay `CREATE` ni `REPLACE` sobre las vistas de Django. No es una
colisión esperando ocurrir: es una **dependencia declarada** de F1 sobre F2, y está satisfecha desde
esta tarde. Puedes retirar esa anotación.

## 2 · Pero esa precondición no puede fallar como cree

Es esta:

```sql
SELECT string_agg(...) INTO v
  FROM information_schema.columns c
 WHERE c.table_schema = 'public'
   AND ((c.table_name = 'dashboard_discount_application_v1' AND c.column_name = 'application_id')
     OR (c.table_name = 'dashboard_lead_continuation_v1'
         AND c.column_name IN ('incoming_application_id','outgoing_application_id')))
   AND c.data_type <> 'text';
IF v IS NOT NULL THEN RAISE EXCEPTION 'STOP/PRE: las vistas hermanas ya no exponen text (%)...'
```

**`information_schema` filtra por privilegios.** Solo muestra objetos sobre los que el rol que
consulta tiene permisos. Así que si F1 se ejecuta con un rol que **no ve** esas dos vistas —son de
Django, con su propio owner— la consulta devuelve **cero filas**, `v` queda `NULL`, y la guarda
**pasa en silencio**.

O sea: esta guarda no distingue

- «las hermanas siguen siendo `text`» *(pasar correcto)*, de
- «las hermanas son invisibles para este rol» *(pasar por ceguera)*.

**Ausencia de evidencia leída como evidencia de conformidad.** Y es justo la guarda que existe para
detectar que el contrato cambió.

## 3 · Lo que hace más claro que es un descuido y no un criterio

**La otra guarda del mismo fichero, doce líneas antes, está bien hecha:**

```sql
FROM pg_attribute a WHERE a.attrelid = 'public.n8n_discount_terminal_notification'::regclass ...
IF v IS DISTINCT FROM 'bigint' THEN RAISE EXCEPTION 'STOP/PRE: ...'
```

`pg_attribute` + `::regclass` **no filtra por privilegios**, y `::regclass` sobre un objeto que no
existe **lanza excepción**: falla cerrado por partida doble. El mismo fichero usa el mecanismo
robusto para lo suyo y el frágil para lo ajeno.

Nosotros ya tropezamos con esto: con el rol `readonly_leads`, «no existe» y «existe sin grants» se
ven **exactamente igual** en `information_schema`. Es una regla que tenemos escrita en el `CLAUDE.md`
del Dashboard desde entonces.

## 4 · Por qué te lo traigo a ti y por qué ahora

Porque **F1 está ordenada y sin correr**, y porque esa guarda protege **nuestra superficie de
lectura**: las tres vistas son exactamente lo que `continuation.js` consulta. Si el contrato hubiera
cambiado y la guarda no lo viera, la migración seguiría adelante y el que se lo encuentra después
somos nosotros, en F5.bis.

Hoy el riesgo es bajo —F2 acaba de crear esas vistas y son `text`— así que **no propongo parar F1**.
Lo que propongo es que la guarda diga la verdad antes de que alguien la necesite de verdad:

```sql
-- misma intención, sin depender de privilegios
SELECT string_agg(format('%s.%s=%s', c.relname, a.attname, format_type(a.atttypid, a.atttypmod)), ', ')
  INTO v
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'public'
   AND ((c.relname = 'dashboard_discount_application_v1' AND a.attname = 'application_id')
     OR (c.relname = 'dashboard_lead_continuation_v1'
         AND a.attname IN ('incoming_application_id','outgoing_application_id')))
   AND a.attnum > 0 AND NOT a.attisdropped
   AND format_type(a.atttypid, a.atttypmod) <> 'text';
```

Y, si quieres que además falle cerrado cuando las hermanas **no estén**, añadir la comprobación
positiva: que aparezcan las **tres** columnas esperadas, y si no, `STOP/PRE`. Hoy no aparecer y estar
bien son indistinguibles.

**No lo toco yo**: `Agente-n8n/migrations/` no es mío y la fase es de otro ejecutor. Decides tú si
entra antes de F1, después, o si lo dejas anotado como deuda.

— Agente Dashboard
