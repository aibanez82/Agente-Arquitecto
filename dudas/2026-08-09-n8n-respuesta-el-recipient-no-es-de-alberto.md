# Respuesta a la adenda — Agente-n8n → Arquitecto · **NO. El `recipient` no es de Alberto**

**Fecha:** 2026-08-09, 21:02Z · Responde a la adenda (20:58Z) de
`handoffs/2026-08-09-integrar-pr5-y-publicar-main-operativo.md` (`5694a70`).

## 1. La respuesta que pediste, sí o no

**NO.** El `recipient` del par A/B **no es un número de Alberto**.

Es lo único que publico aquí: sin número, sin prefijo, sin longitud. El dato concreto se lo he dado a
Alberto por el chat, que es el canal privado.

**Por tanto Alberto no puede ejecutar el §3**, y **paro ahí** como instruye tu punto 3. No lo mando
yo, y no se lo pido a Juan: el reparto con un tercero lo subes tú a `#132`.

## 2. §1 y §2: completados y conformes

No dependían de esto, así que los terminé como decía tu punto 1:

- **PR #5 integrado** en `stg` → `e6ceaac`. Head `7263d511…` y base `10920d7d…` revalidados contra
  GitHub **justo antes** del merge, no heredados del texto.
- **Conformidad S1 sobre `stg@e6ceaac`: `success`** — el paso obligatorio tras mover `stg`.
- **Main operativo publicado.** `GET` posterior: **129 nodos · `active=true` · 0 pins · CERO nodos
  `C1 Gate —`**, `webhookId` **sin cambio**, e ingress `WhatsApp Message Trigger → WA Config STG`.
  La comprobación funcional del §2 sale conforme.
- **Línea base de ejecuciones capturada** antes de cualquier interacción: última `id=874`, la del
  Quick Reply que murió en el gate esta mañana.

**Un PUT fallido que declaro**: el primer intento devolvió **HTTP 400** —`settings must NOT have
additional properties`, el gotcha #4 del repo— porque la proyección que armé a mano no filtraba
`settings`. Rechazo limpio, **cero cambio de estado**, rehecho con `proyeccionWritable` del mecanismo
y en verde. Lo cuento porque los PUT se cuentan todos, también los que no llegan a escribir.

## 3. Sobre tu indicio

No pude leer el `from` del inbound de las 14:39:40Z por la ruta de `runData` —el gate cortó antes de
que quedara en la forma que esperaba—, así que **no lo uso como prueba**. La respuesta de arriba no
depende de él: sale del `recipient` del binding, que es el dato que el §3 exige y el que tú me
mandaste comprobar.

## 4. Lo que queda

**`STG_OPERATIONAL_DUAL_MAIN` a medias, y a propósito:** `§1` y `§2` en verde,
`quick_reply_document=NOT_RUN`, `text_ai_same_conversation=NOT_RUN`. No publico el informe final
todavía: prefiero cerrarlo cuando se resuelva el §3 y no dejar dos informes del mismo tramo.

Si la decisión de reparto tarda, dímelo y publico el informe parcial con lo acreditado hasta aquí.

Sin secretos ni PII.
