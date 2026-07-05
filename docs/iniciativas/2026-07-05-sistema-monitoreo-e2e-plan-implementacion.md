# Sistema de Monitoreo E2E — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el **Agente de Monitoreo** — un cloud agent que barre la salud E2E del funnel cada 90 min, detecta apagones/anomalías en 14 checks (uptime, emisión, integridad), y alerta con diagnóstico por Telegram + digest diario por email, sin spam.

**Architecture:** Repo Node.js auto-contenido (`aibanez82/Agente-Monitoreo`). Capas separadas y testeables: *fetchers* de I/O (Postgres readonly, API n8n, HTTP) → *evaluadores* puros (métricas → `OK/WARN/FAIL/UNKNOWN`) → *motor de estado* (diff snapshot previo vs actual → transiciones) → *notificadores* (Telegram/email). El estado y el histórico viven en git. La capa de razonamiento/diagnóstico vive en el `CLAUDE.md` del agente. El scheduling es un routine (skill `/schedule`).

**Tech Stack:** Node.js ≥20 (fetch nativo, `node:test`), `pg` (Postgres), `nodemailer` (email). Telegram vía `fetch`. Sin frameworks de test extra.

## Global Constraints

- **Repo destino:** `aibanez82/Agente-Monitoreo`, clonado en `~/claude-projects/Agente-Monitoreo`. Todos los paths del plan son relativos a esa raíz.
- **Persistencia:** todo estado/histórico se hace commit a git (nunca memoria local — Alberto usa varias laptops).
- **Timezone:** almacenar/comparar en UTC; convertir a `America/Mexico_City` (UTC-6, sin DST) SOLO en presentación.
- **BD read-only:** usar SIEMPRE el rol `readonly_leads` vía `DATABASE_URL`. Nunca escribir a Postgres.
- **Git identity:** `user.email = a.ibanez@gmail.com`, `user.name = aibanez82`.
- **n8n API:** `https://n8n.srv1325340.hstgr.cloud/api/v1/`, header `X-N8N-API-KEY`.
- **Workflow bot en prod:** id `BtOaZm7WlZT-24V7hqCnF`. Payment: `disvKr7iVhnNnefuiqJbJ`. Retomar: `96XfJZcwvlHnVJLko3G8-`.
- **Regex VIN-17 canónica (check #7):** `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$` (normalizar `String(s).trim().toUpperCase()` antes).
- **Cadencia:** cada 90 min, franja activa 08:00–22:00 CDMX.
- **Estado de un check:** `OK` | `WARN` | `FAIL` | `UNKNOWN`. `UNKNOWN` = no se pudo medir (dependencia caída) — NUNCA se reporta `OK` sobre datos no leídos.
- **JOINs correctos:** `qualitas_lead.cotizacion_id = qualitas_cotizacion.id`; `whatsapp_sessions.quotation_id = qualitas_cotizacion.id`. Columnas: `l.canal_atencion`, `c.codigo_postal`, `c.telefono`. `n8n_chat_histories.message` es JSONB → `message->>'type'`, `message->>'content'`; ordenar por `id` (no hay `created_at`).

---

## Estructura de archivos (destino: repo Agente-Monitoreo)

```
package.json                 # deps + scripts (test, run)
.env.example                 # plantilla de secretos
.gitignore
CLAUDE.md                    # instrucciones del agente (capa de razonamiento/diagnóstico)
src/
  config.js                  # umbrales, franja activa, registro de checks
  lib/
    db.js                    # pool Postgres readonly + query()
    n8nApi.js                # cliente API n8n (execuciones, workflows)
    http.js                  # GET con timeout → {ok, status}
    time.js                  # helpers UTC / franja activa CDMX
  checks/
    pillar1_uptime.js        # checks 0,1,2,3,4,5,12,13
    pillar2_emision.js       # checks 6,7
    pillar3_datos.js         # checks 8,9,10,11
    registry.js              # lista ordenada de todos los checks
  state.js                   # load/save estado-salud.json + diff → transiciones
  alerts.js                  # transiciones → lista de notificaciones (push/silencio/recordatorio)
  notify/
    telegram.js              # sendTelegram(text)
    email.js                 # sendEmail(subject, text)
  report.js                  # writeReport(), appendHistorico()
  run.js                     # orquestador del barrido
state/
  estado-salud.json          # snapshot actual (commit)
  historico/                 # YYYY-MM.jsonl (commit)
test/
  *.test.js
```

---

### Task 1: Scaffold del repo

**Files:**
- Create: `package.json`, `.gitignore`, `.env.example`, `src/config.js`, `src/lib/time.js`
- Test: `test/time.test.js`

**Interfaces:**
- Produces: `config` object (`{ activeHours:{startCdmx:8,endCdmx:22}, cadenceMin:90, n8n:{base,botId,paymentId,retomarId}, thresholds:{...} }`); `isActiveHour(dateUtc) -> boolean`; `nowUtc() -> Date`.

- [ ] **Step 1: Crear `package.json`**

```json
{
  "name": "agente-monitoreo",
  "version": "0.1.0",
  "type": "module",
  "engines": { "node": ">=20" },
  "scripts": {
    "test": "node --test",
    "run:sweep": "node src/run.js"
  },
  "dependencies": {
    "pg": "^8.11.0",
    "nodemailer": "^6.9.0"
  }
}
```

- [ ] **Step 2: Crear `.gitignore` y `.env.example`**

`.gitignore`:
```
node_modules/
.env
.env.local
```

`.env.example`:
```
DATABASE_URL=postgres://readonly_leads:...@host:5432/db
N8N_API_KEY=
N8N_BASE_URL=https://n8n.srv1325340.hstgr.cloud
META_ACCESS_TOKEN=
HEROKU_OAUTH_TOKEN=
HEROKU_APP_NAME=hyl-wai-production
LANDING_URL=https://seguroautoqualitas.com
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
ALERT_EMAIL_TO=a.ibanez@gmail.com
```

- [ ] **Step 3: Escribir el test de `time.js` (falla primero)**

`test/time.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { isActiveHour } from '../src/lib/time.js';

test('10:00 CDMX (16:00 UTC) es horario activo', () => {
  assert.equal(isActiveHour(new Date('2026-07-06T16:00:00Z')), true);
});
test('03:00 CDMX (09:00 UTC) NO es horario activo', () => {
  assert.equal(isActiveHour(new Date('2026-07-06T09:00:00Z')), false);
});
test('22:00 CDMX (04:00 UTC día siguiente) es límite: NO activo', () => {
  assert.equal(isActiveHour(new Date('2026-07-07T04:00:00Z')), false);
});
```

- [ ] **Step 4: Ejecutar y ver que falla**

Run: `npm test`
Expected: FAIL — `Cannot find module '../src/lib/time.js'`

- [ ] **Step 5: Implementar `src/lib/time.js` y `src/config.js`**

`src/lib/time.js`:
```js
// CDMX = UTC-6 fijo (sin DST desde 2023).
export function nowUtc() { return new Date(); }
export function cdmxHour(dateUtc) {
  return (dateUtc.getUTCHours() + 24 - 6) % 24;
}
export function isActiveHour(dateUtc, startCdmx = 8, endCdmx = 22) {
  const h = cdmxHour(dateUtc);
  return h >= startCdmx && h < endCdmx;
}
```

`src/config.js`:
```js
export const config = {
  activeHours: { startCdmx: 8, endCdmx: 22 },
  cadenceMin: 90,
  n8n: {
    base: process.env.N8N_BASE_URL || 'https://n8n.srv1325340.hstgr.cloud',
    botId: 'BtOaZm7WlZT-24V7hqCnF',
    paymentId: 'disvKr7iVhnNnefuiqJbJ',
    retomarId: '96XfJZcwvlHnVJLko3G8-',
    prodWorkflowIds: ['BtOaZm7WlZT-24V7hqCnF', 'disvKr7iVhnNnefuiqJbJ', '96XfJZcwvlHnVJLko3G8-']
  },
  landingUrl: process.env.LANDING_URL || 'https://seguroautoqualitas.com',
  vinRegex: /^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$/,
  thresholds: {
    inboundGapMinutes: 120,     // check 1: gap entrante que dispara FAIL
    outboundMin2h: 3,           // check 1/2: actividad saliente mínima para exigir entrante
    leadGapHours: 3,            // check 3: sin leads nuevos en horas activas
    reminderHours: 12           // recordatorio de FAIL en curso
  }
};
```

- [ ] **Step 6: Ejecutar test y confirmar PASS**

Run: `npm test`
Expected: PASS (3/3 en time.test.js)

- [ ] **Step 7: Init git + commit**

```bash
git init && git add -A
git commit -m "chore: scaffold Agente-Monitoreo (config + time helpers)"
```

---

### Task 2: Librerías de I/O (db, n8n API, http)

**Files:**
- Create: `src/lib/db.js`, `src/lib/n8nApi.js`, `src/lib/http.js`
- Test: `test/http.test.js`

**Interfaces:**
- Produces:
  - `query(sql, params) -> Promise<rows[]>` (throws si la BD no responde).
  - `n8n.lastExecution(workflowId) -> Promise<{startedAt:Date}|null>`; `n8n.listWorkflows() -> Promise<[{id,active,name}]>`; `n8n.reachable() -> Promise<boolean>`.
  - `httpOk(url) -> Promise<{ok:boolean, status:number}>`.

- [ ] **Step 1: Escribir test de `http.js` (falla primero)**

`test/http.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { httpOk } from '../src/lib/http.js';

test('httpOk devuelve ok=false y status=0 en host inexistente', async () => {
  const r = await httpOk('https://no-existe.invalid.localhost.zzz', 2000);
  assert.equal(r.ok, false);
  assert.equal(r.status, 0);
});
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `npm test`
Expected: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar `src/lib/http.js`**

```js
export async function httpOk(url, timeoutMs = 8000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: ctrl.signal, redirect: 'follow' });
    return { ok: res.ok, status: res.status };
  } catch {
    return { ok: false, status: 0 };
  } finally { clearTimeout(t); }
}
```

- [ ] **Step 4: Implementar `src/lib/db.js`**

```js
import pg from 'pg';
let pool;
function getPool() {
  if (!pool) pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 8000,
    max: 2
  });
  return pool;
}
export async function query(sql, params = []) {
  const r = await getPool().query(sql, params);
  return r.rows;
}
export async function closeDb() { if (pool) await pool.end(); pool = null; }
```

- [ ] **Step 5: Implementar `src/lib/n8nApi.js`**

```js
import { config } from '../config.js';
const base = () => `${config.n8n.base}/api/v1`;
const headers = () => ({ 'X-N8N-API-KEY': process.env.N8N_API_KEY });

