# E2E de descuentos en STG — llega hasta Django y ahí se para: **dos procesos de fondo suyos no corren**

**14 ago 2026 (noche CDMX) · Agente n8n.** Lo que sigue está medido contra la instancia y la base
de STG, no leído. Todo el carril que es mío está probado de punta a punta; el E2E se detiene en dos
componentes de Django que no arrancan. Además hay **tres decisiones que no son mías** al final.

Sigo con lo que no depende de esto. Nada de lo de aquí toca PROD.

---

## 1. Hasta dónde llegó el E2E, tramo a tramo

Prueba real por WhatsApp de Alberto, sesión `waq_2014_bdcb8b296625` (lead 661, cotización 2014).
Horas en **UTC**, que es como están las ejecuciones.

| tramo | estado | evidencia |
|---|---|---|
| Objeción de precio → fase 2 elegible | **probado** | ej. `1478` |
| Catálogo Django → clasificación `PRICE_OBJECTION` | **probado** | ej. `1478`, `1539` |
| Disponibilidad → oferta creada en Django | **probado** | oferta `dc9c6035…`, programa `POR_PRECIO_ALTO_PARA_IA_30` |
| Envío de la oferta con dos botones, por el fence | **probado** | `n8n_outbound_dispatch`: `outcome=sent`, `attempts=1`, con `provider_message_id` |
| Pulsar «Aceptar» → resolución con Django | **probado** | ej. `1527`: `application_id 1`, `state queued`, `next_action worker` |
| **Django procesa la solicitud** | **BLOQUEADO** | §2 |
| Documento → PDF al cliente | sin probar | depende del anterior |
| Recordatorio (`quote_sent` attempt 2 = `discount_offer`) | **BLOQUEADO** | §3 |

Los cuatro fallos que aparecieron por el camino ya están arreglados, desplegados en STG y
commiteados (§5). Ninguno de ellos es la causa de lo que sigue.

## 2. Bloqueo 1 — el worker de descuentos de Django no ha reclamado nunca la solicitud

La fila de Django, en la propia base de STG:

```
public.qualitas_discountapplication · id 1
  state                     queued
  stage                     validation
  slot_number 1 · slot_status reserved
  worker_claim_token        NULL
  worker_claimed_at         NULL
  worker_fence              0
  worker_lease_expires_at   NULL
  worker_retry_not_before   NULL
  created_at / updated_at   2026-08-15 03:36:29 UTC   <- sin tocar desde que se creó
```

`updated_at` idéntico a `created_at` y las cinco columnas `worker_*` vacías: **nadie del lado de
Django la ha tomado**. No es que fallara al procesarla; es que no ha empezado.

El worker de n8n hace su parte cada minuto y sin un solo error (barrido `1543`):

```
Discount Application Poll Claim      -> puede_poll: true, intento 2
Poll Django Discount Application     -> Django responde: state queued, stage validation, result null
Validate Discount Application Status -> status_valid: true
Persist Discount Application Status  -> programado: true (reprograma el siguiente intento)
IF Fetch Private Document?           -> rama falsa: no hay documento porque no hay resultado
```

n8n pregunta bien y Django contesta «todavía no». **Aviso operativo:** el worker reintenta 8 veces
con espera creciente y luego marca la solicitud para reconciliación manual. Si Django despierta
después de eso, la solicitud 1 **no se retoma sola**.

## 3. Bloqueo 2 — el encolador de recordatorios tampoco produce

Independiente del anterior, mismo patrón. En STG:

| | |
|---|---|
| Último `qualitas_leadcheckpointfollowupattempt` de cualquier tipo | **24 jul**, cotización 1856 |
| Intentos para la cotización 2014 | **cero** |
| Llamadas al webhook `proactive-wa-message` de n8n | **cero desde el 10 ago** |
| `n8n_checkpoint_outbound_decision` | **0 filas** |

Y el caso era candidato de libro: cotización creada el 14 ago 19:08 UTC, política `quote_sent`
attempt 1 **activa** con `delay_mins = 1`, horas sin avanzar. El lado n8n está listo y esperando:
`Retomar Conversacion` activo, webhook `POST` con `headerAuth`.

Esto importa para #156 más allá del recordatorio: la política **`quote_sent` attempt 2 tiene
`behavior = discount_offer`**, así que es *también* un disparador de ofertas. Mientras no encole,
esa mitad del módulo no se puede probar en STG por ninguna vía.

## 4. Tres decisiones que no son mías

**4.1 — Una resolución a medias deja al cliente sin salida y quema un hueco.** Cuando
`Persist Django Resolution` falló (§5.4), la fila de n8n se quedó en `django_outcome=reserved` y la
de Django en `queued`. Consecuencias medidas, no hipotéticas: el cliente no recibió respuesta;
volver a pulsar el botón es **terminal por diseño** y no hace nada nunca; Django bajó
`remaining_slots` de 3 a 2 y **negó ofertas nuevas** con `pending_application`; y el worker de n8n
no veía la solicitud porque la anotación que la descubre es justo la que se perdió. Los dos lados
contando historias distintas, y ninguno capaz de salir solo.

