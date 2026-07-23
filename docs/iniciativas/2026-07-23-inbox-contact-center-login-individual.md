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

## Estado (23 jul 2026)

- ✅ Código implementado en rama `stg` del Dashboard (escrituras fallan con error controlado
  hasta que exista la infraestructura — mismo patrón usado con Metepec).
- ✅ Las 3 tablas ya existen en Postgres STG (creadas por el Arquitecto el 23 jul, mismo rol
  `DATABASE_URL`/`u81gb6n2j32hnm` que usa Heroku `hyl-wai-stg`, que ya tenía `CREATE` amplio en
  el schema `public` — el `GRANT` explícito que pedía el handoff no hizo falta, el rol ya es
  owner).
- ⚠️ **Sin verificar con certeza:** que el `DATABASE_URL` de Preview (rama `stg`) en Vercel del
  proyecto Dashboard apunte exactamente a esa misma DB — está marcado Sensitive/Encrypted en
  Vercel y `vercel env pull` lo trae vacío (mismo problema ya documentado con el de producción),
  así que se infirió por coincidencia de patrón con Conciliación/Metepec, no se comparó cadena
  contra cadena. Confirmar en el primer INSERT real desde el Inbox desplegado.
- ⏳ **Bloqueante — pendiente de Alberto:** definir en Vercel (Preview de `stg`) las env vars
  `JWT_SECRET` (nuevo, firma la cookie de sesión individual, reemplaza `SESSION_TOKEN`
  compartido) y `ADMIN_BOOTSTRAP_TOKEN` (de un solo uso, para crear el primer usuario admin
  desde `pages/api/admin/agents.js`). Ninguna de las dos aplicada todavía.
- ⏳ Tras desplegar: verificación de 4 pasos pedida por el agente del Dashboard (crear admin,
  alta de agentes de prueba, tomar lead + enviar mensaje + confirmar fila en
  `dashboard_message_audit`, prueba de concurrencia con 2 agentes sobre el mismo lead).
- 🔴 Fuera de alcance por ahora: aplicar lo mismo en PROD (bloqueado hasta validar flujo
  completo en STG + confirmación explícita de Alberto) y borrar `PROACTIVE_MESSAGE_PASSWORD` de
  Vercel (solo cuando el login nuevo esté confirmado funcionando).