async function apiGet(path) {
  const res = await fetch(`${base()}${path}`, { headers: headers() });
  if (!res.ok) throw new Error(`n8n API ${res.status} on ${path}`);
  return res.json();
}
export const n8n = {
  async reachable() {
    try { await apiGet('/workflows?limit=1'); return true; } catch { return false; }
  },
  async listWorkflows() {
    const d = await apiGet('/workflows?limit=100');
    return d.data.map(w => ({ id: w.id, active: w.active, name: w.name }));
  },
  async lastExecution(workflowId) {
    const d = await apiGet(`/executions?workflowId=${workflowId}&limit=1`);
    const e = d.data?.[0];
    return e ? { startedAt: new Date(e.startedAt) } : null;
  }
};
```

- [ ] **Step 6: Ejecutar test y confirmar PASS**

Run: `npm test`
Expected: PASS (http.test.js). db/n8n se validan en integración (Task 10).

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: I/O libs (db readonly, n8n API, http probe)"
```

---

### Task 3: Motor de estado (diff snapshot → transiciones)

**Files:**
- Create: `src/state.js`
- Test: `test/state.test.js`

**Interfaces:**
- Consumes: snapshot = `{ [checkId]: { status, evidence } }`.
- Produces:
  - `loadState(dir) -> prevState` (objeto `{}` si no existe).
  - `saveState(dir, state) -> void`.
  - `diffState(prev, curr, nowUtc, reminderHours) -> { nextState, transitions:[{id,type,from,to,evidence,since}] }` donde `type ∈ {new_fail, recovery, reminder, escalation}`.

- [ ] **Step 1: Escribir tests (falla primero)**

