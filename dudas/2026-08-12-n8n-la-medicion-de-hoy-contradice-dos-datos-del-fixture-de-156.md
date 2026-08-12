# Duda — la medición en vivo de hoy contradice dos datos del fixture de `#156`

**12 ago 2026 · Agente n8n · NO bloqueante:** la Fase 0 va entregada, y los dos cabos caen fuera de
su alcance cerrado. Lo que puede estar mal es lo que **`#156` cree** del esquema de STG.

Handoff `2026-08-12-fase0-migracion-sessions-paridad-prod.md` + su adenda (`45e0bec`).
Entrega: rama `fix/fase0-sessions-paridad-prod@94d53b5`, doc `docs/fase0/entrega-sessions-paridad.md`.

## De dónde sale la contradicción

Para escribir la migración de paridad usé dos mediciones que **concuerdan en todo lo que la Fase 0
necesita** —las 17 columnas de PROD, las 7 ausentes, la aritmética del archive—:

- **M1** — tu medición en vivo de los dos catálogos, hoy 12 ago.
- **M2** — la evidencia versionada del esquema de STG que ya usé en `#156` E2, con procedencia por
  columna: `Agente-n8n@8440923:scripts/156/test/lib/fixtures.js` (E1 extracción real del DDL de STG
  28 jul · E2 ventana STG 30 jul · E3 migraciones Django 0032/0033).

Concuerdan en PROD. **Discrepan en dos datos de STG**, y los dos son de M2, o sea de lo que `#156`
da por cierto:

| Cabo | M2 (28–30 jul, versionada) | M1 (hoy, en vivo) |
|---|---|---|
| 1. `human_takeover` y `metepec_derived` en `whatsapp_sessions_archive` de **STG** | **ausentes** — es mi GAP-B, «el archive tiene el token sin la bandera» | **presentes**, nullable y sin default (26 columnas) |
| 2. `phone_number` en **STG** | `varchar(20)` | `varchar(32)` |

La aritmética de M1 solo cuadra si el cabo 1 es cierto: 17 de negocio + 7 + `archive_id` +
`archived_at` = **26**, que es lo que mides. Con el archive sin las dos banderas saldrían 24.

## Por qué importa, y a qué

**A la Fase 0, en nada:** en PROD faltan las siete en las dos tablas, medido en vivo hoy, y eso no lo
discute ninguna de las dos mediciones. La migración entregada las añade y ensancha `phone_number`
desde `varchar(20)`, que es el valor en el que M1 y M2 **sí** coinciden para PROD.

A `#156` sí, por dos vías:

1. Si M1 tiene razón en el cabo 1, **el paso P2 de `migrations/156/001-readiness` es hoy un no-op en
   STG**, y GAP-B lo cerró alguien después del 30 jul **sin dejar migración** — exactamente el patrón
   que la Fase 0 existe para desmontar. El fail-first de mi suite de `#156` afirma que el archive
   entra sin las banderas: contra el STG de hoy, ese fixture describiría un pasado.
2. El fixture de `#156` dice `varchar(20)` para `phone_number` de STG. Si son 32, ese dato está
   caduco igual.

## Lo que pregunto

1. **¿Cuál de las dos mediciones vale para el archive de STG?** Si vale la tuya, ¿quién y cuándo
   añadió esas dos banderas? Me importa menos el culpable que si hay **más** cambios de ese lote sin
   registrar, porque entonces M2 está caduca en más sitios que estos dos.
2. **¿Corrijo el fixture de `#156`?** No lo he tocado por iniciativa propia: la rama está **entregada
   y pendiente de dictamen** (`informes/2026-08-12-n8n-156-e1-e7-informe.md` sobre `8440923`), y
   cambiar un fixture ahí mueve lo que está a revisión. Si quieres que se corrija, dímelo y va en un
   commit propio con su nota, no colado en otro cambio.
3. **¿Hay que re-medir STG entero antes de la Fase 1**, con el mismo método de columna a columna que
   usaste para PROD? Tú comparaste PROD **contra** STG, así que la foto de STG ya la tienes; lo que
   no sé es si la diste por buena o solo la usaste como referencia del delta.

## Lo que hago mientras

Nada de esto me para. Sigo con lo que el handoff manda si termino: la **clasificación de los 39 nodos
con parámetros distintos**, incluida la pregunta diferida de tu adenda —si Retomar, Atención Humana o
Multicotización leen o escriben `updated_at`/`wamid` en `n8n_chat_histories` y su archive, que en PROD
no existen—.
