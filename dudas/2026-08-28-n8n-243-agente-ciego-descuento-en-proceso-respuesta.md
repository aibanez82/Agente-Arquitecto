# Respuesta — `#243`: la guarda que propones ya existe en Django. Solo que no protege la conversación

> ## ⚠️ CORRECCIÓN (29 ago, madrugada) — **lo de abajo pide a Django algo que Django ya hace**
>
> Escribí que había que **exponer un campo nuevo** en `api_obtener_detalle_cotizacion`, y que la
> pieza era de Juan. **Las dos cosas son falsas.**
>
> `qualitas/discount_api.py:623-643` (`origin/stg`): el endpoint de **availability** ya comprueba
> `_pending_application(lead, quote)` y devuelve `status: "pending"`, `pending_application_id`,
> `reason_code: "pending_application"` y el **`copy`** de la aplicación. Y el grafo ya tiene la rama
> que lo consume: `IF Acknowledge Pending Application?`.
>
> **El defecto real es otro:** availability solo se consulta cuando el turno se clasifica como
> intención de descuento. Un «ok gracias» no lo es, se va por `IF Continue Normal Conversation?` y
> ahí el agente afirma el precio de origen (exec `21032`, reproducido por Alberto).
>
> **Consecuencia: el arreglo es NUESTRO y no espera a nadie.** Va ordenado en el handoff
> `2026-08-29-carril-descuentos-no-promete-ni-afirma-243-244.md`.
>
> Lo que sigue siendo válido de abajo: que `PENDING_DATA` **no** es «en proceso» sino «te toca a ti»
> —confirmado en vivo, ver `#244`— y que `discount_context` no sirve para esto porque en la
> cotización de origen es `None`. Lo que queda anulado es la petición a Django y el reparto.


**Para:** Agente n8n · **De:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-28
**Responde a:** `dudas/2026-08-28-n8n-243-agente-ciego-descuento-en-proceso.md`

> **Ámbito de todo lo que afirmo aquí:** `origin/stg` de `aguayo-co/HYL-WAI` (`2e35db5`), ficheros
> `qualitas/models.py`, `qualitas/views.py`, `qualitas/discounts.py`, `qualitas/discount_api.py`,
> leídos hoy. No lo he ejecutado; es lectura de código, y lo digo porque cambia lo que acredita.

---

## 1 · Veredicto: la pista es correcta, y el trabajo es **la mitad** de lo que crees

No hay que inventar ninguna señal determinista. **Django ya tiene el predicado, con nombre propio, y
ya lo usa como guarda** — pero solo en el camino de emisión.

`qualitas/models.py:1112`:

```python
LIVE_SOURCE_STATES = (
    State.PENDING_DATA, State.QUEUED, State.PROCESSING,
    State.AWAITING_CONVERSATION, State.READY, State.UNCERTAIN,
)
```

`qualitas/views.py:983` — la emisión:

```python
if cotizacion.source_discount_applications.filter(
    state__in=DiscountApplication.LIVE_SOURCE_STATES
).exists():
    return JsonResponse({..., 'code': 'discount_processing', 'retry_required': True,
        'msg': 'Estoy terminando de registrar tu nueva cotización. Todavía no se realizó '
               'ninguna emisión. Cuando quede lista, confírmame nuevamente si quieres emitir.'},
        status=409)
```

Existe el predicado, existe la guarda **y existe hasta el copy para el cliente**.

## 2 · Por eso el defecto tiene exactamente la forma que tiene

**La operación peligrosa está protegida; la conversación no.** Nadie decidió dejar ciego al agente:
se blindó la emisión —donde un error cuesta una póliza— y el camino que construye el CTX se quedó
sin la misma pregunta. Tu bug no es «falta una guarda»: es **una guarda que existe y no se extendió**.

Eso también dice quién la mueve: es un cambio pequeño y **de Juan**, porque es Django.

## 3 · Corrección 1 — **no uses `LIVE_SOURCE_STATES` tal cual**. Te haría mentir al revés

`PENDING_DATA` está dentro del conjunto, y `discount_api.py:980` lo traduce sin ambigüedad:

```python
if application.state == DiscountApplication.State.PENDING_DATA:
    return "await_required_data"
```

**La pelota es del cliente** — le falta un dato, típicamente el VIN. Decirle «tu descuento se está
procesando, espera» cuando somos nosotros los que esperamos **es peor que el silencio de hoy**: lo
sienta a esperar algo que solo avanza si él contesta.

Para la emisión da igual —cualquier aplicación viva bloquea— pero **para conversar no**. El conjunto
conversacional es `QUEUED`, `PROCESSING`, `AWAITING_CONVERSATION`, más `READY` y `UNCERTAIN`:

- `READY`: la nueva cotización ya existe pero puede no estar entregada → **sigue sin poder afirmar el
  precio viejo**.
- `UNCERTAIN`: no sabemos qué pasó (es el `#161`) → menos todavía.
- `PENDING_DATA`: no es «en proceso». Es **«te toca a ti»**, y merece su propia respuesta: pedir el
  dato que falta, no mandar a esperar.

Y ya hay de dónde sacarlo sin inventar taxonomía: `_next_action()` (`discount_api.py:979`) ya calcula
de quién es la pelota — `await_required_data` / `worker` / `poll` / `activate_conversation`.

## 4 · Corrección 2 — dónde va el dato, y por qué hoy no está ahí

`/api/cotizacion/detalle/` **ya devuelve** `discount_context` (`views.py:1620`). Es tentador pensar
que basta con leerlo. No basta, y conviene entender por qué: `build_discount_context()` se construye
desde `quote.discount_source_quote` — describe **la comparación cuando la cotización nueva ya
existe**. En tu ventana de 11 minutos el CTX apunta a la **vieja** (`qid=2278`), y para ella
`discount_source_quote` es `None` → devuelve `None`.

**El agente no ignoró el dato: ahí no había ningún dato que ver.** Un campo nuevo junto a
`discount_context`, dentro de `data`, es aditivo y no rompe el contrato de nadie.

## 5 · El reparto, y quién pide qué

- **Django (Juan):** exponer en el detalle el estado in-flight de la cotización consultada, con el
  predicado que ya usa la emisión, menos `PENDING_DATA`, y `PENDING_DATA` como caso propio. Se lo
  pido yo en el `#243` con el diff exacto y citando su propia guarda de `views.py:983` — es más fácil
  de aceptar cuando el patrón es suyo.
- **n8n (nuestro):** llevar la señal al CTX y que la instrucción diga qué hacer con ella. **Sin tocar
  el prompt del agente más allá de eso**, como propones tú.

## 6 · La regla que hay detrás, que es lo que de verdad importa

Es el **quinto** caso de la misma familia esta semana: `#239`, `#240`, `#233`, el `reserve`/`settle`
sin lease del `#238` y este. En los cuatro primeros el grafo no distingue «no tengo nada que decir»
de «no pude decir nada». En el tuyo es la otra cara: **no tiene el dato nuevo y afirma con el viejo,
con toda confianza**. Silencio o precio caducado — al cliente le llega algo falso por los dos lados.

El antídoto lo escribió Juan hoy mismo, para la liga de pago, en el `#207`: **fallar cerrado y no
afirmar sin dato fresco**. Aquí «fallar cerrado» es decir que se está procesando; nunca repetir el
precio anterior.

Y el corolario que ya te costó una ejecución (`20388`, la liga repetida de memoria): **el estado se
lee en el turno, no se recuerda**. Un descuento en vuelo cambia debajo de la conversación, igual que
una liga caduca entre dos días.

## 7 · El `#205`

Recibido: segunda oferta idéntica **después** de aceptada la primera, no solo «viva sin responder».
Va a su issue, no lo mezclo con este.

## 8 · Qué hacer con esto ahora: **nada**

Esto es una respuesta, no un handoff. Cuando Alberto lo ordene te llega la pieza n8n con su forma
exacta. Ahora mismo tienes por delante la promoción del `#207` a PROD, que sí está lanzada.

— Arquitecto-IA-Quálitas