`test/state.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { diffState } from '../src/state.js';

const t0 = new Date('2026-07-06T16:00:00Z');
const later = new Date('2026-07-06T16:00:00Z');

test('OK->FAIL produce new_fail', () => {
  const prev = { c1: { status: 'OK', since: '2026-07-06T14:00:00Z', alerted: false } };
  const curr = { c1: { status: 'FAIL', evidence: 'x' } };
  const { transitions } = diffState(prev, curr, t0, 12);
  assert.equal(transitions.length, 1);
  assert.equal(transitions[0].type, 'new_fail');
});

test('FAIL->FAIL dentro de 12h NO alerta', () => {
  const prev = { c1: { status: 'FAIL', since: '2026-07-06T15:30:00Z', alerted: true } };
  const curr = { c1: { status: 'FAIL', evidence: 'x' } };
  const { transitions } = diffState(prev, curr, t0, 12);
  assert.equal(transitions.length, 0);
});

test('FAIL->FAIL tras 12h produce reminder', () => {
  const prev = { c1: { status: 'FAIL', since: '2026-07-06T03:00:00Z', alerted: true } };
  const curr = { c1: { status: 'FAIL', evidence: 'x' } };
  const { transitions } = diffState(prev, curr, t0, 12);
  assert.equal(transitions[0].type, 'reminder');
});

test('FAIL->OK produce recovery', () => {
  const prev = { c1: { status: 'FAIL', since: '2026-07-06T15:00:00Z', alerted: true } };
  const curr = { c1: { status: 'OK', evidence: 'ok' } };
  const { transitions } = diffState(prev, curr, t0, 12);
  assert.equal(transitions[0].type, 'recovery');
});

test('WARN->FAIL produce escalation', () => {
  const prev = { c1: { status: 'WARN', since: '2026-07-06T15:00:00Z', alerted: false } };
  const curr = { c1: { status: 'FAIL', evidence: 'x' } };
  const { transitions } = diffState(prev, curr, t0, 12);
  assert.equal(transitions[0].type, 'escalation');
});

test('UNKNOWN no dispara alerta ni pisa el since previo', () => {
  const prev = { c1: { status: 'OK', since: '2026-07-06T14:00:00Z', alerted: false } };
  const curr = { c1: { status: 'UNKNOWN', evidence: 'db down' } };
  const { transitions, nextState } = diffState(prev, curr, t0, 12);
  assert.equal(transitions.length, 0);
  assert.equal(nextState.c1.status, 'UNKNOWN');
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — `src/state.js` no existe.

- [ ] **Step 3: Implementar `src/state.js`**

```js
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export function loadState(dir) {
  const f = join(dir, 'estado-salud.json');
  if (!existsSync(f)) return {};
  try { return JSON.parse(readFileSync(f, 'utf8')); } catch { return {}; }
}
export function saveState(dir, state) {
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'estado-salud.json'), JSON.stringify(state, null, 2));
}

const isBad = s => s === 'FAIL';

export function diffState(prev, curr, nowUtc, reminderHours) {
  const transitions = [];
  const nextState = {};
  for (const [id, cur] of Object.entries(curr)) {
    const p = prev[id] || { status: 'OK', since: nowUtc.toISOString(), alerted: false };
    const from = p.status, to = cur.status;
    let since = p.since, alerted = p.alerted || false;

    // UNKNOWN: no transiciona ni alerta; conserva since previo.
    if (to === 'UNKNOWN') {
      nextState[id] = { status: 'UNKNOWN', since, alerted, evidence: cur.evidence };
      continue;
    }
    if (to !== from) { since = nowUtc.toISOString(); alerted = false; }

    if (isBad(to) && !isBad(from)) {
      transitions.push({ id, type: from === 'WARN' ? 'escalation' : 'new_fail', from, to, evidence: cur.evidence, since });
      alerted = true;
    } else if (isBad(to) && isBad(from)) {
      const hrs = (nowUtc - new Date(since)) / 3.6e6;
      if (hrs >= reminderHours) {
        transitions.push({ id, type: 'reminder', from, to, evidence: cur.evidence, since });
        since = nowUtc.toISOString(); // resetea la cuenta del recordatorio
      }
    } else if (!isBad(to) && isBad(from)) {
      transitions.push({ id, type: 'recovery', from, to, evidence: cur.evidence, since });
    }
    nextState[id] = { status: to, since, alerted, evidence: cur.evidence };
  }
  return { nextState, transitions };
}
```

- [ ] **Step 4: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS (6/6 en state.test.js).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: state engine con dedup por transición + recordatorio 12h"
```

---

### Task 4: Formateo de alertas (transiciones → texto)

**Files:**
- Create: `src/alerts.js`
- Test: `test/alerts.test.js`

**Interfaces:**
- Consumes: `transitions[]` de Task 3, `checkMeta` (`{id -> {name, pillar}}`).
- Produces: `formatAlerts(transitions, checkMeta) -> [{ level:'push'|'digest', title, body }]`. `new_fail`/`escalation`/`recovery`/`reminder` → `push`. (El diagnóstico enriquecido lo añade el agente en run.js; aquí es el mensaje base.)

- [ ] **Step 1: Escribir test (falla primero)**

`test/alerts.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatAlerts } from '../src/alerts.js';

const meta = { c1: { name: 'Inbound Meta→n8n', pillar: 1 } };

test('new_fail -> push con título 🔴', () => {
  const out = formatAlerts([{ id: 'c1', type: 'new_fail', to: 'FAIL', evidence: '0 entrantes/2h' }], meta);
  assert.equal(out[0].level, 'push');
  assert.match(out[0].title, /🔴/);
  assert.match(out[0].body, /Inbound Meta→n8n/);
  assert.match(out[0].body, /0 entrantes/);
});
test('recovery -> push con ✅', () => {
  const out = formatAlerts([{ id: 'c1', type: 'recovery', to: 'OK', evidence: 'exec nueva' }], meta);
  assert.match(out[0].title, /✅/);
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — módulo no existe.

- [ ] **Step 3: Implementar `src/alerts.js`**

```js
const ICON = { new_fail: '🔴', escalation: '🔴', reminder: '⏰', recovery: '✅' };
const VERB = {
  new_fail: 'FALLO detectado', escalation: 'ESCALADO a fallo',
  reminder: 'sigue FALLANDO', recovery: 'RECUPERADO'
};
export function formatAlerts(transitions, checkMeta) {
  return transitions.map(t => {
    const m = checkMeta[t.id] || { name: t.id, pillar: '?' };
    return {
      level: 'push',
      title: `${ICON[t.type]} [P${m.pillar}] ${m.name} — ${VERB[t.type]}`,
      body: `Check: ${m.name}\nEstado: ${t.to}\nEvidencia: ${t.evidence ?? '—'}`
    };
  });
}
```

- [ ] **Step 4: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: formateo de alertas por tipo de transición"
```

---

### Task 5: Checks Pilar 1 — Uptime

**Files:**
- Create: `src/checks/pillar1_uptime.js`
- Test: `test/pillar1.test.js`

**Interfaces:**
- Cada check exporta `{ id, name, pillar, async run(ctx) -> {status, evidence} }` donde `ctx = { query, n8n, httpOk, config, nowUtc }`.
- Separar lógica pura `evaluate*(metrics)` (testeable) del fetch.
- Produces: `pillar1Checks` (array de checks 0,1,2,3,4,5,12,13).

