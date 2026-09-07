# `n8n_outbound_dispatch.request_hash` — qué garantiza y qué NO

> Arquitecto-IA-Qualitas · 6 sep 2026 · medido contra STG y PROD.
> **Escrito porque alguien iba a usarlo como huella del cuerpo del mensaje, y en un carril no lo es.**

## Para qué existe

Cada mensaje al cliente se **reserva** antes de salir, con `n8n_outbound_reserve(...)`, que escribe una fila en `n8n_outbound_dispatch` con un `request_hash`. Ese campo **no es documentación: sostiene dos guardas** (leídas en `pg_proc`, no deducidas):

1. **Reintento del mismo envío** — si vuelve el mismo `dispatch_id` y **coinciden** identidad, epoch, conector y `request_hash`, se devuelve el resultado anterior sin volver a mandar. Si algo difiere, se rechaza con `payload_mismatch`.
2. **Entrega dudosa** — si en la misma `session_id` + `epoch` ya existe una fila con **ese mismo `request_hash`** y `outcome = 'uncertain'`, se prohíbe reintentar (`uncertain_no_retry`). **Es lo que evita mandarle dos veces lo mismo a un cliente cuando no sabemos si le llegó.**

## Qué NO garantiza

**No es, en general, el `sha256` del texto que recibió el cliente.** Depende del carril:

| Carril | Qué firma el `request_hash` |
|---|---|
| Aviso de revisión (`s1.d202.p2.notice.%`) | **el texto enviado**, `sha256` directo |
| Resolución / Direct (`d156.p2.….application.reply`) | **un compuesto** `n8n_jcs` con `offer_id`, `action`, `response_hash` y **`copy` = `response_copy` de Django** |

En el carril Direct, desde el **6 sep 2026**, ese `copy` **ya no es lo que sale**: el escritor propio (`Build Direct Discount Notice Copy`) decide el texto **después** de la reserva. Medido ese día sobre un envío real de STG: `request_hash = 9e486897…`, mientras `sha256` del texto enviado es `f8a2ac6f…` y el de la frase de Django `69d83e9d…`. **No coincide con ninguno de los dos, porque es compuesto.**

**Causa:** la huella se calcula al RESERVAR y el texto se decide al ENVIAR. Lo introdujo el Arquitecto con el arreglo del `#288`.

## Consecuencias, dimensionadas

**Para quien lee el ledger (Dashboard, auditorías):** en el carril Direct, `request_hash` **no sirve para detectar que el texto enviado difiere del guardado**. Usarlo como huella del cuerpo da un falso negativo silencioso.

**Para la guarda 2:** existe un riesgo estrecho de que bloquee un mensaje **distinto** creyéndolo el mismo, porque comparten la frase de Django — plausible justo por el `#248`, que hace que Django repita una frase en varios momentos. Requiere **las tres a la vez**: misma sesión y epoch, un envío previo en `uncertain`, y la misma frase de Django. **No se ha observado ninguna vez.**

## Por qué no se arregla hoy

Se evaluaron dos arreglos y los dos se descartaron con motivo:

- **Quitar `copy` del compuesto** — lo propuso el Arquitecto y **lo retiró él mismo al leer para qué se usaba el campo**: debilitaría la guarda 2, que es la que impide reenviar un mensaje que quizá ya llegó.
- **Que la huella firme lo enviado** — exige decidir el texto **antes** de reservar, es decir mover el escritor a la reserva. Eso es la iniciativa «D», descartada el 6 sep por el criterio `#179`: **no hay defecto medido que la justifique**.

Queda como **limitación conocida y acotada**, no como deuda abierta. Si alguna vez se observa un `uncertain_no_retry` bloqueando un mensaje legítimo, eso **sí** es el defecto medido que reabre la conversación.

## Regla práctica

- Para «¿se envió algo y cuándo?» → `dispatch_id`, `outcome`, `settled_at`. **Fiables en todos los carriles.**
- Para «¿qué decía?» → **el ledger no lo guarda.** Ni el `request_hash` lo sustituye.
- Para «¿coincide lo enviado con lo recordado?» → comparar el texto de `n8n_chat_histories` con la fuente del nodo emisor. **No con el hash.**
