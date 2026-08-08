# Duda — los GET de conformidad del Dashboard no son observables sin una sesión de STG

**Agente:** Dashboard
**Handoff que ejecuto:** `Dashboard_SeguroAuto:handoffs/2026-08-08-s1-dashboard-read-only.md`
(`GO_DASHBOARD_S1_READ_ONLY`, `#132 c.5228367097`)
**Estado:** detenido **antes** de tocar nada. `S1_DASHBOARD_MODE` **no** se ha modificado; no se ha
redesplegado; no se ha ejecutado ninguna lectura ni ningún POST con efectos.

---

## 1. La duda en una frase

Todo el Preview de `stg` está detrás del middleware de sesión del Dashboard, así que **ni el `503
s1_dashboard_blocked`, ni la lectura servida en `read_only`, ni el `403 s1_proactive_blocked` son
observables sin una cookie `dashboard_session` válida** — y el GO exige acreditar el modo
**efectivo por comportamiento**, no el declarado. Me falta ese material.

## 2. El hecho, verificado contra el despliegue vivo

`apps/operacion/middleware.js@stg` deja pasar sin sesión solo `/login`, `/bootstrap-admin`,
`/api/auth`, `/_next`, `/favicon`, `/og-image` y `/api/admin/agents`; cualquier otra ruta sin cookie
se redirige a `/login`. Comprobado ahora mismo contra el alias del Preview de `stg` (sin cookie):

```text
GET  /api/db-leads             -> 307, location: /login?from=%2Fapi%2Fdb-leads
POST /api/n8n-proactive-message-> 307
```

Consecuencias para las tres cosas que pide el GO §4:

1. **Modo efectivo.** El guard de lectura vive **dentro** del handler (`db-leads.js:178`,
   `conversation.js:60`, `inbox.js:135`), y el redirect ocurre **antes**, en el edge. Sin sesión, un
   Preview en `blocked` y uno en `read_only` responden **exactamente igual** (307). El
   «declarado ≠ efectivo» que el GO quiere evitar no se puede cerrar por este camino.
2. **GET A/B de conformidad.** Mismo motivo: no llego al handler.
3. **Control negativo del proactivo.** El `s1ProactiveGuard` es lo primero del handler —antes de
   auth, BD, `fetch` y outbound— y eso sigue siendo cierto en el código; pero **tampoco es
   observable**, porque el 307 del middleware se lo come antes. Un `403` no lo puedo acreditar hoy.

**Lo que NO es el hueco:** los identificadores A/B, el `run-id` y el recipient los tengo por el canal
privado del owner; con sesión, los GET exactos salen del tirón.

## 3. Lo que me desbloquea (y lo que descarto por mi cuenta)

Me desbloquea **una credencial de `dashboard_users` en STG** con rol `admin` o `hylantt` — el rol
`agente` está acotado por `AGENTE_ALLOWED_API_PREFIXES` y no alcanza `/api/db-leads`. Con eso:
`POST /api/auth` → cookie → los GET del GO, en el orden del GO.

Descarto por mi cuenta, y las dejo explícitas para que se me corrija si alguna era la intención:

- **Firmar yo un JWT** con `JWT_SECRET` del Preview: fabricar una sesión no está autorizado y
  además acreditaría con una identidad que no existe en la base.
- **Crear un usuario** vía `/api/admin/agents` + `ADMIN_BOOTSTRAP_TOKEN`: es una **escritura viva**
  en STG fuera del alcance del GO.
- **Usar el DSN de solo lectura de STG** para leer A/B por SQL: el GO pide la evidencia por el
  **API efectivo** (§10.4 del contrato: «la evidencia Dashboard de F1/F2 proviene de
  `GET /api/db-leads` efectivo»), y un SELECT vivo no acredita el modo efectivo del despliegue.
- **Preguntárselo a Alberto**: el propio handoff §8 lo prohíbe («nunca preguntando a Alberto ni a
  otro agente»). Por eso esto viene aquí.

## 4. Respuestas posibles que veo

- **(a)** El owner suministra la credencial por el canal privado habitual
  (p. ej. `~/.c1-stg-private/env.sh`, como con el recipient y el DSN) → ejecuto el GO completo.
- **(b)** Autorizas explícitamente uno de los caminos descartados en §3 → ejecuto con esa salvedad
  publicada en el informe.
- **(c)** El GO se reinterpreta: la conformidad Dashboard de este paso se acredita por otra vía que
  tú fijes → la ejecuto tal cual.

Mientras tanto queda todo intacto y `S1_DASHBOARD_MODE` sigue **declarado** `blocked`. No publico
informe `BLOCKED` todavía porque no he llegado a acreditar `mode_before` por comportamiento y no
quiero que el registro diga que se intentó el cambio: no se ha intentado.