- [ ] **Step 1: Escribir tests de los evaluadores puros (falla primero)**

`test/pillar1.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { evalInbound, evalWorkflowsActive, evalLeadIntake } from '../src/checks/pillar1_uptime.js';

test('inbound FAIL: hay salientes pero gap entrante > umbral', () => {
  const r = evalInbound({ outbound2h: 5, inboundGapMin: 200 }, { inboundGapMinutes: 120, outboundMin2h: 3 });
  assert.equal(r.status, 'FAIL');
});
test('inbound OK: gap entrante corto', () => {
  const r = evalInbound({ outbound2h: 5, inboundGapMin: 10 }, { inboundGapMinutes: 120, outboundMin2h: 3 });
  assert.equal(r.status, 'OK');
});
test('inbound OK: sin salientes (madrugada) no exige entrante', () => {
  const r = evalInbound({ outbound2h: 0, inboundGapMin: 999 }, { inboundGapMinutes: 120, outboundMin2h: 3 });
  assert.equal(r.status, 'OK');
});
test('workflows FAIL si alguno de prod no está activo', () => {
  const r = evalWorkflowsActive([{ id: 'BtOaZm7WlZT-24V7hqCnF', active: false }], ['BtOaZm7WlZT-24V7hqCnF']);
  assert.equal(r.status, 'FAIL');
});
test('lead intake WARN si 0 leads en la franja de horas', () => {
  const r = evalLeadIntake({ leadsInWindow: 0 }, { leadGapHours: 3 });
  assert.equal(r.status, 'WARN');
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — módulo no existe.

- [ ] **Step 3: Implementar `src/checks/pillar1_uptime.js`**

```js
// ---- Evaluadores puros ----
export function evalInbound(m, th) {
  if (m.outbound2h < th.outboundMin2h) return { status: 'OK', evidence: `sin tráfico saliente (${m.outbound2h}/2h)` };
  if (m.inboundGapMin > th.inboundGapMinutes)
    return { status: 'FAIL', evidence: `${m.outbound2h} salientes/2h pero ${Math.round(m.inboundGapMin)}min sin entrante` };
  return { status: 'OK', evidence: `entrante hace ${Math.round(m.inboundGapMin)}min` };
}
export function evalWorkflowsActive(workflows, prodIds) {
  const inactive = prodIds.filter(id => { const w = workflows.find(x => x.id === id); return !w || !w.active; });
  return inactive.length
    ? { status: 'FAIL', evidence: `workflows de prod inactivos: ${inactive.join(', ')}` }
    : { status: 'OK', evidence: 'los 3 workflows de prod activos' };
}
export function evalLeadIntake(m, th) {
  return m.leadsInWindow === 0
    ? { status: 'WARN', evidence: `0 leads en las últimas ${th.leadGapHours}h activas` }
    : { status: 'OK', evidence: `${m.leadsInWindow} leads recientes` };
}

// ---- Checks (fetch + evaluate) ----
const check0Db = {
  id: 'db_reachable', name: 'Postgres alcanzable', pillar: 1,
  async run(ctx) {
    try { await ctx.query('SELECT 1'); return { status: 'OK', evidence: 'BD responde' }; }
    catch (e) { return { status: 'FAIL', evidence: `BD no responde: ${e.message}` }; }
  }
};
const check1Inbound = {
  id: 'inbound', name: 'Inbound Meta→n8n vivo', pillar: 1,
  async run(ctx) {
    const [{ c: outbound2h }] = await ctx.query(
      `SELECT count(*)::int c FROM qualitas_whatsappmessage
       WHERE direction='OUTBOUND' AND sent_at > now() - interval '2 hours'`);
    const last = await ctx.n8n.lastExecution(ctx.config.n8n.botId);
    const inboundGapMin = last ? (ctx.nowUtc() - last.startedAt) / 60000 : 1e9;
    return evalInbound({ outbound2h, inboundGapMin }, ctx.config.thresholds);
  }
};
const check2Followup = {
  id: 'followup15m', name: 'Follow-up 15m vivo', pillar: 1,
  async run(ctx) {
    const [{ c }] = await ctx.query(
      `SELECT count(*)::int c FROM qualitas_whatsappmessage
       WHERE template_name LIKE 'cotizacion_followup%' AND sent_at > now() - interval '3 hours'`);
    const [{ c: leads }] = await ctx.query(
      `SELECT count(*)::int c FROM qualitas_lead WHERE fecha_creacion > now() - interval '3 hours'`);
    if (leads >= ctx.config.thresholds.outboundMin2h && c === 0)
      return { status: 'FAIL', evidence: `${leads} leads nuevos pero 0 follow-ups en 3h (cf. Issue #74)` };
    return { status: 'OK', evidence: `${c} follow-ups/3h` };
  }
};
const check3Leads = {
  id: 'lead_intake', name: 'Entrada de leads viva', pillar: 1,
  async run(ctx) {
    const [{ c }] = await ctx.query(
      `SELECT count(*)::int c FROM qualitas_lead
       WHERE fecha_creacion > now() - interval '${ctx.config.thresholds.leadGapHours} hours'`);
    return evalLeadIntake({ leadsInWindow: c }, ctx.config.thresholds);
  }
};
const check4Workflows = {
  id: 'workflows_active', name: 'Workflows de prod activos', pillar: 1,
  async run(ctx) {
    const wfs = await ctx.n8n.listWorkflows();
    return evalWorkflowsActive(wfs, ctx.config.n8n.prodWorkflowIds);
  }
};
const check5N8n = {
  id: 'n8n_reachable', name: 'n8n alcanzable', pillar: 1,
  async run(ctx) {
    const ok = await ctx.n8n.reachable();
    return ok ? { status: 'OK', evidence: 'API n8n 200' } : { status: 'FAIL', evidence: 'API n8n no responde' };
  }
};
const check12Landing = {
  id: 'landing_http', name: 'Landing/Django HTTP', pillar: 1,
  async run(ctx) {
    const r = await ctx.httpOk(ctx.config.landingUrl);
    return r.ok ? { status: 'OK', evidence: `landing ${r.status}` }
                : { status: 'FAIL', evidence: `landing status ${r.status} (dyno Heroku?)` };
  }
};
const check13Heroku = {
  id: 'heroku', name: 'Heroku app/dyno/release', pillar: 1,
  async run(ctx) {
    if (!process.env.HEROKU_OAUTH_TOKEN) return { status: 'UNKNOWN', evidence: 'sin token Heroku (check desactivado)' };
    try {
      const res = await fetch(`https://api.heroku.com/apps/${process.env.HEROKU_APP_NAME}/dynos`, {
        headers: { Authorization: `Bearer ${process.env.HEROKU_OAUTH_TOKEN}`, Accept: 'application/vnd.heroku+json; version=3' }
      });
      if (!res.ok) return { status: 'FAIL', evidence: `Heroku API ${res.status}` };
      const dynos = await res.json();
      const up = dynos.filter(d => d.state === 'up').length;
      return up > 0 ? { status: 'OK', evidence: `${up} dynos up` } : { status: 'FAIL', evidence: 'ningún dyno up' };
    } catch (e) { return { status: 'UNKNOWN', evidence: `Heroku API err: ${e.message}` }; }
  }
};

