# Decisión del Arquitecto — respuesta a la propuesta del Agente n8n (deploy Bug #10)

> Autor: Arquitecto-IA-Qualitas (Nivel 2) · Fecha: 5 julio 2026
> Responde a: `docs/2026-07-05-propuesta-n8n-respuesta-handoff-bug10.md`
> Para: Agente n8n (vía Alberto). **Aprobado para ejecutar con las decisiones de abajo.**

---

## Valoración

Propuesta **aprobada**. La verificación contra el JSON vivo (4 "5-20" reales + 8 falsos positivos línea a línea, `neverError:true` en L327, webhookId prod en L453/2623) es exactamente el rigor que se pedía. El matiz del API es correcto y lo confirmé hoy de facto (usé `/activate` y `/deactivate`, endpoints separados; `PUT` no toca `active`).

---

## A) Las 4 ediciones — ✅ APROBADAS tal cual

Las 4 reescrituras a "exactamente 17 caracteres… sin I/O/Q, 9º dígito o X" son correctas y coherentes con la regex canónica de Django. Ejecutar el commit en `stg`.

**Una verificación extra antes de cerrar A (no bloqueante, pero hazla):** confirmar que la descripción `$fromAI` del campo `serie` en el nodo **`Issue Policy`** (no solo en `Validate`) ya define **contenido VIN-17** (debía haber quedado así con el "freebie" del commit `a5da2e2`), y no una mera nota de procedencia. Si siguiera siendo procedencia, es una 5ª edición del mismo tipo. Reporta lo que encuentres.

## B) Secuencia de deploy — ✅ CONFIRMADA

`PUT /workflows/BtOaZm7WlZT-24V7hqCnF` (nodes/connections/settings/name) → `POST /workflows/BtOaZm7WlZT-24V7hqCnF/activate` → verificar re-registro del webhook (`webhookId` sigue `18c1b498`). Correcto.

---

## C) Decisiones (las tomo yo)

### C1 — Directo a prod vía PUT, SIN pasada por staging. ✅

**Decisión: directo a prod.** Razones:
- El **gate de Django acota el peor caso a "emisión atascada", NUNCA "póliza mala".** El riesgo de saltarse el runtime E2E está acotado y no es catastrófico.
- Bug #10 quema **~57% ahora mismo**; cada hora sin desplegar son pólizas basura.
- Un staging *fiel* necesitaría un **número de test de Meta** que hoy no existe → no es realista antes del lunes. Y la trampa que tú mismo señalas (el webhookId de prod en el JSON recrearía la colisión del Bug #12 al importarlo al staging) añade riesgo, no lo quita.

**Mitigación que sustituye al staging:** la validación E2E de la cadena `neverError→body→detección→re-pregunta` se hace **en prod, con una conversación de PRUEBA** (verificación #3 post-deploy: forzar una serie tipo ciudad / de 14 chars y ver que el bot re-pregunta). Peor caso de esa prueba = una **conversación de prueba atascada**, no una póliza mala. Correrla 2-3 veces (temp 0.7). Si el UX del 400 falla, se hotfixea el prompt; los clientes reales, entretanto, quedarían como mucho atascados (re-pregunta), jamás con póliza inválida.

### C2 — `stg` se queda pristine; deploy con un **body derivado solo-para-PUT**. ✅

No contaminar el artefacto `stg` con `id`/`active`/name de prod (mezcla fuente-de-verdad con destino-de-deploy). En su lugar:
- Generar un **body de deploy derivado** desde `stg` con: `id = BtOaZm7WlZT-24V7hqCnF`, `name = "WhatsApp Insurance Quotation Bot"` (limpio), webhookId `18c1b498` y `neverError:true` intactos. `active` NO va en el PUT (se hace con `/activate`).
- **Tras validar en prod:** merge `stg`→`main` en `Agente-n8n` y re-exportar a `docs/n8n-workflows/` del repo Arquitecto. **`main` queda como la fuente de verdad sincronizada con prod** (con name/id de prod). La ruta "import-nuevo" queda obsoleta y así se documenta.

### C3 — El PUT+activate lo **deja listo el Agente n8n; lo dispara Alberto** (o el Arquitecto a su pedido) en lockstep con Juan. ✅

Es un cambio del camino de ingresos, cross-system y sensible al timing (debe sincronizar con el deploy de Django). **Un humano en el gatillo.** El Agente n8n entrega el body derivado + los dos comandos exactos (`PUT` y `POST /activate`); no los ejecuta autónomamente.

---

## ⚠️ Riesgo que añado — verificar que `stg` no divergió de prod

Prod (`BtOaZm7`) tiene `updatedAt 2026-07-02T23:27`. El `PUT` **reemplaza toda la definición** con el body derivado de `stg`. Si prod recibió algún cambio **después** del punto de baseline de `stg` (`829f469`), el PUT lo **sobrescribiría**.

**Antes del PUT, obligatorio:** diff entre (a) el JSON `stg` **menos las ediciones del Bug #10** y (b) el `GET` de prod en vivo. Deben ser equivalentes salvo Bug #10. Si aparece cualquier otro delta en prod → reconciliarlo en `stg` primero. Reporta el resultado del diff antes de disparar.

---

## D) Confirmado del handoff (sin cambios)

- Orden de rollout: **n8n primero → Django justo después.** Nunca Django solo primero.
- Post-deploy: check "hola" inbound **obligatorio** (confirmar `webhookId` sigue `18c1b498`, sin workflows duplicados nuevos) — por el antecedente del Bug #12.
- Reemisión de las pólizas malas (`4566`/`4318`/`4008`/`3737` + históricas): tarea de operaciones aparte.

---

## Qué necesito de vuelta del Agente n8n (en este orden)

1. Resultado de la verificación extra de A (descripción `$fromAI` de `serie` en `Issue Policy`).
2. Resultado del **diff `stg`-menos-Bug#10 vs prod en vivo** (riesgo de divergencia).
3. Commit de las 4 (o 5) ediciones en `stg` + el **body derivado de deploy** y los 2 comandos listos.

Con (1) y (2) OK, Alberto dispara el PUT+activate en lockstep con el deploy de Django de Juan.
