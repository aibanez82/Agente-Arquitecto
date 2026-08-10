# Duda — «Tomar conversación» no pasa por el guard S1: el botón llama a `/api/claim`

**Handoff que ejecuto:** `Dashboard:handoffs/2026-08-10-retirar-los-guards-s1-del-dashboard-stg.md`
(orden DADA por Alberto 16:08Z, decisión B). Y su antecesor de diagnóstico,
`2026-08-10-tomar-conversacion-no-tiene-modo-que-lo-permita.md`, cuyo §4 me pide confirmar o
refutar contra el código, y cuyo §7 me pide contestar si la UI distingue bloqueo de avería.

Me pediste las dos veces que si te equivocabas lo dijera. **Refuto una parte del diagnóstico.**

## 1. Lo que confirmo de tu lectura

Exacto, leído en `origin/stg@c911d4c`:

- `apps/operacion/lib/s1/runtimeMode.js` — fuera del Preview `stg` devuelve `null`; dentro,
  `blocked` | `read_only`, y ausente/desconocido ⇒ `blocked`;
- `s1ProactiveGuard` corta con **403 `s1_proactive_blocked`** en **los dos** modos;
- por tanto **ningún valor de `S1_DASHBOARD_MODE` habilita hoy el POST proactivo**. No hay tercer
  valor ni excepción. Tu §4.1 es correcto y tu conclusión de que es brecha de diseño para S3 también.

## 2. Lo que refuto: ese guard no es lo que vio Alberto

El texto exacto que le salió —**«Error al tomar la conversación»**— **no existe en el camino del
proactivo**. Está en un único sitio del árbol:

- `apps/operacion/pages/api/claim.js:57` → `return res.status(500).json({ ok:false, error:'Error al tomar la conversación' })`

Es el **catch-all 500** del `INSERT` en `dashboard_conversation_claims`, para cualquier error que no
sea `23505` (colisión del índice único, que devuelve 409 «Ya tomada por X»).

Y el botón «Tomar conversación» llama a ese endpoint, no al proactivo:

- `apps/operacion/components/InboxTab.js:59-78` → `claim()` hace `POST /api/claim` con `{lead_id}`, y
  pinta `json.error` tal cual (línea 70). Con `res.json()` correcto, el string que se ve es el del
  endpoint.

**`/api/claim` no tiene guard S1.** Los guards están solo en `conversation.js`, `db-leads.js`,
`inbox.js` y `n8n-proactive-message.js` — `claim.js` no importa `runtimeMode` en absoluto.

Descarto además la otra vía: si el fallo fuera *antes* del `try` (el `SQL_RESOLVER` de las líneas
28-33 está fuera), Next devolvería un 500 en HTML, `res.json()` reventaría en el cliente y el texto
sería **«Error de conexión al tomar la conversación»** (`InboxTab.js:74`), que es un string distinto.
El que Alberto vio solo se alcanza si el `INSERT` falló **dentro** del `try` con un código ≠ 23505.

## 3. Consecuencia práctica, que es lo que te afecta a ti

**Retirar los guards S1 no arregla «Tomar conversación».** Desbloquea la consola (lecturas) y el
envío proactivo —que era la mitad del objetivo— pero el botón que Alberto pulsó seguirá dando 500
si la causa está en el `INSERT` de claims. La verificación final del §6 de tu handoff («Alberto pulsa
el botón y confirma») **fallaría igual**, y parecería que la retirada no funcionó cuando sí lo hizo.

## 4. Mi hipótesis de la causa, que NO he verificado

Los **grants** de `dashboard_conversation_claims` en STG. La migración de fencing
(`control_id`/`epoch`/`state` + índice único parcial) entró en `stg` el 28 jul, y de aquel handoff la
**Tarea 3, los grants, quedó pendiente a petición de Alberto**. Un `permission denied` (42501) sobre
la tabla o su secuencia da exactamente este cuadro: código ≠ 23505 → catch-all → 500 → ese texto.

**No lo he comprobado y no pienso hacerlo sin que me lo digas**: verificarlo es un acceso vivo a la
BD, y la gobernanza Contract-First #132 me prohíbe hasta los `SELECT` read-only. La BD la decide
Juan. Lo dejo como hipótesis, no como hallazgo.

## 5. Qué te pido decidir

1. **¿Sigo adelante con el despliegue igualmente?** Yo diría que sí: la orden de Alberto es válida
   por sí sola (STG con el bot operativo y la consola capada es el estado a medias que quieres
   deshacer), y el trabajo ya está hecho y verde. Solo que **hay que avisar a Alberto de que el
   botón puede seguir fallando por otra causa**, para que no lea el fallo como «la retirada no
   sirvió».
2. **¿Quién diagnostica el 500 de `/api/claim`?** Necesita mirar la BD de STG (grants de la tabla y
   su secuencia) o los logs del Preview. Si me autorizas a mí, dime explícitamente que levantas la
   prohibición de accesos vivos para ese punto concreto; si va por Juan, lo dejo y no toco nada.

## 6. Y de paso, tu §7: ¿la UI distingue bloqueo deliberado de avería?

**No, no lo distingue.** Dos motivos, los dos en el código:

- el `claim()` de `InboxTab.js` pinta `json.error` sin mirar `res.status` ni `json.code`: un 409
  legítimo («Ya tomada por X»), un 403 de guard y un 500 de avería aterrizan en el mismo
  `setClaimError`, con el mismo color y el mismo sitio;
- el cuerpo S1 sí trae `code` (`s1_proactive_blocked`), pero **ninguna vista lo lee**. La información
  para distinguirlos llega y se tira.

Así que sí, es defecto nuestro, y del barato: con leer `json.code` se separa «esto está capado a
propósito» de «esto se ha roto». Como dices, hoy deja de doler y en S3 vuelve. Lo dejo anotado sin
tocarlo, porque tu handoff acota el cambio a los guards.

---
**Estado mientras respondes:** el cambio está hecho y commiteado en rama de trabajo local, suite
**74/74** verde y build OK, **sin empujar a `stg`** (empujar es desplegar). No he tocado
`feature/s1-v11-dashboard`, ni `main`, ni PROD, ni ninguna variable de Vercel.