export const pillar1Checks = [check0Db, check1Inbound, check2Followup, check3Leads, check4Workflows, check5N8n, check12Landing, check13Heroku];
```

- [ ] **Step 4: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS (5/5 en pillar1.test.js).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: checks Pilar 1 (uptime) con evaluadores puros testeados"
```

---

### Task 6: Checks Pilar 2 — Emisión

**Files:**
- Create: `src/checks/pillar2_emision.js`
- Test: `test/pillar2.test.js`

**Interfaces:**
- Produces: `pillar2Checks` (checks 6, 7). Consume `config.vinRegex`.

- [ ] **Step 1: Escribir tests de los evaluadores puros (falla primero)**

`test/pillar2.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { evalEmisionFallida, evalSerieInvalida } from '../src/checks/pillar2_emision.js';
import { config } from '../src/config.js';

test('emisión FAIL si hay marcas de error recientes', () => {
  assert.equal(evalEmisionFallida({ errorMarks: 2 }).status, 'FAIL');
});
test('emisión OK si 0 marcas', () => {
  assert.equal(evalEmisionFallida({ errorMarks: 0 }).status, 'OK');
});
test('serie inválida FAIL: "Gómez Palacio" (tiene espacio)', () => {
  const r = evalSerieInvalida(['Gómez Palacio', '3N1CN8AE40531VABC'], config.vinRegex);
  assert.equal(r.status, 'FAIL');
});
test('serie OK: VIN-17 válido', () => {
  const r = evalSerieInvalida(['1HGCM82633A004352'], config.vinRegex);
  assert.equal(r.status, 'OK');
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — módulo no existe.

- [ ] **Step 3: Implementar `src/checks/pillar2_emision.js`**

```js
export function evalEmisionFallida(m) {
  return m.errorMarks > 0
    ? { status: 'FAIL', evidence: `${m.errorMarks} marcas [api_error:issue_policy] recientes (Bug #9)` }
    : { status: 'OK', evidence: 'sin errores de emisión recientes' };
}
export function evalSerieInvalida(series, vinRegex) {
  const bad = series.filter(s => !vinRegex.test(String(s).trim().toUpperCase()));
  return bad.length
    ? { status: 'FAIL', evidence: `series inválidas emitidas: ${bad.slice(0, 5).join(' | ')}` }
    : { status: 'OK', evidence: `${series.length} series válidas` };
}

