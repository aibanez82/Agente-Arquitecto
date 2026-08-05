# S3 (Atención Humana básica) — preparación offline del Arquitecto

> **5 ago 2026, ~06:50 CDMX.** DOCS-ONLY, en stand-down, autorizada por el patrón §9 de la
> enmienda (prep que no distrae el camino crítico). S3 depende de S1 cerrada (`#132`) y S2
> cerrada (`#135`); el contrato S3 lo redacta y congela Juan (enmienda en `#128`,
> `plan140:amendment:s3-human-basic`). Este doc = inventario + brechas + input pre-freeze
> listo para publicar en `#128` cuando abra el ciclo (con OK de Alberto).

## 1. Alcance vinculante (enmienda, literal)

Contrato S3 cubrirá: **toma exacta, identidad del control, silenciamiento de IA, persistencia
de inbound, envío humano, liberación, control obsoleto, transición, rollback y pruebas
básicas**. Resultado esperado en STG: tomar silencia IA; inbound cae en la conversación
correcta; el humano envía solo a destino allowlisted; liberar habilita el siguiente inbound
para IA; un control antiguo no modifica uno nuevo. Sin canary independiente. Nada vivo antes
del freeze + handoff.

## 2. Delta clave desde nuestro diseño de julio (`#128` §1-2, 27 jul)

| Diseño jul-27 | Realidad hoy (verificada) |
|---|---|
| Claim por `lead_id`, índice único parcial `ON (lead_id)` | **Claims keyea `session_id`** (`uq_claims_active_session WHERE state='active'`), con `lead_id`/`quotation_id` como metadata; toma por `lead_id` resuelta server-side lead→cotización→sesión (`claim.js@c911d4c`) |
| "¿Humano al mando?" = `EXISTS claim abierto` | Igual en esencia, pero con **`control_id` + `epoch`** (fencing): liberar exige el par exacto + agente; "nunca por teléfono ni lead solo". Acreditado en el ciclo S1 |
| Flag ortogonal, sin campo espejo | **El espejo EXISTE**: workflow n8n "Atención Humana: Marcar Human Takeover ON/OFF" escribe `whatsapp_sessions.human_takeover` (+`_control_id`/`_epoch`); dos guards del bot lo leen (inventario `Agente-n8n:docs/s2/prep-inventario-hechos.md`). El contrato **S2 §4.3.1/§5.3** ya los degrada a no-fuente-de-autoridad; nuestra propuesta A5 (aceptar mirrors NO comparados en S2, **migrar el escritor en S3/S4**) está publicada en `#135 c.5187242434` |
| n8n consulta claims con EXISTS directo | Propuesta S2 (nuestra, pre-freeze): **consulta canónica SQL versionada por hash** `control ∈ {IA,HUMANO,METEPEC}` — si S2 la congela así, el gate S3 la consume tal cual |

## 3. Inventario por dominio (existe ✔ / falta ✘ / confirmar ?)

**BD** — ✔ `dashboard_conversation_claims` con `state/control_id/epoch` (acreditada S1; en PROD
existe SIN grants). ✘ **GRANT SELECT a la credencial de n8n y a `readonly_leads`** — pedido
`#128` §3.2, **sin respuesta de Juan, bloqueante del gate**. ? `whatsapp_sessions.lead_id`
garantizado en todo camino de creación (pedido §3.1, sin respuesta; dato jul-27: 100% de las
sesiones nuevas lo traen).

**Dashboard** — ✔ `claim.js` toma/liberación con fencing (S1). ✔ exclusión Humano/Metepec en
tomar conversación (`blocked_metepec_active`, rama fase-7 `08981ef`). ? UI de "Soltar a IA" e
indicador "tomada por X" (por confirmar contra `stg`; el diseño jul los pedía). ✘ marca
`sent_by: human_agent` en el camino proactivo. ✘ auto-release por inactividad (¿alcance
"básico"? → ambigüedad A6).

