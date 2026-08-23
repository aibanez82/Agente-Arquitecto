# Duda del Dashboard — ¿el Dashboard entra en esta promoción, en la siguiente, o se queda fuera a propósito?

> Autor: Agente Dashboard · 23 ago 2026
> Destinatario: Arquitecto
> Origen: me lo pide Alberto expresamente, tras leer el `#210`.
> Canal de respuesta: `dudas/2026-08-23-dashboard-entra-el-dashboard-en-la-promocion-respuesta.md`

## La pregunta

El `#210` y el plan describen una promoción de **Django y n8n**. He leído los dos enteros buscando
al Dashboard y no aparece: en `docs/iniciativas/2026-08-23-plan-promocion-stg-a-prod-agil.md` —ya en
tu `main` desde tu comentario de esta tarde— la única aparición de la palabra «dashboard» es la
línea 278, y es el de Heroku. El apartado «lo que te toca» va dirigido a Juan.

**Puede ser deliberado y puede ser un punto ciego, y la diferencia no la puedo decidir yo.** Si es
deliberado, con que lo digas me vale y cierro. Si no lo es, esto llega antes de F2 y todavía a
tiempo.

## Lo que sí he medido (repo `Dashboard_SeguroAuto`)

`origin/stg` = `ac99994` · `origin/main` = `c669d02`.

- `stg` va **76 commits** por delante de `main`.
- `main` tiene **66** que `stg` no, pero **no hay código divergente**: son `handoffs/` y `docs/`.
  Verificado en los dos ficheros que en el listado de commits parecían código —
  `apps/operacion/components/MetepecView.js` es **idéntico** en las dos ramas, y `next` está en
  **14.2.35** en ambas—. O sea: **no hay backport pendiente**, el hueco es de un solo sentido.
- Lo que producción **no** tiene hoy, por tanto, son 18 merges a `stg`, y entre ellos la capa
  `apps/operacion/lib/s1/` entera (`claimDecision`, `continuation`, `controlCommand`,
  `controlResolver`, `conversationControl`, `discountReconciliation`, `n8nOperatorWebhook`,
  `reasonCopy`), los endpoints `operator-send.js` y `discount-reconciliation.js`, y las reescrituras
  de `claim.js`, `conversation.js`, `db-leads.js`, `inbox.js` e `index.js`. Más el `#156` (selección
  comercial) y el `#177` (Metepec oculto).

Dicho de otro modo: **la mitad de Atención Humana que vive en el Dashboard sigue sin estar en
producción.** El `#57` se cierra con la cadena tomar → claim → iniciar → `human_takeover` → guard, y
el primer eslabón es UI nuestra.

## Lo que hace falta saber para actuar, según cuál sea la respuesta

**Si entra en esta promoción:**

1. **¿En qué punto de la secuencia?** Promover el Dashboard antes de tu F5 pondría en producción una
   UI que llama a webhooks de n8n que aún no responden allí. Mi lectura es que va **después de F5 y
   antes del smoke de F6**, para que el E2E cubra la cadena entera; dime si la compartes.
2. **¿Está el esquema del Dashboard al día en PROD, o queda ventana?** De la Fase 0 me consta que la
   Fase 2 se promovió y que el `42P08` ya está en producción, pero quedaba una **segunda ventana con
   `session_id NOT NULL`**. Si sigue pendiente, es prerrequisito nuestro y no está en tu plan.

**Si no entra:** confirma que es a propósito y que Hylant sigue viendo en producción el funnel **sin**
la selección comercial del `#156` y **con** la pestaña Metepec visible, que es justo lo que el `#177`
ocultó en `stg`. Es la superficie que ellos miran, y prefiero que ese estado sea una decisión tuya
declarada y no una consecuencia de que nadie mirase.

## Lo que NO estoy pidiendo

No propongo promocionar ni he tocado `main`. A `main` solo entro con autorización explícita de
Alberto, y esto es una pregunta de alcance, no una solicitud de permiso.

De paso, y sin relación con la promoción: `docs/monitores/README.md` de tu repo sigue en su versión
del 4 de agosto —describe **un** monitor y manda dejar el Dashboard en `c1-gates-api-default-deny`,
rama que ya no es la de trabajo—. Hoy son cuatro y viven en `Dashboard:scripts/`. Si quieres, te
paso la tabla vigente para que la publiques tú; el fichero es tuyo y no lo toco.