const check6 = {
  id: 'emision_fallida', name: 'Emisiones fallidas', pillar: 2,
  async run(ctx) {
    const [{ c }] = await ctx.query(
      `SELECT count(*)::int c FROM n8n_chat_histories
       WHERE message->>'content' LIKE '%[api_error:issue_policy]%'
         AND id > (SELECT COALESCE(max(id),0)-500 FROM n8n_chat_histories)`);
    return evalEmisionFallida({ errorMarks: c });
  }
};
const check7 = {
  id: 'serie_invalida', name: 'Serie/VIN inválido emitido', pillar: 2,
  async run(ctx) {
    const rows = await ctx.query(
      `SELECT message->>'content' AS content FROM n8n_chat_histories
       WHERE message->>'content' LIKE '%Calling Issue_Policy%'
       ORDER BY id DESC LIMIT 50`);
    const series = rows
      .map(r => (r.content.match(/parameters18_Value["'\s:]+([^"',}]+)/) || [])[1])
      .filter(Boolean);
    if (!series.length) return { status: 'OK', evidence: 'sin emisiones recientes que auditar' };
    return evalSerieInvalida(series, ctx.config.vinRegex);
  }
};
export const pillar2Checks = [check6, check7];
```

- [ ] **Step 4: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: checks Pilar 2 (emisión) — best effort sobre gap Bug #9"
```

---

### Task 7: Checks Pilar 3 — Integridad de datos

**Files:**
- Create: `src/checks/pillar3_datos.js`, `src/checks/registry.js`
- Test: `test/pillar3.test.js`

**Interfaces:**
- Produces: `pillar3Checks` (checks 8,9,10,11); `allChecks` (registry con los 14) y `checkMeta`.

- [ ] **Step 1: Escribir tests de los evaluadores puros (falla primero)**

`test/pillar3.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { evalPegadas, evalSinSesion, evalPrefijo57 } from '../src/checks/pillar3_datos.js';

test('sesiones pegadas WARN si hay >0', () => {
  assert.equal(evalPegadas({ stuck: 4 }).status, 'WARN');
});
test('sesiones pegadas OK si 0', () => {
  assert.equal(evalPegadas({ stuck: 0 }).status, 'OK');
});
test('leads sin sesión WARN si hay', () => {
  assert.equal(evalSinSesion({ orphans: 2 }).status, 'WARN');
});
test('prefijo 57 FAIL si hay (rompe funnel)', () => {
  assert.equal(evalPrefijo57({ co: 1 }).status, 'FAIL');
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — módulo no existe.

- [ ] **Step 3: Implementar `src/checks/pillar3_datos.js`**

```js
export function evalPegadas(m) {
  return m.stuck > 0
    ? { status: 'WARN', evidence: `${m.stuck} sesiones apuntando a cotización no-reciente (Bug #11)` }
    : { status: 'OK', evidence: 'sin sesiones pegadas' };
}
export function evalSinSesion(m) {
  return m.orphans > 0
    ? { status: 'WARN', evidence: `${m.orphans} leads recientes sin whatsapp_session (Bug #4)` }
    : { status: 'OK', evidence: 'todos los leads con sesión' };
}
export function evalPrefijo57(m) {
  return m.co > 0
    ? { status: 'FAIL', evidence: `${m.co} session_id con prefijo 57 (Colombia) en vez de 52 (Bug #2)` }
    : { status: 'OK', evidence: 'sin prefijos 57' };
}

const check8 = {
  id: 'sesion_pegada', name: 'Sesión pegada a cotización vieja', pillar: 3,
  async run(ctx) {
    const [{ c }] = await ctx.query(
      `SELECT count(*)::int c FROM whatsapp_sessions ws
       JOIN qualitas_cotizacion c ON c.id = ws.quotation_id
       WHERE EXISTS (
         SELECT 1 FROM qualitas_cotizacion c2
         WHERE c2.telefono = c.telefono AND c2.id > ws.quotation_id)`);
    return evalPegadas({ stuck: c });
  }
};
const check9 = {
  id: 'lead_sin_sesion', name: 'Leads sin whatsapp_session', pillar: 3,
  async run(ctx) {
    const [{ c }] = await ctx.query(
      `SELECT count(*)::int c FROM qualitas_lead l
       LEFT JOIN whatsapp_sessions ws ON ws.quotation_id = l.cotizacion_id
       WHERE l.fecha_creacion > now() - interval '24 hours' AND ws.quotation_id IS NULL`);
    return evalSinSesion({ orphans: c });
  }
};
const check10 = {
  id: 'prefijo_57', name: 'Prefijo 57 (Colombia)', pillar: 3,
  async run(ctx) {
    const [{ c }] = await ctx.query(
      `SELECT count(*)::int c FROM whatsapp_sessions WHERE session_id LIKE '57%'`);
    return evalPrefijo57({ co: c });
  }
};
const check11 = {
  id: 'timestamps_naive', name: '(Info) timestamps naive', pillar: 3,
  async run(ctx) {
    const rows = await ctx.query(
      `SELECT count(*)::int c FROM information_schema.columns
       WHERE table_schema='public' AND data_type='timestamp without time zone'
         AND table_name IN ('whatsapp_sessions','whatsapp_sessions_archive')`);
    const c = rows[0].c;
    return c > 0 ? { status: 'WARN', evidence: `${c} columnas naive pendientes (Issue #87)` }
                 : { status: 'OK', evidence: 'sin timestamps naive' };
  }
};
export const pillar3Checks = [check8, check9, check10, check11];
```

- [ ] **Step 4: Implementar `src/checks/registry.js`**

```js
import { pillar1Checks } from './pillar1_uptime.js';
import { pillar2Checks } from './pillar2_emision.js';
import { pillar3Checks } from './pillar3_datos.js';

export const allChecks = [...pillar1Checks, ...pillar2Checks, ...pillar3Checks];
export const checkMeta = Object.fromEntries(
  allChecks.map(c => [c.id, { name: c.name, pillar: c.pillar }]));
```

- [ ] **Step 5: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS (todos los pilares).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: checks Pilar 3 (integridad) + registry de los 14 checks"
```

---

### Task 8: Notificadores (Telegram + Email)

**Files:**
- Create: `src/notify/telegram.js`, `src/notify/email.js`
- Test: `test/notify.test.js`

**Interfaces:**
- Produces: `sendTelegram(text) -> Promise<{ok}>`; `sendEmail(subject, text) -> Promise<{ok}>`. Ambos no-op con `{ok:false, skipped:true}` si falta su config (para correr en local sin secretos).

- [ ] **Step 1: Escribir test (falla primero)**

`test/notify.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sendTelegram } from '../src/notify/telegram.js';

test('sendTelegram se salta (no throw) si faltan credenciales', async () => {
  delete process.env.TELEGRAM_BOT_TOKEN;
  const r = await sendTelegram('hola');
  assert.equal(r.skipped, true);
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — módulo no existe.

- [ ] **Step 3: Implementar `src/notify/telegram.js`**

```js
export async function sendTelegram(text) {
  const token = process.env.TELEGRAM_BOT_TOKEN, chat = process.env.TELEGRAM_CHAT_ID;
  if (!token || !chat) return { ok: false, skipped: true };
  const res = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: chat, text: text.slice(0, 4000), disable_web_page_preview: true })
  });
  return { ok: res.ok };
}
```

- [ ] **Step 4: Implementar `src/notify/email.js`**

```js
import nodemailer from 'nodemailer';
export async function sendEmail(subject, text) {
  if (!process.env.SMTP_HOST) return { ok: false, skipped: true };
  const tx = nodemailer.createTransport({
    host: process.env.SMTP_HOST, port: Number(process.env.SMTP_PORT || 587),
    secure: false, auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
  });
  await tx.sendMail({ from: process.env.SMTP_USER, to: process.env.ALERT_EMAIL_TO, subject, text });
  return { ok: true };
}
```

- [ ] **Step 5: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: notificadores Telegram + Email (no-op sin credenciales)"
```

---

### Task 9: Reporte y histórico

**Files:**
- Create: `src/report.js`
- Test: `test/report.test.js`

**Interfaces:**
- Produces: `renderReport(state, nowUtc) -> string` (markdown); `appendHistorico(dir, snapshot, nowUtc) -> void` (una línea JSON por corrida en `historico/YYYY-MM.jsonl`).

- [ ] **Step 1: Escribir test (falla primero)**

`test/report.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderReport } from '../src/report.js';

test('renderReport lista checks con su semáforo', () => {
  const state = { c1: { status: 'FAIL', evidence: 'x', since: '2026-07-06T14:00:00Z' } };
  const md = renderReport(state, new Date('2026-07-06T16:00:00Z'));
  assert.match(md, /🔴/);
  assert.match(md, /c1/);
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL.

- [ ] **Step 3: Implementar `src/report.js`**

```js
import { appendFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const DOT = { OK: '🟢', WARN: '🟡', FAIL: '🔴', UNKNOWN: '⚪' };

export function renderReport(state, nowUtc) {
  const lines = [`# Último reporte de salud`, ``, `> Generado: ${nowUtc.toISOString()}`, ``,
    `| Check | Estado | Desde | Evidencia |`, `|---|---|---|---|`];
  for (const [id, s] of Object.entries(state))
    lines.push(`| ${id} | ${DOT[s.status] || '?'} ${s.status} | ${s.since || '—'} | ${s.evidence || '—'} |`);
  return lines.join('\n') + '\n';
}
export function writeReport(dir, md) {
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'ULTIMO-REPORTE.md'), md);
}
export function appendHistorico(dir, snapshot, nowUtc) {
  const h = join(dir, 'historico'); mkdirSync(h, { recursive: true });
  const ym = nowUtc.toISOString().slice(0, 7);
  const summary = Object.fromEntries(Object.entries(snapshot).map(([k, v]) => [k, v.status]));
  appendFileSync(join(h, `${ym}.jsonl`), JSON.stringify({ ts: nowUtc.toISOString(), checks: summary }) + '\n');
}
```

- [ ] **Step 4: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: reporte markdown + histórico jsonl"
```

---

### Task 10: Orquestador del barrido (run.js)

