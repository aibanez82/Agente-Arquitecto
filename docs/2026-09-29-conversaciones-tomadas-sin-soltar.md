# Diez conversaciones tomadas y nunca soltadas — con el bot mudo

> **Medido el 29 sep 2026** contra `dashboard_conversation_claims`, `dashboard_users`,
> `whatsapp_sessions` y `n8n_chat_histories` de **PROD**.
> Encontrado buscando otra cosa: el diagnóstico del `#417` («Tomar conversación» se queda en «Tomando…»).

## El hecho

**Diez conversaciones están en estado `active` con `released_at` nulo, y `lease_expires_at` está vacío en
las diez.** Las diez tienen `human_takeover = true`, así que **el bot no puede responder en ninguna**.

Sin caducidad de lease, **eso no se deshace solo: solo lo suelta una persona.**

## ⚠️ Lo urgente: cuatro clientes escribieron y nadie contestó

En estas cuatro, **el último mensaje de la conversación es del cliente**. El bot está mudo por la toma y
la persona que tomó no volvió.

| Lead | Cliente / vehículo | Operador | Días | **Lo que escribió y sigue sin respuesta** |
|---|---|---|---|---|
| **2149** | NISSAN X-TRAIL 2017 · `8112390973` | **Rafael Rebollar** | **8** | **«Quiero cancelar»** |
| **2172** | TOYOTA HIACE 2019 · `4425499550` | **Montserrat** | **7** | «Me podrás mandar la cotización por PDF por favor» |
| **2208** | **Elizeth Barrios** · RENAULT STEPWAY 2012 · `9848779227` | **Montserrat** | **5** | «si me llegó al correo» |
| **2255** | TOYOTA COROLLA 2016 · `4881018177` | **Montserrat** | **1** | **«Retomo mi cotización»** |

**El 2255 es el más caro de los cuatro.** Es uno de los clientes que el 28 se quedó sin póliza porque
producción no podía emitir. **Volvió por su cuenta diciendo que retoma su cotización** — y se encontró
silencio, porque su conversación estaba tomada y el bot no puede hablar.

**El 2208 es Elizeth**, la del Renault: **ya pagó** (póliza `7620103198`, `PAGADO`). Solo estaba
confirmando que le llegó la documentación. Cinco días sin que nadie cierre el círculo con una clienta que
ya compró.

**Y el 2149 pidió cancelar hace ocho días.** Sea lo que sea que decidamos, ocho días de silencio ante una
cancelación no es una decisión: es un olvido.

## Las diez, completas

| # | Lead | Cot. | Operador | Tomada (CDMX) | Días | Fase | Cliente / vehículo | Teléfono | Correo | Póliza |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2125 | 3577 | **Alberto Ibáñez** | 18 sep 15:19 | **11** | `payment_pending` | RAFAEL REBOLLAR · NISSAN MARCH 2018 | `5518859302` | `rarefe@hotmail.com` | `7620102689` · PENDIENTE |
| 2 | 2149 | 3603 | **Rafael Rebollar** | 21 sep 13:37 | 8 | `greeting` | NISSAN X-TRAIL 2017 | `8112390973` | `elopez@multinfmty.com` | — |
| 3 | 2172 | 3626 | Montserrat | 22 sep 13:00 | 7 | `greeting` | TOYOTA HIACE 2019 | `4425499550` | `migueeloop3@gmail.com` | — |
| 4 | 2222 | 3676 | Montserrat | 24 sep 12:38 | 5 | `greeting` | MAZDA 3 2025 | `8180109853` | `rodrich30.rf@gmail.com` | — |
| 5 | 2225 | 3679 | Montserrat | 24 sep 13:31 | 5 | `greeting` | GWM HAVAL H6 2026 | `3141047989` | `cruzgibarra@hotmail.com` | — |
| 6 | 2208 | 3662 | Montserrat | 24 sep 18:06 | 5 | `payment_pending` | **Elizeth Barrios** · RENAULT STEPWAY 2012 | `9848779227` | `elizeth.barrios@hyattvividresorts.com` | `7620103198` · **PAGADO** |
| 7 | 2239 | 3693 | Montserrat | 25 sep 13:13 | 4 | `greeting` | JEEP WRANGLER 2008 | `8311203771` | `dyh2898@gmail.com` | — |
| 8 | 2244 | 3698 | Montserrat | 28 sep 12:06 | 1 | `greeting` | VOLKSWAGEN VENTO 2016 | `5515123770` | `jeniwhite779@gmail.com` | — |
| 9 | 2246 | 3700 | Montserrat | 28 sep 15:29 | 1 | `summary_confirmation` | CHEVROLET BEAT 2018 | `8781347480` | `76cesargzz@gmail.com` | — |
| 10 | 2255 | 3709 | Montserrat | 28 sep 18:06 | 1 | `summary_confirmation` | TOYOTA COROLLA 2016 | `4881018177` | `cruzrojasjosefernando@gmail.com` | — |

**Reparto por operador:** Montserrat **8**, Rafael Rebollar **1**, Alberto **1**.

**Esto no es un reproche a nadie.** Montserrat tiene ocho porque es quien más atiende, y la fecha de alta
de su usuario es el **18 de septiembre** — es decir, **su primera toma es de sus primeros días**. Si el
sistema no avisa de que una conversación sigue tomada, **nadie puede acordarse de soltarla**: el fallo es
que no existe ni caducidad ni recordatorio, no que a alguien se le olvidara.

## Por qué ocurre

`lease_expires_at` **existe como columna y está vacía en las diez**. O sea: **la caducidad está diseñada
y no implementada** — o se dejó de rellenar en algún momento. No he medido cuál de las dos.

Sin ella, y sin ninguna pantalla que liste «tomadas hace N días», la única forma de que una conversación
vuelva al bot es que la persona que la tomó se acuerde.

Y hay un agravante que conecta con el `#417`: **el botón «Tomar conversación» se queda en «Tomando…» para
siempre**, así que el operador **cree que no la tomó**. La primera fila de esta tabla —la del 18 de
septiembre, 11 días— **es la sesión de ese issue**. Se toma, parece que no, y nadie la suelta.

## Lo que hay que decidir

**1 · Los cuatro que escribieron.** Necesitan respuesta hoy, y dos de ellos son dinero: uno vuelve a
comprar y otra ya pagó. **Quién contesta y por qué canal es decisión de Alberto.**

**2 · Las otras seis.** Se pueden liberar para que el bot retome, o dejarlas si alguien las está
trabajando fuera del sistema. **Hace falta saber cuál de las dos.**

**3 · El arreglo de fondo:** caducidad del lease, o una pantalla que las muestre, o las dos. Encargado el
diagnóstico al Agente Dashboard — **sin tocar nada** — junto con el `#417`, porque son el mismo hilo.

## Lo que NO afirmo

**No sé si alguien las está atendiendo por fuera del sistema.** Un operador puede haber seguido la
conversación por teléfono o por otro WhatsApp, y eso no deja rastro aquí. Lo que mido es que **en el
sistema no hay respuesta**, no que el cliente esté desatendido. Esa diferencia la resuelve preguntando al
equipo, no la base de datos.

Agente: Arquitecto-IA-Qualitas
