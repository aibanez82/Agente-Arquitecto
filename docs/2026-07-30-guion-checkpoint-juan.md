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

---

## ACTUALIZACIÓN 29-jul noche — el checkpoint llega mucho más maduro

Desde que se escribió este guion pasó todo esto (todo publicado en #132):

- **Fase 6.5 y 6.6 cerradas y certificadas** (`f5072f5`, 273 tests, ambos flavors): los 5 gates
  de la revisión de Juan en verde. **Los 8 writers legacy ya tienen lock** — el punto 3 del
  guion original queda obsoleto (ya no hay decisión de "4 writers sin lock").
- **Juan entregó su paquete Django** (PR draft #139) y **el contraste del Arquitecto dio
  canónico en MATCH EXACTO** — el gate 1 se cierra con su corrida en el PG real de STG.
- **De las 6 preguntas de aprobación, 3 se cerraron con su propio código** ((a)/(c)/(d)).
  **Decisiones reales que quedan: (b) RETURN NULL vs RAISE en el trigger, (e)
  `payload_v1_lead_no_verificable` terminal vs degradar, (f) re-validación por
  identidad/generación sin gates de fase.** Recomendación del Arquitecto: defender las tres
  como están (razonadas en issuecomment-5123328661).
- **4 sincronizaciones menores** ya avisadas a Juan (issuecomment-5123375090): su runbook
  referencia scripts superseded (usar `create-port132-window-schema-stg.py`), la expectativa
  errónea de `blocked_human_active` en Dashboard, la asimetría de sus writers single-statement
  sin lock (confirmar deliberada), y flags de followups seteados EXPLÍCITOS en Heroku STG
  (su preflight trata ausente como false-PASS).
- **Criterio de GO actualizado:** nuestros gates ✅ + canónico match ✅ → el GO del viernes
  depende solo de su preflight real en STG + las 3 decisiones (b)/(e)/(f) + firmas.
- **Punto extra para la llamada (decisión Alberto 29-jul: todo Meta lo ejecuta Juan):** pedirle
  que someta la **plantilla de re-enganche fuera de ventana 24h** (pendiente desde el 16-jul,
  bloquea Recordatorios por fecha mencionada y rescates tipo Bug #12). El Arquitecto tiene el
  borrador listo (nombre `reenganche_cotizacion_pendiente`, categoría Utilidad, cuerpo con
  {{nombre}}/{{vehículo}}, botones de respuesta rápida) — se le pasa para copy/paste.

---

## ACTUALIZACIÓN 29-jul 22:30 — dictamen de auditoría de Juan: NO-GO offline (SUPERSEDE lo anterior donde contradiga)

Juan publicó su auditoría de `f5072f5` (issuecomment-5123871526). Lo esencial:

- **Confirma nuestros números** (reprodujo las suites en PG17 aislado: 269+272 pass, 139/139
  unitarias, dry-run completo) y da por presentes los 5 avances funcionales. **Pero el dictamen
  es NO-GO offline** para ejecutar el runbook contra STG: 3 P0 en el script de deploy + 5 P1
  de fencing/identidad + readiness/rollback. Ninguno toca la lógica certificada — todos están
  en la tubería de deploy o en cobertura que las suites no tenían.
- **Las 3 decisiones abiertas quedaron resueltas — ya NO son agenda de la llamada:**
  (b) `RETURN NULL` ✅ aprobado; (e) `lead_no_verificable` terminal ✅ aprobado;
  (f) ❌ RECHAZADO omitir gates de fase/estado en los 8 writers — lo reprodujo (writer stale
  mutó una sesión `completed`; `Update Out of Scope` baneó a una identidad nueva). Los gates
  son ahora trabajo obligatorio, no decisión.
- **Handoff Fase 6.7 ya entregado al Agente n8n** con los 10 puntos:
  `~/claude-projects/Agente-n8n/handoffs/2026-07-29-fase6-7-bloqueantes-auditoria-juan.md`
  (rama `feature/issue-132-port-dual-safe`, commit `095829a`). Orden: P0 runbook → gates
  writers → resto. Ideal: llegar a la llamada con T1+T2 en verde.
- **PR #139 ya está en STG:** mergeado a `stg` como `34d7d6b` y desplegado en `hyl-wai-stg`
  (sin flags nuevos ni migraciones), ANTES del checkpoint. Juan lo declaró y no tocará STG sin
  autorización. **Abrir la llamada con el punto 1 (preflight read-only)** — confirmar `shadow`,
  flags y schema efectivos — ya no es "presenta Juan si quiere", es el primer paso conjunto.
- **Juan sincronizó su runbook** al script consolidado y al outcome real del Dashboard
  (`HYL-WAI@6499284`).
- **Criterio de GO re-actualizado:** ya no basta preflight + decisiones. Ahora: Fase 6.7
  cerrada y certificada + re-revisión de Juan + su preflight verde. **La ventana del viernes
  13:00 está en riesgo real** — llevar a la llamada la disyuntiva viernes-vs-lunes 3-ago sin
  forzar; si T1+T2 no están en verde y contrastados antes de la llamada, recomendación del
  Arquitecto: proponer lunes directamente.