**Files:**
- Create: `src/run.js`
- Test: `test/run.smoke.test.js`

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: `runSweep({ force }) -> Promise<{ transitions, state, skipped }>`. Fuera de horario activo y sin `force` → `{ skipped:true }`. Cada check corre aislado: si un check lanza excepción no controlada → se marca `UNKNOWN` (no tumba el barrido).

- [ ] **Step 1: Escribir smoke test con dependencias inyectadas (falla primero)**

`test/run.smoke.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { evaluateChecks } from '../src/run.js';

test('evaluateChecks aísla un check que lanza -> UNKNOWN', async () => {
  const checks = [
    { id: 'ok1', run: async () => ({ status: 'OK', evidence: 'a' }) },
    { id: 'boom', run: async () => { throw new Error('db down'); } }
  ];
  const snap = await evaluateChecks(checks, {});
  assert.equal(snap.ok1.status, 'OK');
  assert.equal(snap.boom.status, 'UNKNOWN');
  assert.match(snap.boom.evidence, /db down/);
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL — `evaluateChecks` no existe.

- [ ] **Step 3: Implementar `src/run.js`**

```js
import { query } from './lib/db.js';
import { n8n } from './lib/n8nApi.js';
import { httpOk } from './lib/http.js';
import { config } from './config.js';
import { nowUtc, isActiveHour } from './lib/time.js';
import { allChecks, checkMeta } from './checks/registry.js';
import { loadState, saveState, diffState } from './state.js';
import { formatAlerts } from './alerts.js';
import { sendTelegram } from './notify/telegram.js';
import { renderReport, writeReport, appendHistorico } from './report.js';

const STATE_DIR = 'state';

export async function evaluateChecks(checks, ctx) {
  const snap = {};
  for (const c of checks) {
    try { snap[c.id] = await c.run(ctx); }
    catch (e) { snap[c.id] = { status: 'UNKNOWN', evidence: `excepción: ${e.message}` }; }
  }
  return snap;
}

export async function runSweep({ force = false } = {}) {
  const now = nowUtc();
  if (!force && !isActiveHour(now, config.activeHours.startCdmx, config.activeHours.endCdmx))
    return { skipped: true };

  const ctx = { query, n8n, httpOk, config, nowUtc };
  const snapshot = await evaluateChecks(allChecks, ctx);
  const prev = loadState(STATE_DIR);
  const { nextState, transitions } = diffState(prev, snapshot, now, config.thresholds.reminderHours);

  saveState(STATE_DIR, nextState);
  writeReport(STATE_DIR, renderReport(nextState, now));
  appendHistorico(STATE_DIR, nextState, now);

  for (const a of formatAlerts(transitions, checkMeta))
    await sendTelegram(`${a.title}\n\n${a.body}`);

  return { transitions, state: nextState, skipped: false };
}

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  runSweep({ force: process.argv.includes('--force') })
    .then(r => { console.log(JSON.stringify(r.skipped ? { skipped: true } : { transitions: r.transitions }, null, 2)); process.exit(0); })
    .catch(e => { console.error(e); process.exit(1); });
}
```

- [ ] **Step 4: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS (todos los tests, incl. run.smoke).

- [ ] **Step 5: Smoke run real contra prod (manual, con `.env` lleno)**

Run: `node src/run.js --force`
Expected: imprime `transitions` (probablemente `[]` si todo OK); crea `state/estado-salud.json`, `state/ULTIMO-REPORTE.md`, `state/historico/2026-07.jsonl`. Verifica el reporte a ojo.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: orquestador runSweep con aislamiento de checks + guard de horario"
```

---

### Task 11: Instrucciones del agente (capa de razonamiento) — CLAUDE.md

**Files:**
- Create: `CLAUDE.md` (raíz del repo Agente-Monitoreo)

**Interfaces:** documento en prosa; sin código. Es el "cerebro" que convierte un `FAIL` crudo en diagnóstico.

- [ ] **Step 1: Escribir `CLAUDE.md`**

Contenido (secciones obligatorias):
```markdown
# Agente de Monitoreo — Insurmind/Quálitas

Soy el Agente de Monitoreo (Nivel 3). Vigilo la salud E2E del funnel. NO ejecuto fixes:
diagnostico y reporto al Arquitecto (vía Alberto). No hablo con otros ejecutores.

## Qué hago en cada corrida
1. `node src/run.js` (o `--force` fuera de horario) — corre los 14 checks, actualiza estado,
   emite alertas de transición por Telegram.
2. Si hubo `new_fail` o `escalation`: NO me quedo en el mensaje base. Profundizo como hizo el
   Arquitecto con el Bug #12 — para cada FAIL, ejecuto queries/consultas extra para hallar la
   causa probable y la añado al mensaje (ver "Playbooks de diagnóstico").
3. Hago commit del estado (`state/`) para persistir el histórico entre corridas.

## Playbooks de diagnóstico (por check)
- **inbound FAIL:** revisar `GET /executions?workflowId=<bot>&limit=5` (¿última ejecución?),
  escanear duplicados que compartan el webhookId del trigger (colisión, causa del Bug #12),
  verificar workflow `active`. Reportar causa probable: colisión / token Meta / reinicio.
- **workflows_active FAIL:** listar cuál se desactivó; si hay un `_STG`/copy activo que comparte
  webhookId, es recaída de la colisión (consolidación, ver Arquitecto).
- **db_reachable FAIL:** es Heroku Postgres; marcar los checks de datos como UNKNOWN; escalar YA.
- **emision_fallida FAIL:** extraer `session_id`/póliza de las marcas; recordar gap de Bug #9.
- **serie_invalida FAIL:** listar las series malas; candidatas a reemisión manual con Quálitas.

## Digest diario (dead man's switch)
Una vez al día ejecuto el resumen y lo envío por Email + Telegram. Si YO no corro, Alberto deja de
recibir el digest → esa ausencia es la alerta de que el monitor cayó.

## Reglas
- Nunca escribo a Postgres (rol readonly). Nunca aplico fixes en n8n/Django.
- Todo estado se hace commit a git (persistencia entre laptops de Alberto).
- Timezone: UTC interno, CDMX solo en presentación.
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "docs: CLAUDE.md — capa de razonamiento/diagnóstico del agente"
```

---

### Task 12: Digest diario + scheduling + README

**Files:**
- Create: `src/digest.js`, `README.md`
- Test: `test/digest.test.js`

**Interfaces:**
- Produces: `buildDigest(state, historicoLines, nowUtc) -> {subject, text}`. Envía por Email + Telegram. Se dispara 1×/día (primera corrida después de las 09:00 CDMX).

- [ ] **Step 1: Escribir test (falla primero)**

