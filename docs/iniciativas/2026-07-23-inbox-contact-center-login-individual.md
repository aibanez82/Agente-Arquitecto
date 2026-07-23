# Inbox contact center + login individual por agente

> Iniciativa iniciada 23 jul 2026, propuesta por el agente de IA del Dashboard, aprobada por
> Alberto. Código ya implementado en la rama `stg` de `Dashboard_seguroautoqualitas`, pendiente
> de habilitar infraestructura para desplegar.

## Qué es

Reemplazo de `ProactiveModal.js` (modal pequeño de "tomar conversación", ya eliminado) por una
pestaña **"Inbox"** de página completa, con auditoría real de quién tomó cada conversación y
qué mensajes envió, y login individual por agente (reemplaza la contraseña única compartida del
dashboard).

Handoff original: `Dashboard_seguroautoqualitas:docs/2026-07-23-mensaje-arquitecto-inbox-agentes-auditoria.md`.
Respuesta del Arquitecto: `Dashboard_seguroautoqualitas:docs/2026-07-23-handoff-arquitecto-respuesta-inbox-agentes.md`.

## Arquitectura — nuevo patrón de escritura del Dashboard

El Dashboard nunca había escrito directo a Postgres (solo lectura vía `readonly_leads`/rol de
`DATABASE_URL`, precedente: Conciliación y Metepec, ambos también solo lectura sobre tablas
propias). Esta feature sí necesita escribir. Se resolvió con el mismo criterio de propiedad de
tablas que Conciliación/Metepec: 3 tablas propias del Dashboard, **sin FK hacia schema de
Django** (`lead_id` es `integer` suelto, sin `REFERENCES qualitas_lead`), para no tener que
pedir permisos sobre tablas de Django:

- `dashboard_users` — usuarios/agentes, password hasheado, rol (`agente`/`admin`)
- `dashboard_conversation_claims` — quién tomó qué lead, con índice único parcial
  (`WHERE released_at IS NULL`) que garantiza a nivel de BD que solo un agente puede tener un
  lead tomado a la vez
- `dashboard_message_audit` — auditoría de mensajes enviados desde el Inbox

## Estado (23 jul 2026, actualizado tras verificación E2E del agente del Dashboard)

- ✅ Código implementado y **desplegado en STG**, gateado igual que Conciliación/Metepec
  (`entorno !== 'production'`) — nada visible en producción todavía.
- ✅ Las 3 tablas ya existen en Postgres STG (creadas por el Arquitecto el 23 jul, mismo rol
  `DATABASE_URL`/`u81gb6n2j32hnm` que usa Heroku `hyl-wai-stg`, que ya tenía `CREATE` amplio en
  el schema `public` — el `GRANT` explícito que pedía el handoff no hizo falta, el rol ya es
  owner). **Verificado también por el agente del Dashboard** con INSERT+ROLLBACK real contra la
  base — columnas, índice único y escritura funcionan como espera el código.
- ✅ **Login individual end-to-end confirmado** — Alberto creó su usuario admin y entró. En el
  camino se encontraron y arreglaron 3 bugs reales (todos ya cerrados, no requieren seguimiento):
  1. `bcryptjs` se empaquetaba en el bundle Edge de `middleware.js` (incompatible) — movido a
     `lib/password.js`, solo API routes (Node).
  2. `middleware.js` bloqueaba su propio endpoint de bootstrap del primer admin (esa request no
     tiene cookie de sesión todavía por definición) — excluido explícitamente.
  3. El bootstrap manual vía `fetch()` en consola fallaba silenciosamente — reemplazado por
     `/bootstrap-admin`, pantalla simple que manda el POST sin DevTools.
  Además: el filtro de `TEST_EMAILS` escondía los 7 leads de prueba disponibles en STG — se
  ajustó para que solo aplique en producción, con etiqueta "TEST" visible en STG.
- ⚠️ **Lección operativa, no bloqueante:** al forzar un redeploy manual para tomar las env vars
  nuevas, un `vercel deploy` suelto casi generó un deployment sin el scope de rama `stg` — mismo
  patrón de riesgo que el Bug #17 (ver `docs/bugs/bug-17-webhook-proactivo-stg.md`). Se evitó a
  tiempo con `vercel redeploy` sobre el deployment correcto. Registrado como recurrencia en
  [issue #29](https://github.com/aibanez82/qualitas-issues/issues/29) (purga de deployments
  Preview viejos) — el fix de #17 sigue dependiendo de disciplina humana, no de un guard
  estructural.
- ⏳ **Único pendiente real — decisión de Alberto, no código:** probar "tomar lead + enviar
  mensaje real" dispara un WhatsApp genuino vía `n8n-proactive-message.js`; los únicos leads
  disponibles en STG son los de prueba (Juan Aguayo, `test@test.com`). El agente del Dashboard
  no lo ejecutó solo por eso. Opciones para Alberto: probar con su propio teléfono desde la UI,
  autorizar un lead de prueba, o esperar a que aparezca un lead real en la bandeja. La prueba de
  concurrencia (2 agentes tomando el mismo lead) sí se puede correr ya — no dispara mensajes.
- 🔴 Fuera de alcance por ahora: aplicar lo mismo en PROD (bloqueado hasta cerrar la
  verificación completa en STG + confirmación explícita de Alberto — mismo DDL sin GRANT extra
  a confirmar según el rol de PROD, + las mismas 2 env vars en Production de Vercel) y borrar
  `PROACTIVE_MESSAGE_PASSWORD` de Vercel (solo cuando el login nuevo esté confirmado
  funcionando).
