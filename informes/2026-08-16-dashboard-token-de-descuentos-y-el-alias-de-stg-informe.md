# Informe — Dashboard: gitflow aplicado, token de descuentos puesto, y **el deploy de STG no está llegando**

**16 ago 2026 · Agente Dashboard · por encargo de Alberto.** Todo lo que sigue está medido contra el
proyecto de Vercel y los repos, no leído. Lo importante del informe es el §4: **hay una variable
nueva que no está surtiendo efecto porque STG no se está desplegando desde hace 14 horas.**

---

## 1. Gitflow, aplicado también en el Dashboard

Ejecutado el handoff `2026-08-14-gitflow-en-todos-los-repos.md` (`157d385`). El patrón de
`CLAUDE.md` decía literalmente `git push origin main` — empujaba directo a la rama de PROD.

- La sección «Git» ahora resume el flujo y apunta a
  `/Users/AIP/claude-projects/Dashboard_SeguroAuto/docs/convenciones-de-rama.md`, en vez de repetir
  la regla. Mismo criterio que aplicaste en el repo de n8n.
- **Tres decisiones de Alberto**, ya escritas ahí: (1) el merge a `stg` lo hago yo sin pedir permiso
  —rama propia, gates verdes, `--no-ff`— reservando el PR para contratos y `#156`; (2) `main` solo
  con autorización suya explícita; (3) los docs del repo (`docs/bugs/`, `docs/patterns/`,
  `CLAUDE.md`) van por rama `docs/` a `stg`, y la excepción a `main` se queda **literal** en
  `handoffs/`, `dudas/` e `informes/`.
- El propio cambio entró por la convención que documenta: rama `docs/convencion-de-rama`, suite
  verde antes de integrar, `stg` sin commit directo. `stg` = `3cb14a7`.
- De paso, `CLAUDE.md` volvió a cumplir su propio límite: estaba en 10 244 bytes, por encima de los
  10 KB que él mismo fija.

## 2. Monitores

Alberto los mandó parar y luego rearmar dos. Estado actual: **`monitor-handoffs.sh`** (tu carpeta
`handoffs/` en nuestro `origin/main`) y **`monitor-arquitecto.sh`**, nuevo y versionado en
`scripts/`, que vigila **tu** repo — `dudas/<fecha>-dashboard-<tema>-respuesta.md`, que es por donde
llega tu dictamen y no aterriza en el nuestro. `stg` = `b98b276`.

## 3. `DISCOUNT_RECONCILIATION_DJANGO_TOKEN`, sustituida

Juan pidió a Alberto el valor que Django STG ya espera. Sustituida en Vercel, proyecto
`dashboard-seguroautoqualitas`, **Preview → rama `stg`**, tipo **Sensitive**. El valor no pasó por
ningún transcript: fue del portapapeles a un fichero con `umask 077` y de ahí al CLI por stdin;
comprobado antes de escribirlo que eran 64 caracteres hex sin salto de línea final —el `\n` de más
es el fallo clásico y habría parecido «token incorrecto»— y el fichero borrado después.

**La que había era de anoche y Django no la reconocía**, así que el carril nunca pudo completarse.
No puedo releerla para compararla byte a byte: Vercel la guarda como *Sensitive* y esas no se
recuperan ni con `vercel env pull`. La confirmación es la del CLI (`✓ Added … Branch stg … Type
Sensitive`).

## 4. El bloqueo — **STG no se está desplegando, y las env vars de rama probablemente no se aplican**

Medido en el proyecto de Vercel:

| hecho | evidencia |
|---|---|
| El alias de la rama `stg` apunta a un deployment de hace **14 h** | `dashboard-seguroautoqualita-git-4f585b-…` → `jgh76nqbq`, que además figura en estado **UNKNOWN** |
| El PR #3 (`#161`, mergeado anoche 22:46) **no generó deployment de rama** | el último con `githubCommitRef=stg` es del **13 ago** |
| Los deploys de anoche (22:55–23:02) fueron **manuales, sin metadata de git** | `vercel inspect` no muestra rama ni commit en ninguno de los tres |
| Mis dos merges de hoy tampoco dispararon nada | no hay deployments entre las 23:02 de anoche y el mío de ahora |

Lancé un `vercel deploy --target=preview` desde la punta de `stg`. **Construyó y quedó Ready, pero
no cumple el objetivo y lo digo antes de que alguien lo dé por bueno:** nació sin rama asociada y
sin alias, así que no cambia lo que el equipo ve en STG. Y hay una consecuencia peor, que es la
razón de este apartado: en Vercel una variable de Preview acotada a una rama **solo se inyecta si el
deployment lleva esa rama**. Los deploys manuales de anoche están en esa situación, y ahí dentro no
solo está el token — también `DATABASE_URL`, `DASHBOARD_DISCOUNTS_V06_ENABLED` y
`DISCOUNT_RECONCILIATION_DJANGO_BASE_URL`, todas marcadas `Preview (stg)`.

**Lo que pregunto, porque no es mío:** o se reconecta la integración de Git del proyecto para que un
push a `stg` vuelva a desplegar y a mover el alias —que es como funcionaba hasta el 13 ago—, o se
decide ampliar el scope de esas variables a todo Preview, con lo que eso implica (cualquier preview
del proyecto pasaría a llevar la credencial de Django y la BD de STG). No toco ninguna de las dos
por mi cuenta.

Hasta que eso se resuelva, **el panel de reconciliación de `#161` no es probable en STG**, por mucho
que el token ya esté bien puesto.

## 5. Contexto que conviene que tengas

- El **PR #3** lo firma `Pi Coding Agent <pi-coding-agent@localhost>`, que lleva **8 commits en el
  Dashboard** (los cuatro de `#156` del 13 ago, incluido `997c34b` —el SHA que el test `M0` de n8n
  pinea como «el checkout del Dashboard»— y los cuatro del `#161`) y **10 en Agente-n8n**. Se abrió
  y se mergeó con nueve segundos de diferencia: es trazabilidad, no revisión.
- **44 commits en `stg` sin promover a `main`**, con `#156` completo y `#161` entero. PROD no tiene
  nada de eso.
- El `#161` trae superficie nueva para el Dashboard: hasta ahora solo escribía en sus propias tablas
  de claims, y ahora **escribe hacia Django** (`POST /api/discount-reconciliation`, rol admin,
  token propio, `Idempotency-Key`).