**n8n** — ✔ workflow Marcar Human Takeover ON/OFF (escritor del mirror). ✔/? dos guards
leyendo el espejo en el build STG (no PROD — `#57` sigue real en PROD). ✘ gate de supresión
contra la **fuente canónica** (hoy leen el mirror; S2/S3 lo invierten). ✔ Retomar fail-closed
S1 (`fb98f24`); ? skip explícito por claim activo en el scheduler.

**Django** — ✔ nada que hacer por diseño (pedido §3.3: claims = Dashboard escribe, n8n lee,
Django ignora). Falta la confirmación formal de Juan — reciclable como cláusula del contrato.

## 4. Ambigüedades tempranas para el contrato S3 (input pre-freeze)

- **A1 — Identidad del control:** fijar que es `session_id`+`control_id`+`epoch` (la semántica
  ya acreditada), no el `lead_id` del diseño de julio. Con A/B mismo teléfono: tomar el lead
  debe resolver LA sesión exacta (patrón S1) — definir qué pasa si el lead tiene 2 vivas
  (¿400/409 como cardinalidad S1?).
- **A2 — Fuente del gate:** ¿consulta canónica S2 o EXISTS ad-hoc? (Nuestra posición: la
  canónica; un solo texto contractual para bot, Retomar y UI.)
- **A3 — Envío humano vs modos runtime S1:** el estado final S1 deja `S1_DASHBOARD_MODE=read_only`
  con POST proactivo=403. S3 necesita habilitar el envío humano → definir el modo nuevo (¿`take_send`?)
  y su tabla de códigos, manteniendo fail-closed por defecto y destino allowlisted.
- **A4 — Ventana 24h de Meta:** riesgo arrastrado de `#128`: humano toma fuera de ventana →
  el envío fallará. La plantilla de re-enganche sigue bloqueada (pendiente de Juan). El
  contrato debe definir el comportamiento (error claro al operador, no reintento silencioso)
  sin esperar la plantilla.
- **A5 — Migración del escritor del mirror:** confirmar que S3 ordena que la toma/liberación
  escriba SOLO claims (el workflow ON/OFF pasa a derivado o se retira en S5) — coherente con
  nuestra propuesta A5 de S2.
- **A6 — Auto-release por inactividad:** ¿dentro de "básica" o diferido? (Nuestra posición:
  diferirlo; un claim olvidado se libera manual — menos superficie de contrato.)
- **A7 — `sent_by: human_agent`:** ¿entra al contrato de datos S3 (additional_kwargs en
  `n8n_chat_histories`) o queda como convención no contractual?
- **A8 — Persistencia de inbound bajo control humano:** el diseño jul (persistir SÍ, responder
  NO — la IA retoma con transcripción completa) debe quedar como cláusula observable (conteo
  historial +1, outbound 0).

## 5. Esbozo de suite de conformidad (patrón S1: superficies reales, stubs, fail-first)

n8n: claim activo → inbound persiste (+1 historial) y outbound=0 · claim liberado → siguiente
inbound responde · epoch viejo no silencia/no libera · Retomar salta claim activo · canónico
indisponible → fail-closed (IA NO responde y humano NO se asume).
Dashboard: tomar resuelve sesión exacta A/B · liberar exige `control_id`+`epoch`+agente ·
envío humano solo con claim propio activo y destino allowlisted · modo runtime nuevo
fail-closed · `blocked_metepec_active` intacto.
Integrado: tomar→inbound→silencio→envío humano→liberar→inbound→IA responde, `outbound_real=0`
salvo el envío humano stub.

## 6. Dependencias y qué NO hacer

Bloqueado por: cierre S1 (checkpoint STG) + ciclo S2 completo + GRANTs (§3.2) + redacción del
contrato por Juan. NO hacer hasta freeze+handoff: código, cambios de workflows, pruebas vivas,
canary. Este doc se publica en `#128` como input pre-freeze SOLO con OK de Alberto cuando Juan
abra el ciclo S3.
