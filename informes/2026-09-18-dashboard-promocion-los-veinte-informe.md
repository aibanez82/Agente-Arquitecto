# Informe — promoción `stg` → `main` de los veinte: hecha

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 18 sep 2026
**Responde a:** `Dashboard_seguroautoqualitas:handoffs/2026-09-14-promocion-de-stg-a-main-los-veinte.md` (`920ae10`)
**Orden:** Alberto, en sesión el 18 sep («sí, haz la promoción»), sobre tu autorización del 14.

Llegó con cuatro días de retraso: no la tenía vista hasta que Alberto me pidió revisar tus mensajes
hoy. Tu pregunta de la madrugada del 16 no me llegó por ningún canal que yo lea.

## Resultado

- **Merge:** `origin/main` = **`cf41a5a`**, `--no-ff` de `8d43117`, con el mensaje relatado.
- **Deployment de producción, según la API REST de Vercel** (`/v6/deployments`, `/v13/deployments`,
  `/v4/aliases`), no el CLI: **`dpl_7zxuKT5PbJrNCzom46nPtXMEFt4a`**, `READY`, `target: production`,
  `githubCommitRef: main`, `githubCommitSha: cf41a5a`. Creado 09:02:31 UTC, listo a los 46 s.
  Los tres alias (`dashboard-seguroautoqualitas.vercel.app`, `…-albers-projects-52295059…` y
  `…-git-main-…`) resuelven a ese `dpl_`.

## Tus números contra los míos

| Tuyo | Mío | |
|---|---|---|
| origen `origin/stg@8d43117` | `8d43117` | cuadra |
| destino `origin/main@d89e295` | **`920ae10`** | difiere, y es inocuo: `920ae10` es **tu propio handoff**, un fichero en `handoffs/`. Lo verifiqué (`git diff --stat d89e295 920ae10`) antes de seguir. |
| 20 commits, 10 cambios | 20 y 10 | cuadra; los 10 son los de la tabla del handoff |
| 460 pasan, 2 saltadas | **462 pasan, 0 fallan, 0 saltadas** con `HYL_WAI_REPO` | cuadra: son tus 460 más las 2 del contrato |
| `recovery-fixtures` 11/11 | 11/11 | cuadra, incluidas «FIELES al commit anclado» y «NO se ha movido por debajo» |

Además: el árbol del merge difiere de `8d43117` **solo** en `handoffs/` y `docs/`, que existen
únicamente en `main`. El código desplegado es byte a byte el probado.

## Comprobación en positivo, en producción

Sesión de Alberto (admin) en `dashboard-seguroautoqualitas.vercel.app`, con la Excel real de
canceladas de agosto ya leída por él (644 filas, 578 utilizables, 66 apartadas):

- **La pestaña carga**: cabecera, contadores, apartadas por motivo y tabla.
- **«Enviar por WhatsApp» está apagado, mirado en el DOM**, no deducido del color: `disabled: true`,
  `cursor: not-allowed`, `title` = «Primero hay que cargar el lote en la base de datos.», y ese
  mismo motivo **escrito debajo** de la fila de botones.

**Límite de lo que he mirado, dicho para que no se lea de más:** lo observado es el estado *lote no
cargado*. Tras «Cargar en BBDD», el código (`estadoCarga.js:77-79`, con `envioHabilitado: false`
en `CobranzaVencidaView.js:247`) lo mantiene apagado con otro motivo: «El envío por WhatsApp
todavía no está cableado (#360).». Eso **no** lo he visto en pantalla: verlo exigía escribir 578
clientes en el Django de PROD, y eso no estaba en el encargo. No he pulsado ni «Cargar en BBDD» ni
«Refrescar».

## Lo que no he tocado

`POST /api/cobranza/recovery` queda vivo tras el despliegue, como avisabas. No lo he cerrado, ni
protegido, ni tocado `envioHabilitado`: es el `#360`.

## Nota operativa

El token de Vercel del CLI había caducado (`invalidToken`); Alberto hizo `vercel login` en sesión.
Mientras tanto, los *deployment statuses* de GitHub ya daban `success` para `cf41a5a`, pero no los
di por buenos: la acreditación es la de la API de Vercel de arriba.

— Agente Dashboard
