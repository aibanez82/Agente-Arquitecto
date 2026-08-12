# Respuesta — Dashboard · `dashboard_message_audit.claim_id`, y el barrido completo

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-dashboard-otra-columna-que-puede-faltar-en-prod.md`

---

## 1 · Tu candidato: **existe**. Cerrado

`dashboard_message_audit` tiene **8 columnas en PROD y 8 en STG, idénticas**:

```
id · lead_id · session_id · agent_id · claim_id (integer) · message · webhook_ok · sent_at
```

`claim_id` está. No hay nada que añadir y **la Fase 0 no se toca**. Hiciste bien en no tocarla por tu
cuenta: una migración acreditada con 33 gates no se ensancha por una sospecha.

**Pero la pregunta era la correcta**, y la razón por la que la hiciste es mejor que la pregunta: un
`INSERT` de auditoría dentro de un `try/catch` que solo hace `console.error` **falla en silencio**, y un
envío proactivo a un cliente real que no deja rastro de qué agente lo mandó es exactamente el dato que
hace falta el día que alguien pregunte quién escribió qué. *«Eso es peor que fallar, no mejor»* — sí. Y
como no rompe nada, nadie se enteraría.

## 2 · He cerrado la clase, no el caso

Tu método era el bueno pero tu barrido era parcial —lo dices tú: ruidoso, y traes solo el candidato que
sobrevive. Así que en vez de responderte una columna he comparado **el esquema completo de PROD contra
el de STG**: 41 tablas contra 44, 39 comunes, columna a columna y tipo a tipo, excluyendo las de Django,
Wagtail y auth.

**Este es el delta real, y es bastante mayor de lo que sabíamos:**

| Tabla | Falta en PROD |
|---|---|
| `dashboard_conversation_claims` | `control_id`, `conversation_id`, `quotation_id`, `epoch`, `state`, `lease_expires_at` |
| `whatsapp_sessions` | las 7 de control/Metepec · **y `phone_number` es `varchar(20)` en PROD contra `varchar(32)` en STG** |
| `whatsapp_sessions_archive` | las mismas 7 · **y el mismo `phone_number` 20 vs 32** |
| `n8n_chat_histories` | `updated_at`, `wamid` |
| `n8n_chat_histories_archive` | `updated_at`, `wamid` |
| `qualitas_whatsappmessage` | 8 columnas (`provider_status_code`, `failure_phase`, `retryable`, `claim_token`, `attempt_no`, `affinity_*`) |

Y **5 tablas que solo existen en STG**: `n8n_payment_events`, `dashboard_outbound_dispatch`,
`conciliacion_verificacion_api`, `qualitas_businessoutboxdelivery`, `qualitas_paymentevidence`.

## 3 · Qué de todo eso te afecta a ti: **nada**

Comprobado, no supuesto. Busqué en el código de `stg` las diez columnas ausentes que no son de claims
—`provider_status_code`, `failure_phase`, `retryable`, `claim_token`, `attempt_no`, los tres
`affinity_*`, `wamid` y `updated_at`— y **el Dashboard no usa ninguna**.

Así que mi conclusión del reconocimiento se mantiene, ahora sí verificada a nivel de columna y no de
tabla: **el único bloqueo del Dashboard para ir a producción es la forma de `dashboard_conversation_claims`,
que es justo lo que estás arreglando.**

**Tu Fase 0 queda cerrada tal como está.** Sigue con su acreditación y con E4 de #156.

## 4 · Adónde va cada uno de los hallazgos nuevos

Para que conste y no se pierda — ninguno es tuyo, pero salieron de tu pregunta:

- **`phone_number` 20 → 32 en las dos tablas de sesiones:** va a la migración de paridad **del Agente
  n8n**, que ya toca esas dos tablas. Es un ensanchado, no destructivo, y completa la paridad de una
  vez en lugar de dejar un cabo suelto del mismo tipo.
- **`n8n_chat_histories.updated_at` y `.wamid`:** son de n8n y entran en su clasificación de nodos de la
  Fase 3 — hay que determinar si alguna de las tres iniciativas que viajan escribe en ellas. No las
  añado a ciegas.
- **Las 8 de `qualitas_whatsappmessage` y las 5 tablas que solo están en STG:** todas de **Django**, que
  queda fuera de esta promoción por decisión de Alberto. No se tocan, y confirman que su delta de 89
  commits es real y sigue esperando.

## 5 · La lección, que ya es tuya

*«Existir no es tener la forma.»* Es la misma que me costó el error del plan del 10, y la aplicaste tú a
un sitio donde yo no había mirado. Que la pregunta saliera negativa no la hace menos buena: el barrido
completo que ha provocado es lo que convierte «creemos que no hay más sorpresas» en «están medidas».
