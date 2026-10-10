# Informe (Dashboard): `#344` — una cadena incoherente degrada solo sus leads, en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a** `dudas/2026-10-10-dashboard-344-degradar-solo-el-lead-ambiguo-respuesta.md` (`312a4e7`).

## Estado

En `stg` = `3c4bace` (rama `fix/344-degradar-por-cadena`). Suite **864/864**, verificador y `build` en verde. **No está en `main`.**

## Qué hace (con tus dos ajustes)

- **Listas tolerantes** (`enrichLeadsWithDiscounts(…, { conResumen: true })`, usado por `db-leads` e `inbox`): se valida cadena a
  cadena (`root_quote_id`) con `loadDiscountReadModelsPorCadena`. Una cadena que falla deja sus leads con `discount: null`,
  `discount_degradado: { code }` y `commercial_actions_blocked: true`. El resto se sirve.
- **Ajuste 1:** un `lead_id` repetido sale **una sola vez**, marcado con `discount_base_leads_contradictory`.
- **Lectura caída** (error SQL, tabla ausente o algo no atribuible a ningún lead): `resumen.descuentosDegradados.fuente =
  'no-disponible'` y `capa = <código>`. Todos sin descuento y **200**, no 503.
- **Ajuste 2, el embudo (a):** los leads degradados cuentan como adquisiciones sueltas. El Resumen avisa, abrible para ver
  cuáles: «el embudo incluye N leads de M cadenas de descuento que no se pudieron agrupar; la cifra puede estar inflada en hasta
  N − M». Con 0 no se pinta. En la fila, la etapa lleva ⚠️ con el código al pasar el ratón.
- **`console.warn` sin PII:** solo códigos y recuentos.
- **No cambia:** `/api/claim` y `/api/operator-send` (`resolveDiscountCommercialAccess`, cerrado por lead) ni el visor de una
  conversación (`loadDiscountReadModels`, cerrado para su lead). Sin `conResumen`, `enrichLeadsWithDiscounts` sigue lanzando.

## Tests (los tuyos y los míos)

En `scripts/s1/test/continuation.test.js`, 8 nuevos: el **control positivo** (todo sano da `{leads:0, cadenas:0}` y sin capa),
**una cadena rota entre sanas**, una **semilla inválida**, un **lead repetido**, la **lectura caída**, que **el visor siga
fallando cerrado**, `db-leads` dando 200 con el recuento (y ceros cuando todo está sano), y **Tomar sobre un lead degradado**, que
sigue cerrado y sin llamar al webhook. He ajustado un test de texto (`descuento-lenguaje-ventas`) que fijaba la forma antigua
de la llamada.

**A PROD, con orden de Alberto.**

Agente: Dashboard
