# Handoff Arquitecto → Agente n8n — Verificación de aislamiento 100% del entorno de staging

> Autor: Arquitecto-IA-Qualitas · 7 jul 2026
> Ejecutor: **Agente n8n** (vía API contra la instancia de staging).
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-07-handoff-agente-n8n-verificacion-aislamiento-staging.md` — deja también copia en `Agente-n8n/handoffs/`.
> Iniciativa madre: `docs/iniciativas/entorno-pruebas-staging.md`.

## Objetivo

No asumir el aislamiento del 6 jul como definitivo. Confirmar, con evidencia de API fresca, que **la instancia de staging de n8n no tiene ninguna referencia viva a producción** — ni en workflows, ni en credenciales, ni en el propio trigger. Esto es una auditoría, no la activación E2E (esa sigue bloqueada por la Meta App de Juan — fuera de alcance aquí).

## Por qué importa (contexto de riesgo)

El **Bug #12** fue exactamente esta clase de fallo: un duplicado de staging compartía `webhookId` con producción y, al tocarlo, dejó producción huérfana (2 apagones de inbound en una semana). La instancia de staging actual ya nació separada para evitar la clase de fallo — pero eso no garantiza que cada detalle esté limpio. Encontramos uno ya: el workflow importado el 6 jul **hereda el `webhookId` `18c1b498…` de producción** en el nodo `WhatsApp Message Trigger`, aunque está inactivo y sin credencial. Hay que asumir que puede haber más detalles así hasta que se verifiquen uno por uno.

## Estado de partida (verificado por el Arquitecto al 6 jul, re-verificar todo)

- Instancia: `https://n8n-xlqk.srv1810257.hstgr.cloud` (Hostinger `srv1810257`, ≠ prod `srv1325340`).
- Workflow: `WhatsApp Insurance Quotation Bot_stg` · id `dNqtM20ij6ecZYAX` · inactivo · 61 nodos.
- Credenciales creadas: Postgres STG `5wlLe3gD07CLIM7U`, Anthropic STG `aHI51VvnRnPixCx5`.
- 2 nodos WhatsApp sin credencial (a propósito, pendientes de Meta App).

## Identificadores de PRODUCCIÓN — ninguno debe aparecer en staging

| Tipo | Valor prod | No debe aparecer en |
|---|---|---|
| Instancia n8n | `n8n.srv1325340.hstgr.cloud` | ninguna URL/host de nodo en stg |
| Credencial Postgres | id `FbodkhT9DijVcqpB` | `credentials.postgres.id` de ningún nodo en stg |
| Credencial Anthropic | id `aWrCOYz0wHIk5GSd` | `credentials.anthropicApi.id` de ningún nodo en stg (si se reusó la key de prod dentro de una credencial STG nueva, el **id de credencial** debe ser el nuevo `aHI51VvnRnPixCx5`, nunca el id de prod) |
| Credencial WhatsApp Trigger | id `bUWR11VM0seHo63P` | cualquier nodo en stg |
| Credencial WhatsApp Send | id `PbzXr53disA74eew` | cualquier nodo en stg |
| Host Django prod | `seguroautoqualitas.com` | cualquier parámetro/URL de nodo en stg |
| phoneNumberId prod | `1028815256982638` | cualquier parámetro de nodo en stg |
| webhookId prod (Bug #12) | `18c1b498…` (prefijo) | el campo `webhookId` de CUALQUIER trigger en stg |

## Tareas

**1. Regenerar el `webhookId` del `WhatsApp Message Trigger` ahora mismo** (no depende de la Meta App — es un campo del nodo, no requiere credencial válida). Nuevo UUID v4, distinto de `18c1b498…`. Esta es la tarea 1 del handoff E2E v2 (`docs/2026-07-06-handoff-agente-n8n-fase-e2e-staging-bug10.md`) adelantada porque no tiene dependencia real con el resto de esa fase.

**2. Enumerar TODO lo que existe en la instancia stg vía API** (no dar por buena la memoria del 6 jul):
   - `GET /api/v1/workflows` → listar todos (esperado: solo 1, `dNqtM20ij6ecZYAX`; si aparece más de uno, reportarlo — no debería haber duplicados).
   - `GET /api/v1/credentials` → listar todas (esperado: Postgres STG + Anthropic STG; cualquier credencial adicional no documentada aquí es una alerta).

**3. Para el workflow `dNqtM20ij6ecZYAX`, recorrer TODOS los nodos y grep contra la tabla de identificadores de prod de arriba** — no solo los 6 valores que se chequearon el 6 jul, sino cualquier string que contenga `seguroautoqualitas`, `1028815256982638`, `srv1325340`, o los 4 ids de credencial de prod. Reportar cero o el detalle exacto de qué nodo/campo si aparece algo.

**4. Confirmar que las 2 credenciales STG (`Postgres STG`, `Anthropic STG`) están referenciadas por su **id de staging**, no el de prod, en cada uno de los nodos que las usan (9 Postgres + 4 Anthropic, según el manifiesto del 6 jul).

**5. Confirmar `active: false`** en el workflow — no debe quedar activo por accidente antes de completar la fase E2E (con 2 nodos WhatsApp sin credencial, activarlo ahora fallaría o quedaría en estado inconsistente).

**6. Confirmar que NINGÚN workflow de la instancia de staging (ni ningún otro objeto con webhook) usa un `webhookId` que coincida, ni siquiera parcialmente, con el `18c1b498…` de prod** — tras la tarea 1 esto debería ser trivialmente cierto, pero verificarlo explícitamente vía API.

## Fuera de alcance (no hacer aquí)

- Crear credenciales WhatsApp ni activar el workflow (bloqueado por Meta App — Juan).
- Importar los otros 2 workflows (Payment Confirmation, Retomar Conversacion).
- Cualquier cambio en la instancia de PRODUCCIÓN — esta tarea es de solo lectura/verificación sobre prod, y de edición solo sobre stg.

## Reporte esperado (al Arquitecto vía Alberto)

Una tabla PASS/FAIL por cada una de las 6 tareas, con el detalle concreto (ids, valores encontrados) de cualquier FAIL. Si todo es PASS: confirmación explícita de "0 referencias a producción encontradas en la instancia de staging" + el nuevo `webhookId` generado en la tarea 1.
