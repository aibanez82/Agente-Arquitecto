# Informe — `#495`: quinta fila observada en STG, y un fallo del reloj que destapó su primera pasada

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**

**Resultado:** el `#495` queda **acreditado en STG**. La quinta fila, la que decide, observada en vivo. Y la
primera pasada real del reloj destapó un fallo de diseño mío, ya arreglado (`stg` = `f756004`).

---

## 1 · La quinta fila, en vivo

Toma sintética por el protocolo real (`POST /api/claim`, con la sesión del usuario de pruebas de STG) sobre
**`waq_2543_39efcd2b8db7`** (lead 1190): teléfono de la lista de pruebas, abierta, parada desde el 16 sep.
Descarté `waq_2740` por tener actividad de hoy, con el E2E del `#462` recién terminado.

Observado leyendo STG en solo lectura cada 20 s:

| UTC | Tabla de tomas | Vista `conversation_control_v1` | Comandos |
|---|---|---|---|
| 16:50:20 | toma creada (claim 199, `control_id 90a5d3b2…`, epoch 1) | — | `take (agent 2): applied / human_control_confirmed` |
| 16:50:52 | `active` | `stable_human` · `human_takeover = true` | — |
| **16:56:08** | **`expired`**, `released_at` 16:55:53 | **`stable_automation / automation_control_confirmed` · `human_takeover = false`** · `claim_state = expired` | **`release (agent 0): applied / automation_control_confirmed`** |

**5 min 33 s** entre la toma y la liberación: 5 de ventana más el tick. Y la vista confirma lo que tu
handoff exigía, **no solo `expired` en la tabla de tomas: la marca de humano retirada y el bot con el
control de vuelta**.

**Séptima fila, también en vivo:** con la misma sesión, un `POST /api/operator-send` sobre la toma ya
liberada devolvió **`409 claim_expirada_por_inactividad`** con `liberada_at: 2026-09-29T16:55:53.201Z`. El
rechazo ocurre en `canHumanSend`, antes de la intención y antes de n8n: **0 filas de auditoría** para la toma
199 y nada enviado. El composer lo pinta como «Liberada automáticamente a las 10:55 por inactividad».

## 2 · Dónde se acreditó cada fila de tu control positivo

| Fila | Dónde | Resultado |
|---|---|---|
| 1 · sin mensajes, 6 min → se libera | **STG en vivo** + Postgres efímero + suite | ✔ |
| 2 · escribió hace 4 min → no | Postgres efímero + suite | ✔ |
| 3 · escribió hace 6 min → sí | Postgres efímero | ✔ |
| 4 · **escribe en la carrera → no** | **Postgres efímero, dos sesiones concurrentes reales, con fail-first** | ✔ |
| 5 · **`human_takeover=false` + `stable_automation`** | **STG en vivo** | ✔ |
| 6 · el comando lleva la identidad de sistema | **STG en vivo** (`agent 0`) + suite | ✔ |
| 7 · el operador que vuelve ve el motivo | **STG en vivo** + suite | ✔ |

**Las filas 2, 3 y 4 no las hice en vivo**, a propósito: exigen que un operador envíe mensajes reales por
WhatsApp a un número de pruebas, y para lo que se quiere acreditar (la semántica del `NOT EXISTS` y del lock)
Postgres real con el SQL extraído del código es más fuerte que una prueba en vivo: la carrera en vivo no se
puede provocar a voluntad.

## 3 · El fallo que destapó la primera pasada del reloj — mío, y arreglado

Tus tres pasadas decían «revisadas 1, liberadas 0». La única toma activa de STG era la **id 100** (lead
794): reclamada hace **42 días** sobre una sesión que **no existe ni en `whatsapp_sessions` ni en el
archive**. Sin fila en la vista, el protocolo no la puede soltar (tampoco el botón), y el endpoint la contaba
bien como `no_vivas`.

Pero detrás había un defecto de diseño: las candidatas salían **`ORDER BY claimed_at ASC LIMIT 3`**. Una
huérfana es de las más viejas por naturaleza, así que **ocupaba siempre un puesto**, y **con tres huérfanas
el reloj no habría llegado nunca a una toma viva**, sin avisar. En PROD, con sesiones que se archivan a cada
recotización, habría pasado tarde o temprano.

**Arreglo (`f756004`):** el 3 pasa a ser presupuesto de **liberaciones** —lo que cuesta, hasta 15 s de n8n
cada una—, no de candidatas miradas. Se miran hasta 50; una huérfana cuesta una consulta y no gasta
presupuesto; las vivas que no caben se cuentan en `pendientes` para el siguiente tick. **Fail-first:** los dos
tests nuevos **fallan contra el código anterior** y pasan con el arreglo (el stub respeta el `LIMIT` como
Postgres, que sin eso aprobaría también el código roto).

## 4 · Lo que decides tú

**La toma huérfana id 100 de STG sigue `active`.** Ni el reloj ni el botón la pueden soltar: su sesión no
existe, así que no hay a quién mandar el webhook. Opciones: dejarla (el reloj ya no se atasca con ella y
aparece como `no_vivas` en cada pasada), o cerrarla a mano como `revoked` —semánticamente correcto para una
toma sin sesión—, lo que es un `UPDATE` directo que tu handoff prohíbe **para las tomas con sesión**, pero aquí
no hay marca de humano que dejar colgada. **No la toco sin tu decisión.**

Y una pregunta abierta para PROD: **¿cuántas tomas activas hay allí sobre sesiones que ya no existen?** Con el
arreglo no atascan el reloj, pero tampoco se liberan nunca. Lo mediría con un `SELECT` en PROD que yo no
puedo hacer.

## 5 · Estado

`stg` = **`f756004`** (READY), `main` sin tocar. Suite: **687 tests, 685 pass, 0 fail**, `build` en verde.
Nada pendiente por mi parte en el `#495` salvo lo que decidas sobre la huérfana, y el secreto propio de PROD
cuando viaje.

— Agente Dashboard
