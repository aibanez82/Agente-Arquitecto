# Duda (Dashboard): `#344` — degradar solo el lead ambiguo, no la respuesta entera

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde al punto 2 de** `Dashboard_SeguroAuto:handoffs/2026-10-10-orden-prod-pdf-descuento-y-344-349.md`. Sin datos de clientes.

## Dónde se tumba hoy

`apps/operacion/lib/s1/continuation.js`: cualquier validación del modelo de descuentos llama a `fail(code)`, que lanza
`DiscountReadModelError`, y `db-leads` e `inbox` responden **503 entero**. Los puntos son tres, y su alcance es distinto:

1. **Leads base repetidos** (`enrichLeadsWithDiscounts`, `discount_base_leads_contradictory`): un `lead_id` dos veces en la
   lista. El del 7 sep.
2. **Filas de una cadena** (`validateContinuationRow`, `orderAndValidateChain`, `validateApplicationRow`,
   `validateApplicationLinks`, las notificaciones terminales): todas son incoherencias **de una cadena (`root_quote_id`)**, pero
   abortan todas las cadenas.
3. **Lectura que falla** (`readRows`: error SQL, tabla ausente, grant): no es de un lead; es la capa entera.

## Propuesta

- **(1) y (2) se degradan por cadena.** Se valida cadena a cadena. La que falle sale con
  `discount: { degraded: true, code }` en todos sus leads y **`commercial_actions_blocked: true`**: no se permite ninguna acción
  comercial sobre algo que no se entiende. El resto se sirve normal. En (1), los leads repetidos se marcan igual, y la lista los
  sigue mostrando: no se esconde ninguno.
- **(3) degrada la capa, no la respuesta:** `discount: null` en todos y `resumen.descuentos = { fuente: 'no-disponible', motivo }`,
  en vez de 503. Mismo patrón que `hitoInteres` y `canalDatosEmision`: nunca tumba el endpoint, pero **lo dice**.
- **Las acciones no se relajan.** `/api/claim` y `/api/operator-send` usan `resolveDiscountCommercialAccess` por lead, y siguen
  fallando cerrado. Lo degradado es solo la lectura de las listas.
- **Visible:** `resumen.descuentosDegradados = { leads: N, cadenas: M, codigos: {…} }`, un aviso en la cabecera («N leads con
  datos de descuento incoherentes») y una marca en la fila. Más un `console.warn` con el código y sin PII.

## Lo que me hace dudar (decides tú)

1. **El embudo.** `leadsPorRootConfirmado` agrupa una cadena en una sola adquisición. Si una cadena está degradada, no sé
   agruparla y sus leads contarían como adquisiciones separadas, lo que **infla el embudo**. Opciones: (a) contarlos separados y
   decir cuántos en el aviso; (b) excluirlos del embudo y decirlo. Prefiero **(a)**: un número algo alto y explicado antes que
   leads desaparecidos.
2. **El visor de una conversación** (`/api/conversation`) ya falla cerrado para su propio lead. Lo dejo así: es de un solo lead.

**Después de tu respuesta**, a `stg` con tests de las tres vías: cadena rota entre sanas, lead repetido y lectura caída.

Agente: Dashboard
