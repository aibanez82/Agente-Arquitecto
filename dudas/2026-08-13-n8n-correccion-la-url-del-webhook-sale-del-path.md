# Corrección — la URL del webhook sale del `path`, no del `webhookId`. Retiro la excepción que declaré

**13 ago 2026 · Agente n8n · corrección, no pregunta. Y corre prisa relativa**, porque el orden
equivocado ya se lo pasaste al Agente Dashboard.

`docs/fase4-preparacion@81e98d8` · detalle en `docs/fase4/2-atencion-humana.md` §4.2 y §4.bis.

## Lo que dije y es falso

Escribí que **«los `webhookId` no se conocen hasta después de crear el workflow»**, y de ahí deduje dos
cosas que tú recogiste en el runbook y trasladaste al Dashboard:

1. el orden obligado *crear (inactivo) → anotar los tres ids → cablear el Dashboard → activar*;
2. que la ventana de Atención Humana **es una excepción** a «un sistema, una ventana», porque necesita un
   cambio del Dashboard **en medio**.

**La premisa es el error: la URL de producción de un webhook de n8n se construye con su `path`, no con su
`webhookId`.** Verificado contra la instancia viva, no leído:

```
PROD · Retomar Conversacion · nodo «Webhook»
  webhookId  afd2b47d-bd99-4525-93a6-42764b8f56df
  path       proactive-wa-message
  y la URL que Django usa (CLAUDE.md) es  …/webhook/proactive-wa-message
```

El `webhookId` es interno y solo hace de path cuando el `path` está **vacío**. Los tres de Atención
Humana lo tienen con nombre, y están en el export desde el principio.

## Lo que eso cambia, y todo va a favor

- **Las tres URLs se conocen YA**, sin crear nada. Van escritas y completas en mi §4.bis.
- **El Dashboard puede cablearse antes de la ventana**, en paralelo y sin esperar a nadie.
- **La excepción a «un sistema, una ventana» queda retirada.** Siguen haciendo falta cambios en los dos
  sistemas, pero no uno *en medio* del otro, que era lo que la convertía en excepción. La ventana de
  Atención Humana vuelve a ser una ventana normal.

Lo único que sobrevive de aquello: el `webhookId` importa **para mí** —si cambia tras un `PUT` es el Bug
#12— y la URL **solo responde con el workflow activo** (inactivo devuelve 404), así que activar es el
último paso. Nada más.

## Lo que te pedía el estado, ya escrito (§4.bis)

Las tres URLs con su método, y tres cosas que el Dashboard necesita saber y no son URLs:

1. **No hay nada que le pase yo después de la ventana.** Es lo que hace que pueda ir por delante.
2. **Los tres son `authentication: headerAuth`**, así que su única incógnita real **no es de URL, es de
   secreto**: si `Atencion Humana Header Auth PROD` es la contraparte de su
   `N8N_PROACTIVE_WEBHOOK_TOKEN`, el valor ya lo tiene; si es un par nuevo, hay que crear **los dos lados
   con el mismo valor**. Tu cabo, y ahora es lo único que le bloquea.
3. **`responseMode: lastNode` en los tres**, con **cuatro** nodos de respuesta distintos según el
   resultado (`Respond Claim Invalid`, `Respond Dispatch Idempotent`, `Respond Dispatch Logged`,
   `Respond Dispatch No History`). Si su código espera una forma única de respuesta, mejor que lo sepa
   ahora.

## Por qué lo cuento así

Es el patrón que tú resumiste hace un rato —una comprobación más ancha que el criterio grita en falso,
una más estrecha deja pasar— pero en su versión más incómoda: **una deducción correcta sobre una premisa
que no verifiqué.** El razonamiento estaba bien; el hecho de partida, no. Y encima lo verifiqué solo
porque me pediste ser más preciso, no porque dudara — la precisión destapó el error, que es más o menos
la moraleja del día.

## Dos cosas del estado que ya estaban entregadas

Las listas como pendientes mías y llevan un rato hechas, por si el canal no te lo mostró:

- **La migración de `dashboard_outbound_dispatch`** con su árbitro en la misma transacción:
  `Agente-n8n:migrations/prod-paridad/002-…-{aplicar,ENSAYO}.sql`, **14/14** verde
  (`docs/fase4-preparacion@7213b8e`), dos ficheros uno por modo. Escrita y **no aplicada**.
- **Las 0 filas en STG: es la lectura 1**, el camino nunca se ha ejercitado. Cuatro medidas
  independientes en `docs/fase4/002-dashboard-outbound-dispatch.md` §1 — 19/19 nodos alcanzables, 0
  ejecuciones del workflow con el bot y Retomar sí registrando en la misma ventana, y los únicos `DELETE`
  de la tabla son de tests de concurrencia. Lo dije también en la duda del takeover; si no llegó, aquí
  está otra vez con las rutas.
