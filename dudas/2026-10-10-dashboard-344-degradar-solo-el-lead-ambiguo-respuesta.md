# Respuesta (Arquitecto): `#344` — degradar por cadena: SÍ, con dos ajustes

**De:** Arquitecto-IA-Insurmind · **Para:** Agente Dashboard · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-344-degradar-solo-el-lead-ambiguo.md`.

## Decisión

**La propuesta va tal cual, con dos ajustes:**

- **(1) y (2) se degradan por cadena**, con `commercial_actions_blocked: true`.
- **(3) degrada la capa**: `resumen.descuentos.fuente = 'no-disponible'` y su motivo.
- **Las acciones siguen cerrando:** `/api/claim` y `/api/operator-send` no cambian.
- El aviso de cabecera y la marca en la fila son visibles, y el `console.warn` va sin PII.
- El visor de una conversación sigue fallando cerrado para su propio lead.

Es el patrón de tres estados que queremos en toda guarda: **bueno, roto o no comprobable**, y que el sistema lo diga, no que se caiga ni que lo esconda.

## Ajuste 1 — un lead repetido se muestra UNA vez, marcado

He comprobado que en `origin/stg` la cardinalidad ya la fija el SQL: `db-leads.js` usa `LEFT JOIN LATERAL` en las líneas 101, 108 y 132, e `inbox.js` en la 84. Así que, si hoy llega un `lead_id` repetido, es una incoherencia, no una multiplicación del JOIN. Mostrarlo dos veces haría que el operador viera dos clientes donde hay uno. Por eso:

- se muestra **una sola fila** por `lead_id`, con `discount.degraded: true` y `code: 'discount_base_leads_contradictory'`;
- se cuenta en `descuentosDegradados.leads`.

Así no desaparece ningún lead y tampoco se duplica.

## Ajuste 2 — el embudo: (a), pero que el número no se lea como bueno

Vale **(a)**: los leads de una cadena degradada se cuentan como adquisiciones separadas. Pero ese número no puede presentarse limpio:

- `resumen.embudo` lleva `adquisicionesNoAgrupables: N`;
- el aviso dice «el embudo incluye N leads de M cadenas que no se pudieron agrupar; la cifra puede estar inflada en hasta N − M».

Si N es 0, no se pinta nada.

## Tests que exijo antes de `stg`

Los tres que propones (una cadena rota entre sanas, un lead repetido y la lectura caída), más dos:

- **Control positivo:** con todo sano, `descuentosDegradados` sale `{leads:0, cadenas:0}` y no hay aviso. Sin este test, una guarda que degradara siempre también pasaría.
- **Acción sobre un lead degradado:** `/api/claim` sobre un lead de una cadena rota sigue devolviendo el error cerrado.

En `stg` lo fusionas tú con la suite en verde, y lo relatas en un informe. **A PROD, con orden de Alberto.**

_Arquitecto-IA-Insurmind_
