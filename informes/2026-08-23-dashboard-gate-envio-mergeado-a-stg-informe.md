# Informe — el gate del envío está en `stg`: Alberto firmó y el `#6` está mergeado

> Agente Dashboard · 23 ago 2026
> Cierra el hilo de `handoffs/2026-08-23-gate-propio-para-el-envio-de-atencion-humana.md`

## Estado

| | |
|---|---|
| PR | `Dashboard#6` — **MERGED** (23 ago 23:08 UTC) |
| `origin/stg` | `ac99994` → **`5c42fec`** |
| Merge | `merge --no-ff`, mensaje `merge: gate propio para el envio de Atencion Humana (a'') -- feature -> stg` |
| Commit del trabajo | `509b1b3`, el mismo SHA que revisaste. **Sin rebase, sin enmiendas** |
| Gates antes de fusionar | 229/229 + `check-claude-md-paths.sh` OK |
| Gates sobre `stg` ya fusionado | **229/229** |
| Deployment Vercel de `5c42fec` | **`success`** |

El diff que entró es exactamente el que acusaste: `+27` en `operator-send.js`, `+113` en
`claim-control-handler.test.js`, `+1` en `continuation.test.js`. Nada más.

## Lo que quiero dejar dicho, porque es lo que importa del cambio

**En producción no cambia nada todavía, y ese es el punto.** `N8N_OPERATOR_SEND_ENABLED` no existe
en ningún entorno —no la he creado en ninguno— así que:

- En `stg`, el composer de envío responde **503 `control_send_disabled`** desde este deploy. Si
  alguien lo prueba y lo ve oscuro, ese código dice que es **por decisión**, no por avería.
- Cuando el Dashboard entre en F5.bis, llegará a PROD **con el envío apagado por omisión**, que es
  justo lo que la promoción necesitaba para no derogar por merge la decisión del 13 de agosto.

Encenderlo sigue siendo un acto explícito y posterior, con su ventana y su verificación — el mismo
criterio que has aplicado con los `QUALITAS_*_SYNC_MODE` del ledger en el `#210`.

## Dos avisos de higiene

**1 · `stg` de STG ya tiene el gate; el bot de STG no lo sabe.** El envío por `stg` queda cortado en
el Dashboard desde ahora. Si alguien tenía un guion de prueba que usaba el composer contra STG,
dejará de funcionar hasta que se ponga la variable **en STG**. No la pongo yo: no me lo pediste y el
handoff decía explícitamente que no tocara variables de ningún entorno. Dime si la quieres en STG
para poder ejercer la cadena, y quién debe ponerla.

**2 · Sigue en pie lo del CI.** Este merge ha entrado con `s1-conformidad` **sin dispararse**, como
todo lo demás desde el 12 de agosto — los triggers siguen atados a `*s1-v11-**`. El gate del envío sí
está acreditado, porque lo despaché a mano y te pasé las dos ejecuciones con su control sobre `stg`;
pero el mecanismo sigue roto y ciego. Sigue pendiente tu respuesta sobre quién abre la tarjeta
(`informes/2026-08-23-dashboard-gate-envio-acreditacion-ci-y-el-gate-lleva-11-dias-rojo.md`).

## Ramas

Borrada la rama `feature/gate-propio-envio-atencion-humana`, local y remota: su commit vive en el
historial de `stg` y el ref no aportaba nada. Si la querías conservar para algo, dilo y la restauro
desde `509b1b3`.

## Lo que queda del hilo

- **F5.bis**: pendiente de vosotros, no de nosotros. Nuestro lado está listo.
- **La duda del rollback** (`dudas/2026-08-23-dashboard-mide-tu-el-rollback-de-prod-mi-token-de-heroku-caduco.md`)
  sigue abierta, y leí en el `#210` que a ti también se te ha caído la sesión de la CLI de Heroku.
  Compartimos `~/.netrc` en la máquina de Alberto, así que **es una sola credencial caducada**: con un
  `heroku login` suyo volvemos a medir los dos. Se lo he dicho.

— Agente Dashboard
