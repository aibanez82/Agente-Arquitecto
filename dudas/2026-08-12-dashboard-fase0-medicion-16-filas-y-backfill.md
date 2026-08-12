# Duda — Dashboard · Fase 0: la medición de las 16 filas, y el backfill que propongo

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Sobre:** handoff `2026-08-12-fase0-migracion-claims-paridad-prod.md`, §3.
**Estado:** no me bloquea; sigo construyendo la migración y su acreditación efímera mientras respondes.

---

## 1. La medición: te la pido, porque no tengo acceso

Tu §3 dice «si no tienes acceso, pídemelo en una duda y lo saco yo». **No lo tengo**: sigo bajo cero
accesos vivos, y además en PROD el rol `readonly_leads` no puede leer esta tabla (lo comprobamos el
10 ago). Las tres consultas, todas SELECT puro sobre 16 filas:

```sql
-- a) ¿Cuántas están liberadas en la semántica vieja?
SELECT count(*) AS total,
       count(*) FILTER (WHERE released_at IS NOT NULL) AS liberadas,
       count(*) FILTER (WHERE released_at IS NULL)     AS vivas
FROM public.dashboard_conversation_claims;

-- b) ¿Hay duplicados de session_id entre las que quedarían 'active'?
SELECT session_id, count(*) AS veces
FROM public.dashboard_conversation_claims
WHERE released_at IS NULL
GROUP BY session_id HAVING count(*) > 1;

-- c) Lo mismo por lead_id (uq_claims_active_lead es igual de parcial)
SELECT lead_id, count(*) AS veces
FROM public.dashboard_conversation_claims
WHERE released_at IS NULL
GROUP BY lead_id HAVING count(*) > 1;
```

Las dos últimas filtran por `released_at IS NULL` **a propósito**: son las que quedarían `active` *si*
se aplica el backfill de abajo. Sin backfill, las 16 quedarían activas y habría que correrlas sin el
`WHERE` — que es justamente el escenario que hace fallar la creación de los índices.

## 2. El backfill que propongo, declarado y no incrustado

```sql
UPDATE public.dashboard_conversation_claims
   SET state = 'released'
 WHERE released_at IS NOT NULL;
```

**En la misma transacción y ANTES de crear los índices parciales**, como dices.

**Por qué este y no otro:** en la semántica vieja `released_at IS NOT NULL` significaba exactamente
«esta toma ya no está vigente». El `DEFAULT 'active'` de la columna nueva es correcto para las filas que
no tienen `released_at`, y erróneo para las que sí — no porque el default esté mal elegido, sino porque
un default no puede leer otra columna. El backfill no *decide* nada nuevo: **traduce** un estado que ya
estaba escrito, en otra forma.

**Lo que este backfill NO hace, y quiero que conste:** no distingue `released` de `revoked` ni de
`expired`. La semántica vieja no guardaba esa diferencia —solo había una fecha— así que reconstruirla
sería inventar. Todas las liberadas históricas quedan como `released`, que es el término neutro de los
tres.

**Alternativa que descarto:** dejar las 16 en `active` y arreglarlo después. Además de ser falso (una
toma con `released_at` no está activa), rompería la creación de los índices parciales si hubiera
cualquier repetido, que es exactamente lo que tu §3.3 anticipa.

## 3. Y si hay duplicados entre las activas de verdad

Tu §3.3 dice que pare y lo diga. **Lo haré**: la migración llevará una **guarda que aborta la
transacción entera** si, tras el backfill, quedara más de una fila `active` por `session_id` o por
`lead_id`, nombrando cuál. Prefiero que la Fase 1 falle en la ventana con un mensaje exacto a que cree
un índice a medias o, peor, que alguien resuelva el duplicado a ojo.

Si la medición (b) o (c) devuelve filas, no propongo remedio: es una decisión sobre datos vivos de
producción y no es mía.

## 4. Mientras tanto

Construyo la migración con el backfill **como sección propia y señalada** —no escondido en el flujo— y
la acredito reproduciendo la forma de PROD en PostgreSQL efímero, incluidas filas con `released_at`
puesto. Si decides otro backfill, se cambia una sección aislada y la acreditación se vuelve a correr.

Confirmo también que respeto los tres límites del §2: `conversation_id` se queda en **`varchar(64)`**
(nada de 80, eso es de #156), **no** añado `CHECK(epoch>0)` ni `UNIQUE(session_id, epoch)`, y **no toco**
`dashboard_claims_active_idx`. Si resulta redundante con `uq_claims_active_lead`, lo anoto en la entrega
y no lo borro.
