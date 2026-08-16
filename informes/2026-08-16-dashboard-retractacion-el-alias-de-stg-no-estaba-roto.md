# Retractación — la integración de Git de Vercel nunca estuvo rota (Dashboard, 16 ago)

Retracto el **apartado 4** de mi informe
`informes/2026-08-16-dashboard-token-de-descuentos-y-el-alias-de-stg-informe.md` (16 ago, 10:46
-0600). Afirmé allí que el STG del Dashboard llevaba días sin desplegarse y que la integración de
Git del proyecto de Vercel estaba desenganchada. **Es falso.** Lo descubrí a las ~12:50 -0600, al ir
a reconectarla, y la corrección no llegó a escribirse a tiempo en este canal: el acuse `acf300f`
(14:35 -0600) se publicó sobre el diagnóstico ya caduco. El retraso es mío.

Todas las horas de aquí en adelante en **UTC**, medidas contra la API de Vercel.

## Lo que está medido

1. **La integración crea deployments hoy mismo.** Mi push de `c182dc6` a `stg` generó por sí solo
   `dpl_Eq8WfoHzc7Xjyi39VnLDAdG5McVE`, `githubCommitRef=stg`, estado `READY`, a las **20:37:23Z**.
   Yo no lancé ese deployment: solo pudo hacerlo la integración.
2. **El 13 ago no fue el último.** Hay deployments con `githubCommitRef=stg` en continuidad —
   14 ago (varios), 15 ago 03:28Z, y hoy 16 ago desde 04:46Z hasta 20:37Z. No hay corte.
3. **Estado del proyecto, sin ambigüedad.** `vercel git connect` responde *«already connected»*;
   la API da `gitProviderOptions.createDeployments: "enabled"`, sin *Ignored Build Step*,
   `productionBranch: main`, proyecto no pausado.

## Por qué me equivoqué — tres señales del CLI que mienten

1. **`vercel ls --meta githubCommitRef=<rama>` no filtra.** Devuelve lo mismo con filtro y sin él.
2. **`vercel inspect` no muestra ni rama ni commit.** Un auto-deploy de rama parece «manual, sin
   metadata de git».
3. **Los alias de rama se truncan a un hash** cuando el nombre del proyecto es largo. El
   `…-git-4f585b-…` que cité no era el de `stg`, sino el de `feature/issue-161`, apuntando además a
   un deployment `BLOCKED`. El de `stg` sí es legible:
   `dashboard-seguroautoqualitas-git-stg-albers-projects-52295059.vercel.app`.

Las tres coincidían entre sí, y coincidir no es corroborar cuando salen todas de la misma
herramienta. **Para hechos de plataforma, la fuente autoritativa es la API** (`/v6/deployments`,
`/v13/deployments/<id>`, `/v9/projects/<id>/env`, `/v4/aliases/<alias>`), nunca el CLI.

## Consecuencias

- **La decisión sobre las dos vías queda sin objeto.** Ni reconectar la integración —que era la
  recomendada— ni ampliar el scope de las variables a todo Preview. **Nada sube a Alberto por esto.**
- **La pista del 13 ago no lleva a ninguna parte.** Era un artefacto del filtro que no filtra.
- **El bloqueo del token ya no existe, y tampoco hace falta redeploy** (esto corrige a su vez lo que
  yo mismo escribí al avisar): el token `DISCOUNT_RECONCILIATION_DJANGO_TOKEN` (target `preview`,
  rama `stg`) se escribió a las **19:59:03Z**; el deployment al que apunta el alias de `stg` es de
  las **20:37:23Z**. El token está en el runtime que sirve STG. Si el panel de `#161` fallara ahí
  ahora, el sospechoso no es el token.

## Lo que sí queda en pie del informe original

Solo el apartado del token: sustituido, verificado por `sha256` (`309f98b9…` es el bueno), y la
comprobación de los 64 hex sin `\n`. Lo demás del apartado 4 hay que darlo por no escrito.

**Acción pendiente por mi parte: ninguna.** No he tocado nada en Vercel y no hay nada que tocar.

## Lo que me llevo

Una retractación solo existe si se escribe en el mismo canal que el error. Corregirlo en mi memoria
de trabajo y en conversación no alcanzó a quien ya estaba actuando sobre el informe, y por eso el
dictamen se publicó encima de un hecho falso. La próxima vez, la retractación se escribe antes que
nada.

— Dashboard, 16 ago
