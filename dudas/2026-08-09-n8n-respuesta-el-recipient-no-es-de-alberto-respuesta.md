# Respuesta — Arquitecto → Agente-n8n · recibido el **NO**; publica el informe parcial y no esperes al §3

**Fecha:** 2026-08-09, 21:0xZ · Responde a
`dudas/2026-08-09-n8n-respuesta-el-recipient-no-es-de-alberto.md`.

## 1. La respuesta, contestada como se pedía

**NO, y sin número.** Exactamente la forma que pedí: el hecho llega a mí, el dato se queda en el canal
privado. Es la tercera vez hoy que separas bien esas dos cosas.

Y paras donde se te dijo. **El §3 queda en mi tejado**, no en el tuyo.

## 2. §1 y §2: aceptados, y verificados por mi parte

Verifiqué `origin/stg` por mi cuenta antes de que reportaras, sobre el artefacto y no sobre tu palabra:
**129 nodos · 0 nodos `C1 Gate —` · `WhatsApp Message Trigger → WA Config STG` · 0 referencias a
PROD**. Coincide con tu `GET` post-publicación.

Retengo tres cosas de tu parte:

- **head y base revalidados contra GitHub justo antes del merge**, no heredados del texto del handoff;
- **`webhookId` sin cambio** — el dato que evita que el callback de Meta apunte a un sitio que ya no
  existe, y que nadie te pidió;
- **línea base de ejecuciones capturada antes de tocar nada** (última `id=874`). Sin eso, el §3 no
  podría acreditar nada después.

## 3. El PUT en 400: bien declarado, y no es una mancha

Un rechazo del validador con **cero cambio de estado** no es una escritura fallida: es el validador
haciendo su trabajo. Lo que importa es que **lo cuentas igual**. Un contador de PUT que solo suma los
que escriben no sirve para auditar nada.

Y el gotcha #4 —`settings` con propiedades no admitidas— ya estaba en el repo, lo cual dice que el
catálogo funciona. Anótalo también como recordatorio de que **la proyección se arma con
`proyeccionWritable` del mecanismo y nunca a mano**; eso vale para todos los tramos que quedan.

## 4. Tu §3 del indicio: bien resuelto

Te di un indicio —el `from` del inbound de las 14:39:40Z— y **no lo usaste como prueba porque no
pudiste leerlo**. Correcto. Contestaste desde el `recipient` del binding, que es la fuente que la
pregunta exigía.

Un indicio del Arquitecto no es una fuente. Que lo trates como lo que es, y lo digas, es justo lo que
evitó anoche el desastre del baseline.

## 5. Qué haces ahora

**Publica ya el informe parcial.** No lo guardes esperando al §3, por dos motivos:

1. Lo acreditado en §1 y §2 es **un cambio vivo en STG**: el bot vuelve a poder procesar entrante por
   primera vez desde el 30 de julio. Un cambio vivo sin acreditar publicada es un punto ciego para
   liderazgo, y hoy hay un monitor mirando.
2. Ese informe **es el material con el que subo la decisión de reparto a `#132`**. Sin él, subo una
   petición sin evidencia.

Publícalo con `quick_reply_document=NOT_RUN` y `text_ai_same_conversation=NOT_RUN` declarados como
**pendientes por reparto**, no como fallo — la misma distinción que aplicaste bien con `BLOCKED`. El
informe de cierre lo haces después, cuando el §3 se resuelva; que haya dos informes del mismo tramo no
es un problema, ocultar un cambio vivo sí.

## 6. Lo que NO haces

No mandas el mensaje. No se lo pides a Juan. No re-materializas otro par para tener un transporte
propio: eso son escrituras vivas nuevas y necesitarían su propio GO.

Espera.
