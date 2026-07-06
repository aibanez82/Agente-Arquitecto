# Propuesta del Agente n8n — reconciliación + prep de deploy Bug #10

> Respuesta al handoff `docs/2026-07-05-handoff-despliegue-bug10-vin.md`.
> Autor: Agente n8n (Nivel 3) · Fecha: 5 julio 2026
> Destinatario: **Arquitecto-IA-Qualitas** (vía Alberto) — **pendiente de validación antes de ejecutar**.
> Estado: 🟡 propuesta, nada ejecutado.

---

## Verificación previa (hecha, no asumida)

Cotejé el ⚠️ Hallazgo del handoff contra el **JSON vivo** de la rama `stg` (repo `Agente-n8n`, commit `2570dea`, path `workflows/WhatsApp Insurance Quotation Bot.json`). **Confirmado punto por punto:**

- Las **4 menciones "5-20" reales existen** y conviven con las VIN-17 ya aplicadas (L185/L288/L382) → inconsistencia real: el prompt coacha "17" pero especifica el campo como "5-20" → una serie de 14 chars pasa el prompt y Django la rechaza → **loop muerto**. La reconciliación es **deploy-blocking**.
- Los otros **8 hits de "5-20" son falsos positivos**: IDs de modelo `claude-sonnet-4-5-2025…` / `claude-haiku-4-5-2025…` (L202, 547, 804, 1017, 2378, 2717, 2974, 3187). El descarte del handoff es correcto.
- Estado del JSON `stg`: `neverError:true` presente (L327), webhookId prod `18c1b498` presente (L453/L2623), `name` = `..._stg` (L4), `active:false` (L6), `id` eliminado.

> Nota: la memoria del handoff daba C2 ("4 menciones → VIN-17") por completo. **No lo estaba** — se cambiaron las de coaching, quedaron las 4 de spec de campo.

---

## A) Reconciliación del prompt — 4 ediciones exactas (Capa 3a)

En `workflows/WhatsApp Insurance Quotation Bot.json`, matcheando el wording canónico ya usado en L185 (*"exactamente 17 caracteres, sin espacios ni guiones y sin las letras I, O ni Q (el 9º carácter es un dígito o X)"*):

| # | Línea | Texto actual (literal) | Reemplazo propuesto |
|---|---|---|---|
| 1 | 2361 | `Número de serie del vehículo (5-20 caracteres alfanuméricos)` | `Número de serie / VIN del vehículo (exactamente 17 caracteres alfanuméricos, sin espacios ni guiones, sin I/O/Q, 9º carácter dígito o X)` |
| 2 | 2361 | `// Número de serie del vehículo (5-20 caracteres alfanuméricos, del Grupo 2)` | `// Número de serie / VIN del vehículo (exactamente 17 caracteres, del Grupo 2)` |
| 3 | 2361 | `**serie**: Número de serie proporcionado por el usuario en Grupo 2 (5-20 chars alfanuméricos)` | `**serie**: Número de serie / VIN proporcionado por el usuario en Grupo 2 (exactamente 17 caracteres alfanuméricos, sin I/O/Q)` |
| 4 | 2555 | `"description": "Vehicle serial/VIN number (5-20 alphanumeric characters)"` (inputSchema de `Validate`) | `"description": "Vehicle VIN — exactly 17 alphanumeric characters, no spaces/dashes, no I/O/Q, 9th char is a digit or X"` |

Coherentes con la regex canónica de Django `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$`. Commit en `stg`. **Mecánico y de bajo riesgo** — ejecutable en cuanto se apruebe.

---

## B) Prep de deploy a prod (Tarea 2) — 3 correcciones que el plan no explicita

El JSON `stg` tiene hoy `active:false`, `name` `..._stg`, `id` eliminado. Un PUT crudo de este body **desactivaría prod** (riesgo de repetir Bug #12). Antes del deploy dejaría:

- `active: true`
- `name`: `WhatsApp Insurance Quotation Bot` (limpio)
- `id` / URL: `BtOaZm7WlZT-24V7hqCnF`
- webhookId `18c1b498-024e-4803-8088-56ccf9812f33` y `neverError:true` → intactos.

⚠️ **Ojo técnico del n8n Public API:** `PUT /workflows/{id}` **NO** cambia el campo `active` (read-only en ese endpoint). La activación va aparte con `POST /workflows/{id}/activate`. Secuencia real:
`PUT` (nodes/connections/settings/name) → `POST /activate` → confirmar re-registro del webhook. **Validar esta secuencia.**

---

## C) Decisiones que necesita tomar el Arquitecto (no las toma el ejecutor)

1. **¿Directo a prod vía PUT, o pasada en staging primero?**
   El setup `_stg`/inactive se construyó para validar en staging, pero el plan salta a prod. El argumento se acepta (Django es el gate; peor caso = emisión atascada, no póliza mala; Bug #10 quema ~57% ahora), pero debe ser **decisión consciente**: la cadena `neverError→body→detección→re-pregunta` **nunca se ha corrido E2E**, y el propio handoff la marcó como "checkpoint crítico a validar en staging".
   - **Trampa si se elige staging:** este JSON lleva el webhookId **de prod**. Importarlo al staging `uOuB_…` **recrearía la colisión del Bug #12**. Si se valida en staging, hay que **quitar el webhookId** solo para esa importación.

2. **¿Reintegrar el `id` al JSON de `stg`** (abandona el diseño "import seguro crea nuevo"), o mantener `stg` como artefacto de import-seguro y generar un **JSON derivado solo-para-PUT**?
   Recomendación del ejecutor: si vamos por PUT-a-prod, restaurar name/active/id en `stg` y documentar que la ruta import-nuevo queda obsoleta.

3. **¿Ejecuta el PUT+activate el Agente n8n con `N8N_API_KEY`, o se dejan el JSON+comando listos para que Alberto los dispare?**

---

## D) Confirmado correcto en el handoff (sin cambios)

- Orden de rollout **n8n primero → Django justo después**.
- Estrategia PUT-a-prod (reusar id+webhookId, no crear workflow) **sí evita** recrear Bug #12.
- `neverError:true`, webhookId prod, regex canónica: presentes y correctos.
- Post-deploy: se mantiene **obligatorio** el check "hola" inbound (confirmar webhookId sigue `18c1b498`) por el antecedente del Bug #12.

---

## E) Cierre (tras validar en prod)

- Merge `stg`→`main` en `Agente-n8n`.
- Re-exportar el JSON final a `docs/n8n-workflows/` del repo Arquitecto (fuente de verdad sincronizada).

---

## Resumen para el Arquitecto

Diagnóstico del handoff **aprobado y verificado en el JSON vivo**. Se pide OK en: **(A)** las 4 ediciones exactas, **(B)** la secuencia `PUT` + `POST /activate` con `active:true`, y las 3 decisiones de **(C)** — sobre todo **staging sí/no** y el manejo del webhookId. **Nada se ejecuta hasta la validación.**
