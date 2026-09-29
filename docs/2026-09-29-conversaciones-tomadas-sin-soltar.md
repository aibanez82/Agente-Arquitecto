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

## Por qué ocurre — medido por el Agente Dashboard, y corrige lo que escribí antes

Yo dejé esto como «la caducidad está diseñada y no implementada, no he medido cuál de las dos».
**Ya está medido, y no es ninguna de las dos: está prohibida a propósito.**

**1 · El `lease_expires_at` en NULL es contractual, no un descuido.** La migración
`2026-08-11-claims-epoch-anti-aba.sql` lo dice al crear la columna:

> «`active` con lease NULL es no expirante y válido por compatibilidad. La columna se crea para que el
> modelo esté completo, pero OJO: el contrato **prohíbe explícitamente** crear leases no nulas mientras no
> exista un reconciliador Dashboard probado. Por eso NO lleva DEFAULT.»

Eso cambia el arreglo: **no se puede «poner caducidad» sin construir antes el reconciliador.** El NULL es
la conformidad con el contrato, no el olvido de nadie.

**2 · No existe ninguna forma de liberar sin que una persona pulse.** El único `UPDATE` a `released`
exige ser el dueño y el mismo `control_id` + `epoch`. El estado `expired` está contemplado en el código
**y nada en el sistema lo produce**. No hay cron. **Una toma activa lo es para siempre.**

**3 · Y no se ven, peor de lo que yo suponía.** La bandeja pinta una insignia con el nombre de quien tomó,
pero **`claimed_at` viaja en los datos y no se dibuja**: una toma de hace once días se ve **exactamente
igual** que una de hace once segundos. Y el agravante que no se me ocurrió preguntar: **esa insignia vive
en la fila del lead y la bandeja filtra por periodo**, así que una toma vieja **puede no tener ni fila
donde mirarse**.

**Las tres se refuerzan entre sí**, y eso es lo que lo hace sistémico en vez de diez incidencias: no
caduca (por contrato), no lo suelta nadie más que el dueño, y no se ve. Cualquiera de las tres sola sería
llevadera.

### Y el `#417` ya estaba arreglado — mi hipótesis apuntaba a código que no existe

Escribí que el botón colgado agravaba esto. **Es falso desde el 21 de septiembre.** El commit `8675a58`
—«Tomar y Liberar ya no se cuelgan ni hay que pulsarlos dos veces»— puso un corte de 25 s sobre el `fetch`
y soltó el botón **antes** de recargar la bandeja. Las dos causas que yo había dejado como candidatas
llevan ocho días desactivadas.

Así que la fila más vieja de esta tabla **coincide** con la sesión del `#417`, pero **no por la causa que
supuse**: cuando se tomó, el botón aún colgaba; hoy ya no, y las tomas se siguen quedando igual.

## Lo que hay que decidir

**1 · Los cuatro que escribieron.** Necesitan respuesta hoy, y dos de ellos son dinero: uno vuelve a
comprar y otra ya pagó. **Quién contesta y por qué canal es decisión de Alberto.**

**2 · Las otras seis.** Se pueden liberar para que el bot retome, o dejarlas si alguien las está
trabajando fuera del sistema. **Hace falta saber cuál de las dos.**

**3 · El arreglo de fondo.** La caducidad del lease **no es la vía**: el contrato la prohíbe hasta que
exista un reconciliador probado, y construir eso es un proyecto, no un parche.

**La medida barata y reversible que propone el Agente Dashboard, y que yo suscribo, es otra: pintar la
antigüedad en la insignia.** Convierte lo invisible en visible sin decidir nada por nadie y sin tocar el
contrato del lease. No libera ninguna conversación — hace que se vea que llevan once días tomadas, que es
justamente lo que hoy no ocurre.

Es mejor que lo que yo habría propuesto, y por un motivo que conviene retener: **ante un problema de
invisibilidad, la primera medida es hacerlo visible, no automatizar una decisión que nadie está tomando.**

## Lo que NO afirmo

**No sé si alguien las está atendiendo por fuera del sistema.** Un operador puede haber seguido la
conversación por teléfono o por otro WhatsApp, y eso no deja rastro aquí. Lo que mido es que **en el
sistema no hay respuesta**, no que el cliente esté desatendido. Esa diferencia la resuelve preguntando al
equipo, no la base de datos.

Agente: Arquitecto-IA-Qualitas
