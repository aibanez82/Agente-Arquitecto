# Duda (Dashboard): `#587` — cómo medir (a), (b) y (d) sin tocar el token de Meta

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Issue:** [HYL-WAI#587](https://github.com/aguayo-co/HYL-WAI/issues/587), asignado a aibanez82. Sin secretos.

## Lo que ya está medido

- PROD `/api/meta-analytics` → 500 `Meta API error: template_ids` (con la sesión de Alberto, 10 oct).
- **Código:** `getTemplateIds()` (`apps/operacion/lib/meta.js:12`) pide `message_templates` con **`limit: 20`** y manda **todos** los IDs en
  `template_ids`. Es la única fuente de esos IDs.
- **Documentación:** `template_analytics` admite **como máximo 10** `template_ids` por petición (360dialog, Vonage; citado en el issue).
- **(c) desde cuándo:** **sin medir**. `vercel logs` no funciona con el token de equipo, y el endpoint solo registra `err.message`.

Encaja con la hipótesis, pero **no** separa las alternativas: un token caducado, un permiso retirado o un cambio de versión de la Graph API
también podrían dar un error en `template_ids`.

## Por qué no puedo medir el resto sin tu decisión

`META_ACCESS_TOKEN` es `sensitive` en Vercel (Preview y Production) y es de Juan: no lo leo. Solo lo usa código desplegado. Así que (a)
la respuesta literal, (b) el número de IDs y (d) el control solo se miden de una de estas formas:

- **(1) Diagnóstico en el Preview de `stg`.** Es un cambio de código, por eso te pregunto. `/api/meta-analytics` devolvería, solo cuando
  se pide con `?diagnostico=1` y solo para el rol admin: `error.code`, `error.error_subcode`, `error.type`, `error.message`,
  `fbtrace_id`, el número de IDs que devuelve `message_templates` y si trae más páginas (`paging.next`). Nunca el token, la URL ni los IDs.
  Para **(d)**, `?max_ids=N` limitaría los `template_ids` enviados: con N=10, si da 200, hipótesis confirmada; si sigue fallando, es otra
  cosa. Rama → `stg`, sin `main`. Lo pruebo con la sesión de Alberto en el Preview y lo retiro, o se queda como control, según digas.
- **(2) Que lo mida Juan**, que tiene el token: dos llamadas a la Graph API (el recuento de `message_templates` y `template_analytics` con
  10 IDs). Le escribiría el procedimiento exacto en el issue.

Prefiero **(1)**: no depende de nadie más y deja el diagnóstico escrito. ¿Lo autorizas, o vamos por (2)?

Agente: Dashboard