`test/digest.test.js`:
```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildDigest } from '../src/digest.js';

test('digest resume conteos por estado', () => {
  const state = { a: { status: 'OK' }, b: { status: 'WARN', evidence: 'x' }, c: { status: 'FAIL', evidence: 'y' } };
  const d = buildDigest(state, [], new Date('2026-07-06T15:00:00Z'));
  assert.match(d.subject, /1 FAIL/);
  assert.match(d.text, /WARN/);
});
```

- [ ] **Step 2: Ejecutar y ver fallar**

Run: `npm test`
Expected: FAIL.

- [ ] **Step 3: Implementar `src/digest.js`**

```js
export function buildDigest(state, historicoLines, nowUtc) {
  const counts = { OK: 0, WARN: 0, FAIL: 0, UNKNOWN: 0 };
  for (const s of Object.values(state)) counts[s.status] = (counts[s.status] || 0) + 1;
  const problems = Object.entries(state)
    .filter(([, s]) => s.status === 'WARN' || s.status === 'FAIL')
    .map(([id, s]) => `- ${s.status} ${id}: ${s.evidence || ''}`).join('\n') || 'Todo OK ✅';
  const subject = `[Monitoreo] ${counts.FAIL} FAIL / ${counts.WARN} WARN — ${nowUtc.toISOString().slice(0,10)}`;
  const text = `Digest diario de salud E2E\n\nOK:${counts.OK} WARN:${counts.WARN} FAIL:${counts.FAIL} UNKNOWN:${counts.UNKNOWN}\n\n${problems}\n\n(Si dejas de recibir este digest, el monitor mismo puede estar caído.)`;
  return { subject, text };
}
```

- [ ] **Step 4: Añadir helpers de fecha-de-digest en `src/report.js`**

Para NO contaminar `estado-salud.json` (que `diffState` reconstruye solo con checks y borraría cualquier clave extra), la marca del último digest vive en un archivo aparte:
```js
import { readFileSync } from 'node:fs';   // añadir al import existente de node:fs
// ...
export function lastDigestDate(dir) {
  try { return JSON.parse(readFileSync(join(dir, '_digest.json'), 'utf8')).date; }
  catch { return null; }
}
export function markDigest(dir, isoDate) {
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, '_digest.json'), JSON.stringify({ date: isoDate }));
}
```

- [ ] **Step 5: Cablear el digest en `src/run.js`**

Añadir imports y, dentro de `runSweep` tras `appendHistorico(...)` y antes del bucle de alertas:
```js
import { buildDigest } from './digest.js';
import { sendEmail } from './notify/email.js';
import { cdmxHour } from './lib/time.js';
import { lastDigestDate, markDigest } from './report.js';   // junto a los otros de report
// ...dentro de runSweep, tras appendHistorico(STATE_DIR, nextState, now):
const today = now.toISOString().slice(0, 10);
if (cdmxHour(now) >= 9 && lastDigestDate(STATE_DIR) !== today) {
  const d = buildDigest(nextState, [], now);
  await sendEmail(d.subject, d.text);
  await sendTelegram(`📋 ${d.subject}\n\n${d.text}`);
  markDigest(STATE_DIR, today);
}
```
> Así el digest sale una sola vez al día (primera corrida tras las 09:00 CDMX) y `estado-salud.json` queda limpio de metadatos.

- [ ] **Step 6: Escribir `README.md`**

```markdown
# Agente de Monitoreo

Barrido de salud E2E del funnel Quálitas cada 90 min (08:00–22:00 CDMX).

## Uso
- `npm test` — tests unitarios.
- `node src/run.js --force` — corrida manual (ignora horario).

## Secretos (.env) — ver `.env.example`
DATABASE_URL (readonly_leads), N8N_API_KEY, LANDING_URL, TELEGRAM_*, SMTP_*, HEROKU_* (opcional).

## Scheduling
Se ejecuta como routine de Claude Code (skill /schedule) cada 90 min en horario activo, corriendo
`node src/run.js`. El digest diario sale en la primera corrida tras las 09:00 CDMX.
```

- [ ] **Step 7: Ejecutar y confirmar PASS**

Run: `npm test`
Expected: PASS (todos).

- [ ] **Step 8: Commit + push**

```bash
git add -A && git commit -m "feat: digest diario (dead man's switch) + README + scheduling docs"
git branch -M main && git remote add origin https://github.com/aibanez82/Agente-Monitoreo.git && git push -u origin main
```

- [ ] **Step 9: Crear el routine (fuera del código)**

Con la skill `/schedule`, crear un cloud agent programado que corra cada 90 min (08:00–22:00 CDMX) e invoque `node src/run.js` dentro del repo `Agente-Monitoreo`, con los secretos como env. Verificar la primera corrida real y que llega la alerta de prueba a Telegram.

---

## Self-Review (cobertura del spec)

- **Pilar 1 uptime** → Task 5 (checks 0,1,2,3,4,5,12,13). ✅
- **Pilar 2 emisión** → Task 6 (6,7). ✅
- **Pilar 3 integridad** → Task 7 (8,9,10,11). ✅
- **Estado en git + dedup por transición + recordatorio 12h** → Task 3. ✅
- **Anti-flapping (re-verificación)** → ⚠️ el spec pide re-verificar `OK→FAIL` en la misma corrida a los ~60s. En el plan quedó simplificado (una sola medición por corrida). **Decisión consciente:** con cadencia de 90 min el flapping es poco probable y añadir un sleep de 60s complica el orquestador; se difiere a v1.1 si se observan falsos positivos. Anotado como limitación.
- **Dependencia caída = UNKNOWN, nunca OK falso** → Task 10 (`evaluateChecks` captura excepción → UNKNOWN) + check0 db. ✅
- **Capa de inteligencia/diagnóstico** → Task 11 (CLAUDE.md playbooks). ✅
- **Telegram push + Email digest + dead man's switch** → Tasks 8, 12. ✅
- **Runtime cloud agent cada 90 min, horario activo** → Task 10 (guard) + Task 12 (routine). ✅
- **Accesos/prerequisitos** → `.env.example` (Task 1) + README (Task 12). Crear repo/bot/SMTP = acción de Alberto (aprobada).

**Type consistency:** `run(ctx)` con `ctx={query,n8n,httpOk,config,nowUtc}` usado consistentemente (Tasks 5–7, 10). `diffState`/`formatAlerts`/`renderReport` firmas coherentes entre Tasks 3,4,9,10. Estados `OK|WARN|FAIL|UNKNOWN` uniformes.

**Placeholder scan:** sin TBD/TODO; todo step con código real o comando concreto.
