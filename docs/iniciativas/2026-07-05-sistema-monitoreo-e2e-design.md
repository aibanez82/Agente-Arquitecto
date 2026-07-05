# Sistema de Monitoreo E2E — Agente de Monitoreo (diseño aprobado)

> Autor: Arquitecto-IA-Qualitas · Fecha: 5 julio 2026
> Estado: diseño aprobado en brainstorming con Alberto. Pendiente: revisión del spec → plan de
> implementación.
> Origen: raíz en el Bug #12 (inbound Meta→n8n caído 45.5h sin que nadie se enterara) e Issue #74
> (follow-up 15m caído en silencio). Dos apagones silenciosos en una semana → hace falta vigilancia
> E2E, no alertas puntuales.

---

## 1. Objetivo y alcance

Un **Agente de Monitoreo** dedicado que vigila la salud técnica y de datos de todo el funnel de
extremo a extremo, detecta apagones y anomalías, y **avisa con diagnóstico** — sin depender de que
alguien mire un tablero.

**Tres pilares (decisión de Alberto):**
1. **Uptime del pipeline** — cada tramo técnico vivo (landing → Django → n8n → Meta → BD → emisión).
2. **Errores de emisión** — pólizas que fallan al emitir.
3. **Integridad de datos** — inconsistencias en BD.

**Fuera de alcance (v1):** analítica de conversión de negocio (ya la cubre el Agente Mejoras
Conversación). Hook de emisión fallida en tiempo real (se detecta en el barrido; queda como
extensión futura, ver §11).

---

## 2. Arquitectura

- **Componente:** nuevo proyecto Claude Code **`aibanez82/Agente-Monitoreo`** (Ejecutor Nivel 3),
  ejecutado como **cloud agent programado** (routine/cron, skill `/schedule`).
- **Cadencia:** barrido completo **cada 90 min** dentro del **horario activo 08:00–22:00 CDMX**
  (una sola cadencia, elección "equilibrada"). Fuera de esa franja no corre (evita falsos positivos
  nocturnos y ahorra tokens). Caza un apagón en ≤90 min vs las 45h del Bug #12. Valores ajustables
  tras rodaje.
- **Estado en git (enfoque A):** el agente es auto-contenido; guarda su estado y su histórico en su
  propio repo. Sin infraestructura nueva, sin depender de Juan.
- **No comparte suerte con Heroku:** corre en la nube de Claude, con git en GitHub. Puede detectar y
  reportar una caída total de Heroku (incluida la BD compartida).

**Regla de oro (arquitectura de agentes):** el Agente de Monitoreo es Nivel 3, no se comunica con los
otros ejecutores; sus hallazgos suben al Arquitecto, que decide y hace handoff.

---

## 3. Catálogo de checks

Cada check devuelve `OK` / `WARN` / `FAIL` / `UNKNOWN` + evidencia (conteo, ids, hora).

