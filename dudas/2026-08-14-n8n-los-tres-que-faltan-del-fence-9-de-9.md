# Duda — los **tres puntos que faltan** para cerrar el fence 9/9 de STG

**14 ago 2026 · Agente n8n · tres decisiones, ninguna de código.**

**Qué ejecuto:** `handoffs/2026-08-14-hyl-wai-156-fence-los-9-de-stg.md` más la autorización de
`authority_epoch`. **Seis de los nueve están hechos** (`Agente-n8n@stg` `a8a5213`, entrega en
`docs/156/entrega-fence-6-de-9.md`): los seis conectores del bot principal ya pasan por
`n8n_outbound_reserve`, con el epoch congelado en `Resolve Session`, y `preservacion` en 34/34.

Sigo con todo lo que no depende de esto — el test de ejecución del fallo cerrado es lo siguiente.
Las tres preguntas de abajo son lo único que impide llegar a 9/9.

---

## Duda 1 — `Atencion Humana` / `Send Human Agent Message`: ¿cuenta ya como fenceado?

**El hecho.** Ese workflow **no es un conector desnudo**: ya trae su propia maquinaria de reserva —
`Reserve Or Retry Dispatch`, `Lookup Existing Dispatch`, `Persist Dispatch Result`, más
`Validate Claim And Resolve Phone`—. Es el **camino del operador**, y su fence es el otro ledger,
`dashboard_outbound_dispatch`, cuyo `control_id` es `NOT NULL` justo porque nació para mensajes que
manda un humano teniendo el claim.

La cabecera de `migrations/156/003-outbound-fence.sql` ya lo dice:

> «el camino del operador NO queda sin fence: su unicidad durable por `idempotency_key` sigue en
> pie», y unificar los dos ledgers es **un paso de rollout**, no alcance de #156.

**Las dos respuestas posibles:**

| respuesta | qué desbloquea | coste |
|---|---|---|
| **(a) Cuenta como fenceado**, con su ledger propio, y el 9/9 se acredita declarando los dos ledgers | cierro este punto **hoy**, sin tocar el workflow | queda el estado de transición de dos ledgers, ya declarado por escrito |
| **(b) El 9/9 exige el ledger común** | tengo que migrar `Atencion Humana` a `n8n_outbound_reserve` | es rollout: mapear `idempotency_key → dispatch_id` y convivir con filas vivas. **No es trabajo de este handoff** y lo pediría como uno propio |

**Mi recomendación: (a).** Fencearlo dos veces no lo hace más seguro, y migrar un ledger vivo dentro
de un trabajo cuyo objeto es otro es justo lo que esta semana ha salido caro.

## Duda 2 — Payment y Retomar: pido autorización para **un nodo Postgres nuevo** en cada uno

**El hecho.** Los dos tienen identidad (`session_id`, `lead_id`, `quotation_id`/`cotizacion_id`,
`conversation_id`). **Ninguno tiene `authority_epoch`** — cero menciones en ambos exports vivos.

Y el permiso que ya tengo no alcanza, y creo que deliberadamente: fue *«solo la columna, nada más del
`SELECT` ni del nodo»* sobre **`Resolve Session`**. En estos dos **no existe ningún `SELECT` temprano
al que añadirle una columna**:

- **Payment Confirmation_stg**: un único nodo Postgres, ` Mark Session Completed`, y está **al
  final** del flujo. Su guard de S1 es un Code node.
- **Retomar Conversacion_stg**, carril Dashboard: `Normalize & Validate → C1 Gate — Send message →
  Send message`. **Ni una lectura de base** por el camino.

Congelar el epoch ahí exige **un nodo Postgres nuevo al principio del flujo** de dos workflows vivos.
Es más que estirar el permiso que tengo, así que lo pregunto en vez de asumirlo.

**Las tres respuestas posibles:**

| respuesta | qué desbloquea | coste |
|---|---|---|
| **(a) Autorizado el nodo nuevo** (solo lee `conversation_control_v1`, no escribe) | fenceo los dos **con epoch real**, igual que Main | dos nodos nuevos en camino caliente, una consulta más por ejecución |
| **(b) Fencear sin epoch congelado**, leyéndolo en el momento | fenceo los dos hoy, sin nodos nuevos | la comprobación de epoch **es decorativa**: compara el estado consigo mismo y coincide siempre. Si se elige, quiero que quede escrito así y no como «fenceado» |
| **(c) Dejarlos fuera del 9/9 por ahora** | nada que hacer | el gate no se cumple |

**Mi recomendación: (a).** Es la única que da al fence de esos dos puntos el valor que tiene en Main.
La **(b)** no la descarto —el resto del fence (identidad, control, sesión elegible) sí protegería—,
pero entonces el 9/9 incluiría dos puntos con media comprobación, y eso hay que decirlo en #156.

## Duda 3 — Los 7 conectores sin salida de error: ¿confirmas que el hueco son **duplicados**?

No es una petición de trabajo: ya decidiste **declarar y no arreglar**, y me parece bien. Es para que
la categoría quede correcta en #156, porque tu lectura y la mía difieren en el daño.

**Confirmo tu lectura de fondo:** verifiqué en `003` que el único outcome terminal para la terna
`(session_id, epoch, request_hash)` es **`uncertain`**. Una reserva huérfana en `reserved` **no
bloquea envíos futuros**. Con una condición que es de diseño, no del fence: se sostiene **solo
porque cada turno trae su propio `dispatch_id`**, cosa que he garantizado metiendo el `wamid` del
turno dentro del id. Si alguien lo simplificara a algo estable entre turnos, una huérfana bloquearía
ese conector para siempre.

**Donde difiero:** el hueco no es «basura y evidencia falseada». Es **el duplicado**. `uncertain`
existe precisamente para hacer terminal el caso *«puede que saliera y no lo sabemos»*. En los 7
conectores sin salida de error ese estado **no se puede alcanzar**, así que:

> si un envío llega a Meta y la ejecución muere antes de liquidar, un turno posterior con el mismo
> texto, misma sesión y mismo epoch produce el **mismo `request_hash`**, pasa el fence con un
> `dispatch_id` nuevo y **vuelve a enviar**.

Un mensaje repetido al cliente. Plausible en los de texto fijo (`Send Generic Error Message`,
`Send Not Available Message`), donde el mismo texto se repite con facilidad.

**No lo subo a bloqueante por mi cuenta** — el daño es un duplicado, no un envío indebido, y hacen
falta tres coincidencias. Pero si con este matiz cambia de categoría en tu lista de higiene, es
decisión tuya y prefiero que la tomes con el dato correcto.

---

## Resumen de qué desbloquea cada respuesta

| duda | si respondes lo que recomiendo | tiempo hasta 9/9 |
|---|---|---|
| 1 | (a) cuenta como fenceado | cierra en el acto |
| 2 | (a) autorizas el nodo nuevo | los dos fenceados en el mismo movimiento |
| 3 | no desbloquea nada — solo corrige la categoría | — |

Con **1(a) + 2(a)** entrego el 9/9 completo, el test de fallo cerrado y el inventario actualizado en
una sola entrega. Con **2(b)** entrego lo mismo pero con dos puntos marcados como «fence sin epoch»,
y eso tendría que ir dicho en #156, no escondido en la cifra.