En STG lo reparé a mano — llamando a `n8n_discount_resolution_settle` con los valores exactos que
Django devolvió en la ejecución `1527`, no con un `UPDATE`: es la llamada que el bug se comió,
repetida. Lo digo explícitamente porque es una escritura mía sobre datos de STG.

**Lo que pregunto:** en producción esto deja a un cliente que aceptó un descuento sin respuesta,
sin reintento y con un hueco consumido. ¿Hace falta una reconciliación entre los dos ledgers, y de
quién es? No la construyo por mi cuenta: toca el contrato.

**4.2 — Con `pending_application`, el bot se queda mudo.** Ejecución `1539`: Django devuelve
`status: pending` / `pending_application`, y el turno termina en `Discount Reply Terminal` con
`crear_oferta: false`, `continuar_normal: false`, `outbound_count: 0`. El cliente escribió «Es muy
cara» y **no recibió absolutamente nada**. Entiendo que sea deliberado —no duplicar mensajes
mientras hay algo en curso—, pero desde fuera es el bot ignorándote. ¿Es el comportamiento que se
quiere, o falta un copy?

**4.3 — El clasificador con justificación pegada sigue cayendo a `no_match`.** El modelo devuelve
el JSON dentro de una valla markdown; eso ya lo trato (§5.3). Pero cuando además añade
«**Justificación:** …» **fuera** de la valla, sigue siendo `no_match`. Me he quedado en la lectura
estricta del contrato («cualquier texto libre → `no_match`») en vez de relajarla por mi cuenta.
Ocurrió de verdad en la ejecución `1434`, donde acertó de casualidad porque la respuesta era
`no_match` de todos modos. Como `no_match` sólo significa «sigue la conversación normal», el coste
de aceptar la justificación es bajo y el de rechazarla es perder clasificaciones correctas en
silencio. ¿Se relaja? Es una línea.

## 5. Lo que ya está hecho, desplegado en STG y commiteado

Rama `stg` de `aibanez82/Agente-n8n`, punta **`1b40090`**. Cuatro fallos, los cuatro con la misma
forma de fondo: **una verdad viviendo en dos sitios y corregida en uno**.

1. **`migrations/156/015`** — la regla de la `014` aplicada a las tres funciones que se quedaron
   fuera (`n8n_discount_phase2_claim`, `n8n_discount_resolution_claim`, las cinco revalidaciones de
   `n8n_discount_conversation_activate`) más el nodo `IF Discount Phase 2 Eligible?`. Sin esto **la
   fase 2 no se había podido disparar ni una sola vez** desde que se desplegó: toda sesión resuelta
   se marca `active` en su propio turno y la condición exigía `open`. Generada por
   `scripts/156/build-015.js`; el test exige que cambien exactamente 6+1+1 líneas.
2. **`migrations/156/016`** — una oferta nacida en la fase 2 **no se podía aceptar nunca**:
   `n8n_discount_resolution_claim` verificaba el envío mirando sólo el ledger del carril de
   recordatorios, y las ofertas de fase 2 se anotan en otro. Vista `n8n_discount_offer_sent_v1` que
   publica los dos carriles; la unicidad no se ensancha (una oferta por los dos sigue dando
   `oferta_ambigua`). El prefijo del dispatch pasa a una función usada por ambos lados.
3. **Parser del clasificador** — devolvía `no_match` sobre clasificaciones **correctas** porque el
   modelo envuelve el JSON en ```` ```json ````. Ninguno de los tests que había lo cubría: todos
   alimentaban JSON pelado, que no es lo que el modelo produce.
4. **Parámetros anulables** — n8n serializa un `null` de expresión como la **cadena `"null"`**, que
   no es NULL para plpgsql. Rompió el worker (dos claims), `Persist Django Resolution` (§4.1) y
   habría roto `Settle Discount Availability`. Envueltos con `NULLIF(NULLIF($n,''),'null')`, el
   idioma en una constante del builder, y un test que fija qué posiciones son anulables.

Suites: **#156 257/258** — el único fallo es `M0`, que compara el SHA del checkout local del
Dashboard y está desfasado en esta máquina, idéntico antes y después de mis cambios. **S1 300/312**,
los 12 fail-first `ROJO en vigente` de siempre.

**Nota de entorno que cuesta una hora si no se sabe:** la suite #156 necesita
`ISSUE156_DASHBOARD_REPO` e `ISSUE156_DJANGO_REPO`. Sin ellas **34 pruebas fallan por entorno** y
parecen fallos reales. El valor por defecto apunta a `Dashboard_seguroautoqualitas`, que en esta
máquina se llama `Dashboard_SeguroAuto`.

## 6. Qué me desbloquea cada respuesta

- **§2 y §3** — que alguien arranque los dos procesos de Django en STG. Con eso termino el E2E
  (documento → PDF) sin tocar nada más. Es lo único que falta para cerrar el carril entero.
- **§4.1** — si la reconciliación es necesaria y me toca, la diseño; si es de Django, sólo aporto
  la evidencia.
- **§4.2 y §4.3** — un sí o un no. Los dos son cambios de una línea, pero son de contrato.

Mientras tanto no me bloqueo: el resto de #156 en STG está desplegado y verde.
