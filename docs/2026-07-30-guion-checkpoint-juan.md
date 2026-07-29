# Guion de Alberto — checkpoint con Juan, jueves 30 jul 10:00 CDMX

> Meet: https://meet.google.com/ywh-djvu-vxr (45 min). Agenda = los 8 puntos de Juan (su
> comentario del 29 jul en #132). Nuestro estado: TODO verde (`848057e`, 249 tests, ambos
> flavors, certificado). Lo que se juega: el GO/NO-GO de la ventana del viernes 13:00.

## Chuleta de datos (por si te preguntan)

- Rama: `aibanez82/Agente-n8n:feature/issue-132-port-dual-safe`, SHA **`848057e`**
- Tests: **249** (245+4 skip `actual` / 248+1 skip `objetivo`), 0 fallos, 3× sin flakiness
- Artefactos de ventana: 5 workflows transformados + sub-workflow `Issue Policy Guard (STG)`
  + script de schema (con paridad archive) + runbook `deploy/deploy-port-132-stg.py` (dry-run
  ensayado) + rama Dashboard `fix/operator-webhooks-post-headerauth` (`08981ef`)
- Header de auth: **`X-Operator-Auth`** · Env vars Vercel: `N8N_OPERATOR_WEBHOOK_BASE_URL`,
  `N8N_OPERATOR_WEBHOOK_SECRET` · Un solo secreto para los 4 webhooks de operador

## Punto por punto (qué escuchar, qué decir, qué decidir)

**1. Estado STG tras PR #138 (presenta Juan — su preflight read-only).**
Escuchar: ¿modo `shadow` confirmado? ¿flags apagados? ¿migraciones 0053-0061? ¿existe aún
`idx_whatsapp_sessions_phone_number`? ¿forma real de las tablas archive?
→ Si el índice único YA no está: nuestra realidad es el flavor `objetivo` (todo probado).
→ Si las archive difieren de lo asumido: nuestro script tiene guardas; ajuste pequeño, no bloquea.

**2. Canónico `hashtext()` (el gate crítico).**
Nuestra string y vectores están publicados (todos → `525512345678`). Pedir: que Juan confirme
que su helper unificado reproduce EXACTAMENTE esos vectores (idealmente enseña su test cruzado
corriendo). Sin match exacto → NO-GO automático del viernes.

**3. Writers con/sin lock + Chat Memory.**
Ya resuelto de nuestro lado: trigger BEFORE INSERT (cubre LangChain) + `Update Activity`
lockeado. **Decisión real de este punto: los 4 writers legacy sin lock** (`Save Group1/2/3
Progress`, `Save Policy Data`, `Update Out of Scope in DB`, `Increment KB Counter`).
→ Tu posición: si Juan los quiere lockeados, lo hacemos hoy jueves por la tarde (fase pequeña,
mismo patrón, cabe antes del viernes). Si no, quedan como excepción documentada. No lo ofrezcas
proactivamente — que lo pida él.

**4. Paridad active/archive.** Corregida en nuestro script. Solo confirmar contra su preflight.

**5. Payment v1 / lead_id.** Nuestro supuesto: `lead_id` NULL = compatible, solo contradicción
real bloquea. Que apruebe o endurezca. Su deploy de Payment v1 a STG: a su ritmo (parser dual).

**6. Humano/Metepec.** Exclusión fail-closed implementada (`blocked_metepec_active` /
`blocked_human_active`), Dashboard ya la mapea. Transferencia explícita = diseño aparte, NO
entra en esta ventana. Solo pedir su OK a la semántica.

**7. #69 + ventana 24h.**
Cuéntale el hallazgo si no lo ha leído: **Phase Guard nunca funcionó** (leía propiedad
inexistente) — corregido + 3 barreras, Payment único writer de `completed`. Pedir su OK al
cambio observable (sesiones completed ahora reciben respuesta de cierre).
Ventana 24h: ya acordado diferirla a #135/B4 con followups en dry-run — solo formalizar.

**8. GO/NO-GO y logística de ventana.**
- Criterio GO viernes 13:00: su preflight verde + canónico match + supuestos 1-6 aprobados.
  Si falta algo → plan B lunes 3-ago AM, sin forzar.
- Orden de ventana: el suyo de 13 pasos (más completo que el nuestro) — aceptado; nuestro
  runbook cubre los pasos n8n (backup→drift→transform→import→verify→sync Git).
- #130 (`N8N_TOKEN`): nuestra posición = rotar en esta ventana si todo va verde.
- #129 (rol read-only `conciliacion_pagos`): prerrequisito del E2E conjunto, NO de la ventana.
- Recordar: deploy ≠ cierre de #132 (falta integración pinneada, sign-off, `dual`, rollback
  probado) — ya acordado, sin discusión.

## Antes de la llamada (5 min, tuyos)

1. ☐ `GH_TOKEN` al environment cloud (claude.ai/code → environments → Default) — desbloquea el
   monitor horario de Juan. Independiente del checkpoint pero pendiente tuyo.
2. ☐ Mira si Juan respondió algo en #132 durante la noche (o pídemelo al arrancar sesión:
   "revisa comentarios de Juan").
3. ☐ Confirma tu disponibilidad real del viernes 13:00-15:00 — la ventana requiere TUS manos
   (credencial n8n, env vars Vercel, correr el runbook, merge del Dashboard).

## Después de la llamada

Pásame el resultado (aunque sea en 3 líneas: GO/no-GO, decisión de los 4 writers, supuestos
aprobados/ajustados) y yo: actualizo docs, lanzo la fase pequeña si Juan pidió los locks
legacy, y dejo la ventana del viernes lista paso a paso.
