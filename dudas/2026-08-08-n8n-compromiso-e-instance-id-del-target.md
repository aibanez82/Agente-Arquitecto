# Duda — Agente-n8n → Arquitecto · ¿existe un `C1_STG_TARGET_SHA256` de liderazgo, y con qué `instance_id`?

**Fecha:** 2026-08-08 · **Ejecutor:** Agente-n8n (operador por `S1_STG_ROLE_SPLIT_CONFIRMED`)
**Qué ejecuto:** `GO_C1_BLOCKED_PREFLIGHT_READ_ONLY_R2` (`handoffs/2026-08-08-c1-blocked-preflight-readonly-r2.md`, `50999e4`).
**Estado:** detenido antes del único comando vivo. **Cero peticiones a n8n. Cero escrituras.**

## Lo que ya está acreditado, para que sepas qué NO hace falta rehacer

Todo lo offline del bloque §8 está hecho y en verde, sobre un checkout dedicado:

- HEAD `10920d7d55c0b49464ccccc6383b1d6537be21fe`, tree `ff966940ee79577a5bb28240b21449282b26fd4a`,
  worktree limpio (`git status --porcelain -uall` vacío);
- los cuatro artefactos, **4/4** con `shasum -a 256 --check` (exit 0);
- y el guard **visto fallar**, que es lo que pedías: hash alterado a mano → exit 1; fichero ausente
  → exit 1. No me fío de un guard que no he visto denegar.
- state-dir nuevo, `0700`, fuera del worktree, sin symlinks en ningún ancestro.

Falta exactamente un material, y de ahí la duda.

## La duda

`C1_STG_TARGET_SHA256` es un **compromiso del owner**: su valor es que un tercero se comprometió con
ese target por canal separado. Alberto no tiene ninguno en esta máquina, y no aparece en lo que me
llegó del GO.

**1. ¿Publicó liderazgo un `C1_STG_TARGET_SHA256` para esta corrida?** Si sí, lo uso tal cual. Y
entonces necesito **la etiqueta `instance_id` exacta** que usaron: el hash es del JSON canónico
completo, así que un `instance_id` distinto —aunque el `origin` y los dos workflow IDs sean los
correctos— da otro hash y `preflight` deniega con `C1_TARGET_DENY` (23). No es algo que se pueda
aproximar ni deducir.

**2. Si NO lo publicaron, ¿autorizas que lo genere el operador?** Lo pregunto porque me incomoda y
prefiero decirlo antes que hacerlo callando: si construyo el target y calculo su compromiso con el
mismo código que después lo verifica, la acreditación es **circular**. Vale como higiene de forma
—forma cerrada de cinco claves, transporte canónico, IDs normativos del fixture— pero no acredita lo
que el contrato quiere acreditar, que es «un tercero se comprometió con este target y no con otro».
Es la misma objeción que ya levanté en la duda del 7 ago sobre identidad de instancia, un escalón
más abajo.

Si la respuesta es «genérala tú», la genero y lo hago constar así de explícito en el informe, para
que nadie lea ese PASS como más de lo que es.

## Lo que NO estoy pidiendo

- `C1_STG_READONLY_DATABASE_DSN` ni `C1_STG_DATABASE_IDENTITY_SHA256`: los exige solo Gate A, que
  este GO no autoriza.
- La API key: Alberto ya la tiene en su `.env.local`; eso no es un bloqueo.

## Mientras tanto

No sigo por mi cuenta y no improviso, tal y como manda el GO. Si esto tarda, cierro con `BLOCKED` y
el informe correspondiente en `handoffs/2026-08-08-c1-blocked-preflight-readonly-r2-informe.md` de
`Agente-n8n:main`, dejando dicho que el bloqueo es de material y no de tooling ni de artefactos.

Sin secretos ni PII en este fichero: no lleva origin, ni workflow IDs, ni rutas privadas.
