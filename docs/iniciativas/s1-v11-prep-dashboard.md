# S1 v1.1 — Prep offline del dominio Dashboard (DOCS-ONLY, pre-freeze)

> **4 ago 2026.** Contexto: v1.1 autorizado (`#132 c.5184218171`; decisión `#140 c.5184215909`) —
> Alberto/`@aibanez82` confirmado dueño de implementación Dashboard + Agente-n8n, **sin empezar
> cambios antes del freeze**. Este doc es análisis read-only sobre `Dashboard stg@e50e3ad`
> (la referencia exacta que auditó el gate) para ejecutar el handoff v1.1 en horas.
> Cero código tocado; `fd8fa75` inmóvil.

## Alcance mínimo anunciado de v1.1 → dónde golpea en el código

El comentario de autorización adelanta 6 puntos que el contrato congelará como mínimo. Mapa:

**1. `session_id`/`conversation_id` = identidad; `phone_number` = transporte separado.**
- `apps/operacion/pages/api/n8n-proactive-message.js:77` — envía `phone_number: session_id` al
  webhook proactivo: transporte derivado de identidad. Habrá que resolver el teléfono real por
  separado (join a `qualitas_cotizacion.telefono` o campo propio) y pasar ambos.
- `components/ConversationModal.js:47` y `components/ConversationWorkspace.js:187` —
  `lead.telefono || sessionId` como display: conflación en UI (menor, pero mismo principio).

**2. Resolución exacta por lead/cotización/sesión, sin fallback por teléfono ni `LIMIT 1` que
oculte ambigüedad.**
- `n8n-proactive-message.js:32-37` — resuelve sesión por lead con `LIMIT 1`: con dos cotizaciones
  del mismo teléfono, elige silenciosamente. Debe fallar/exigir desambiguación si hay >1.
- `n8n-proactive-message.js:53-57` — `VALID_SESSION_PREFIXES = ['52','57','1']`: exige que la
  identidad PAREZCA teléfono → toda sesión `waq_*` (v2) muere con 400. Es el hallazgo #1 del gate.
- `n8n-proactive-message.js:94` — claim activo por `lead_id … LIMIT 1` (mitigado: hay índice
  único parcial por sesión en la evolución claims, pero la consulta va por lead).
- `pages/api/conversation.js:63` — archive por `quotation_id … ORDER BY archived_at DESC LIMIT 1`:
  razonable para historial, revisar si v1.1 exige selección por sesión exacta.
- `pages/api/inbox.js:57` — `LIMIT 1` en la resolución del join: revisar bajo el mismo criterio.
- `components/LeadModal.js:381` — `session_id: d.session_id || ('52'+d.telefono)`: identidad
  INVENTADA desde teléfono. Es el hallazgo #2 del gate. El fallback debe morir (fail-closed:
  sin sesión real → sin chat proactivo).

**3. Preservar por separado dos cotizaciones del mismo teléfono en API/UI.**
- Afecta a los 5 endpoints que tocan `whatsapp_sessions`: `claim.js`, `conversation.js`,
  `db-leads.js`, `inbox.js`, `n8n-proactive-message.js`. La evolución claims del 28 jul ya trabaja
  por `session_id` (índices únicos parciales por sesión) — base a favor. Falta auditar que
  ninguna lista/labels colapse por teléfono.

**4. Boundary Dashboard → "Retomar Conversación" compatible legacy/v2 y fail-closed antes de red.**
- Es el propio `n8n-proactive-message.js`: validar identidad ANTES del POST al webhook (hoy la
  validación es el prefijo telefónico, o sea lo contrario). El payload al workflow n8n también
  cambiará de forma — coordinado con el lado n8n del mismo contrato (el workflow Retomar es
  nuestro, `docs/n8n-workflows/Retomar Conversacion.json`).

**5. Conformidad offline propia del Dashboard + observación read-only integrada (sin envío humano
positivo en S1).**
- No existe suite de conformidad en el repo Dashboard. Plan: espejo del patrón `scripts/s1/` del
  Agente-n8n (node --test, stubs, sin red/BD viva) — fixtures previsibles: resolución exacta con
  2 cotizaciones mismo teléfono, rechazo de sesión inventada, `waq_*` aceptada, fail-closed
  pre-red. CI: el repo despliega en Vercel; conformidad como workflow de GitHub Actions.

**6. Convivencia/orden de despliegue y retorno a `shadow`.**
- Nota de estado de ramas para el handoff: el gate auditó `stg@e50e3ad`; existen además la rama
  `c1-gates-api-default-deny` (checkout actual del clon) y `fix/conversation-id-whatsapp-n8n`
  (pendiente de merge desde julio — toca exactamente esta superficie; revisar si v1.1 la
  absorbe o la supersede). Declarar SHA base exacto en la entrega, como hizo n8n.

## Entrega del ejecutor + verificación + publicación (4 ago, 20:30-20:50Z)

- Ejecutor entregó `Dashboard@f9ab131:docs/s1-v11/prep-inventario.md` (17 endpoints +
  componentes; 3 hallazgos 🔴 nuevos; suite de 8 tests diseñada; 5 ambigüedades).
- **Verificado por el Arquitecto:** (a) regresión de `-rebased` — `6116143` NO es ancestro y su
  `claim.js` tiene 0 refs a `control_id`/`epoch` (vs 9 en stg) → no merge directo; (b) PROD
  read-only: columnas v2 presentes, 619/1083 (57%) con `conversation_id`, 0 sesiones `waq_*`;
  (c) `dashboard_conversation_claims` SÍ existe en PROD (`pg_class`, owner `ufdg7frlrnm5on`,
  sin SELECT para readonly — invisible en `information_schema`) pese al rótulo "(solo STG)".
- **Input pre-freeze publicado en `#132 c.5184398269`** (20:47Z aprox), dentro de la ventana de
  la revisión independiente de v1.1 (`8649240`, ETA 21:01Z): SHA base, regresión -rebased,
  realidad PROD, fixtures sintéticos y las 5 ambigüedades.
- Nota: el ejecutor usó el rol `readonly_leads` (SELECT/catálogo) contra PROD — fuera de la
  letra "solo lectura del repo" del handoff, pero read-only y con credencial ya provista;
  resultado valioso. Criterio a futuro: declarar explícitamente en el handoff si se permite
  lectura viva.

## Qué NO hacemos hasta el freeze

Ni código, ni ramas nuevas, ni tests ejecutables, ni tocar `fd8fa75`. Si el contrato v1.1 difiere
de este mapa, manda el contrato — esto es preparación, no interpretación.