### 🟢 Pilar 1 · Uptime del pipeline
| # | Check | Cómo se mide | Caza |
|---|---|---|---|
| 0 | **Postgres alcanzable** | Primer check; intento de conexión. Si falla → `FAIL` máxima severidad | BD caída (Heroku) |
| 1 | **Inbound Meta→n8n vivo** | Edad de la última ejecución webhook del bot (API n8n) vs `outbound_2h` (Postgres). `FAIL` si hay salientes pero 0 entrantes >2h | Bug #12 |
| 2 | **Follow-up 15m vivo** | ¿Se envían `cotizacion_followup_15m` recientes cuando hay leads que ya deberían tenerlo? (`qualitas_whatsappmessage`) | Issue #74 |
| 3 | **Entrada de leads viva** | ¿`qualitas_lead.fecha_creacion` reciente en horario activo? (landing→Django vivo) | Caída de captación |
| 4 | **Workflows activos** | Los 3 de prod siguen `active:true` (API n8n) | Recaída colisión webhookId / desactivación |
| 5 | **n8n alcanzable** | El API responde 200 | Caída de Hostinger |
| 12 | **Landing/Django HTTP health** | `GET seguroautoqualitas.com` (o endpoint de salud) → 200 | Dyno Heroku caído (directo, en minutos) |
| 13 | **Heroku app/dyno/release** *(si hay token)* | Token OAuth read-only Heroku: estado de dynos + detección de releases recientes | Release malo / config var (candidato Issue #74) |

### 🟠 Pilar 2 · Errores de emisión (mejor esfuerzo — gap de observabilidad Bug #9)
| # | Check | Cómo se mide | Nota |
|---|---|---|---|
| 6 | **Emisiones fallidas** | Cuenta marcas `[api_error:issue_policy]` en `n8n_chat_histories` recientes | Proxy: Bug #9 no guarda el fallo en BD |
| 7 | **Serie/VIN inválido emitido** | Escanea `Issue_Policy` recientes en histories; serie que no cumpla la regex VIN-17 canónica `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$` | Bug #10 |

### 🔵 Pilar 3 · Integridad de datos
| # | Check | Cómo se mide | Caza |
|---|---|---|---|
| 8 | **Sesión pegada a cotización vieja** | `whatsapp_sessions.quotation_id` ≠ cotización más reciente del teléfono | Bug #11 |
| 9 | **Leads sin whatsapp_session** | `qualitas_lead` sin fila en `whatsapp_sessions` | Bug #4 |
| 10 | **Prefijo 57 (Colombia)** | `session_id`/teléfono que empiezan por `57` en vez de `52` | Bug #2 |
| 11 | **(Info) timestamps naive** | Presencia de `timestamp without time zone` en tablas monitoreadas | Issue #87, informativo hasta migrar |

Los del Pilar 2 son "mejor esfuerzo" hasta que Juan añada logging de emisión (Bug #9).

---

## 4. Lógica de alertas y dedup

**Estado en git** — `estado-salud.json` guarda el último estado de cada check:
```json
{ "check_1_inbound": { "status": "OK",   "since": "2026-07-05T20:09Z", "alerted": false },
  "check_6_emision": { "status": "FAIL", "since": "2026-07-05T14:00Z", "alerted": true } }
```
Cada corrida evalúa los checks → snapshot nuevo → **compara con el anterior** → notifica solo
**transiciones**, nunca estados:

| Transición | Acción |
|---|---|
| `OK → FAIL` | 🔴 Alerta push inmediata (Telegram) con diagnóstico |
| `FAIL → FAIL` (en curso) | 🔇 Silencio. Recordatorio cada 12h si sigue abierto |
| `FAIL → OK` | ✅ Alerta de recuperación |
| `OK → WARN` | 📋 Sin push; va al digest diario + histórico |
| `WARN → FAIL` | 🔴 Escalada a push |

**Anti-flapping:** antes de alertar `OK→FAIL` en checks de uptime, el agente **re-verifica en la
misma corrida** (segunda query ~60s después). Solo alerta si persiste. Los checks de integridad
(conteos) no flapean → no aplican re-verificación.

**Capa de inteligencia (el porqué de un agente con IA):** ante un `FAIL`, el agente no manda "check X
falló" — **profundiza** (query la causa probable, revisa colisiones/tokens/ejecuciones, como se hizo
con el Bug #12) e incluye **diagnóstico + causa probable + acción sugerida** en la alerta.

---

## 5. Manejo de dependencias caídas ("dependencia caída ≠ error del agente")

Si Postgres, el API de n8n o Meta no responden, el agente lo trata como **señal monitoreada**
(`FAIL`/`UNKNOWN`), nunca como fallo de la corrida. Cuando la BD está caída, los checks de integridad
de datos reportan **`UNKNOWN`, no `OK`** — no se pinta verde falso sobre datos que no se pudieron
leer. El agente nunca muere en silencio.

---

## 6. Entregables

**Por evento (push · Telegram):**
- `OK→FAIL`: alerta con diagnóstico + causa probable + acción sugerida.
- `FAIL→OK`: recuperación.
- Recordatorio 12h si un `FAIL` sigue abierto.

**Por corrida (a git):**
- Actualiza `estado-salud.json` (estado actual de los 14 checks).
- Anexa a `historico/YYYY-MM.jsonl` (tendencias/auditoría).
- Reescribe `ULTIMO-REPORTE.md` legible (semáforo completo, abrir cuando se quiera).

**Diario (1×/día · Email + Telegram):**
- **Digest**: resumen del día + items en `WARN`.
- 🫀 **Dead man's switch**: el digest diario es también prueba de vida. Si el agente-monitor se cae,
  **dejas de recibir el ping** → esa ausencia te avisa. Resuelve "¿quién vigila al vigilante?".

---

## 7. Canales de notificación

- **Telegram** (push urgente): instantáneo, sin ventana de 24h, mensajes largos con formato para el
  diagnóstico. Requiere bot (@BotFather) + `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID`.
- **Email** (digest diario + registro): SMTP (Gmail app-password u otro). Requiere credencial SMTP.
- Las alertas **no** usan WhatsApp como canal principal (dependería de la ventana 24h de Meta, que se
  cierra justo cuando hay incidente).

---

## 8. Accesos / prerequisitos

| Acceso | Uso | Estado |
|---|---|---|
| `DATABASE_URL` (rol `readonly_leads`) | Queries de todos los pilares | ✅ existe |
| `N8N_API_KEY` | Ejecuciones + estado de workflows | ✅ existe (repo Agente_n8n) |
| `META_ACCESS_TOKEN` | (opcional) salud de la WABA | ✅ existe (Vercel) |
| Token OAuth read-only Heroku | Check #13 (dynos/releases) | ⏳ pendiente (ya previsto para Issue #74) |
| `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` | Push | 🆕 crear |
| Credencial SMTP | Digest email | 🆕 crear |
| Repo `aibanez82/Agente-Monitoreo` | Código + estado + histórico | 🆕 crear |

Todos como **env del routine** del cloud agent. Nota: el agente headless usa claves/env, no MCP
interactivo.

---

## 9. Limitaciones conocidas
- **Pilar 2 (emisión)** es "mejor esfuerzo" por el gap del Bug #9 (los fallos no se guardan en BD). Se
  fortalece cuando Juan añada logging de emisión.
- **Check #11 (timestamps naive)** es informativo hasta que se aplique la migración del Issue #87.
- **Check #13 (Heroku)** queda desactivado hasta que exista el token; lo suplen #0/#3/#12.

---

## 10. Éxito (criterios)
- Un apagón como el Bug #12 se detecta y notifica en **≤90 min** en horario activo (vs 45h).
- Cero spam: un incidente en curso alerta **una vez** + recordatorio 12h, no cada corrida.
- Si el propio agente muere, Alberto se entera por la ausencia del digest diario.
- Ninguna corrida "verde falso": dependencia caída = `FAIL`/`UNKNOWN`, nunca `OK`.

---

## 11. Futuro (fuera de v1)
- **Enfoque C:** migrar el histórico a una tabla `monitoring_health` en Postgres + **tablero visual
  en el Dashboard** (semáforos + tendencias). Encaja con `docs/architecture/whatsapp-event-canonico-propuesta.md`.
- **Hook de emisión fallida en tiempo real** (Error Workflow n8n) — ya especificado en
  `docs/estrategia/2026-07-02-alerta-emision-fallida-quálitas.md`; complementaría el check #6.
