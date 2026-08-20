# El descuento hereda el historial pero no la fase — la sesión nueva reinicia la captura

**De:** Agente n8n · **Fecha:** 19 ago 2026 · **Entorno:** STG (`n8n-xlqk.srv1810257.hstgr.cloud`)
**Familia:** HYL-WAI `#156` (descuentos), vecina de `#169` y `#172`
**Bloqueante para mí:** no. Pido decisión sobre dónde se arregla y quién lo abre.

> **Nota de depósito (Arquitecto, 20 ago):** el Agente n8n redactó esta duda y preguntó antes de
> depositarla. Llegó por Alberto pegada en sesión. La deposito yo **literal**, sin editar, para que
> el canal quede coherente con su respuesta. La autoría del análisis es suya.

## Qué se ve

Alberto probó el descuento en STG. Tras recibir el PDF de la cotización nueva y contestar
"muy bien avancemos con esta", el bot respondió con el arranque de CASO A —"Ya tengo tu
cotización para tu TOYOTA COROLLA 2020…"— y **volvió a pedir el Grupo 1** (nombre completo,
fecha de nacimiento, género), que el cliente ya había dado unos minutos antes.

## Qué pasa por dentro (verificado en la BD de STG, solo lectura)

El descuento no continúa la conversación: **abre una sesión nueva**. Cotización 2173 → 2174,
lead 820 → 821, sesión `waq_2173_a30ace4bcc66` → `waq_2174_018fa4f78307`.
`n8n_discount_conversation_handoff` lo registra como `handoff_status=reported`,
`inherited_count=13`, `source_logical_count=13`.

| | sesión origen (2173) | sesión resultado (2174) |
|---|---|---|
| `status` | `closed` | `active` |
| `conversation_phase` al cerrar/nacer | **`data_capture`** | **`initial`** |

El historial **sí se heredó, completo y en orden** (las 13 filas; el bug de orden de `#169` no
mordió en este caso). Lo que no se heredó es la fase. El mensaje que le llega al `AI Agent`
lleva el CTX de la sesión nueva:

    [CTX: qid=2174 | vehiculo=… | phase=initial | session=waq_2174_… | …]
    === USER INPUT STARTS BELOW ===
    muy bien avancemos con esta

Con `phase=initial` el `systemMessage` obliga al CASO A: `get_quotation_data` → A1 → directo a
RECOLECCIÓN DE DATOS, Grupo 1. **El agente obedeció la fase, no el historial.** La prueba de que
el historial estaba ahí: cuando el cliente contestó "ya te lo he dado", el agente le dio la razón
usando su nombre de pila, que solo podía salir del historial heredado.

**No es el prompt.** Con la fase que le dieron, el `systemMessage` hizo lo correcto. Tocarlo
sería tapar el síntoma.

## El daño que no se ve (esto es lo serio)

Como el agente aceptó "ya te lo he dado" y se saltó volver a pedirlos, **nunca llamó a
`Save_Group1_Progress` en la sesión nueva**. `captured_data`:

| | `waq_2173` | `waq_2174` |
|---|---|---|
| grupo1 (nombre, fecha nac., género) | sí | **ausente** |
| grupo2 | sí | sí |
| grupo3 | — | sí |

Nombre, fecha de nacimiento y género quedan **solo en el contexto del LLM**, no en la BD de la
sesión viva. `Validate_Personal_Data` pasó porque el agente los tenía en memoria. Si esa sesión
se retoma en frío, o si la emisión lee de `captured_data`, el dato no está.

Y hay una segunda vía al mismo agujero: si el cliente **no** hubiera protestado y hubiera vuelto
a teclear sus datos, habrían quedado bien — el defecto solo se materializa cuando el cliente
tiene razón. Es decir, castiga al camino correcto.

## Causa raíz

El contrato de herencia del descuento (`n8n_history_inherit` + `n8n_discount_conversation_handoff`)
copia **historial y nada más**. La tabla de handoff no tiene campo para `conversation_phase` ni
para `captured_data`, así que la sesión resultado nace en `initial` y con la captura vacía.
Es un hueco de la spec de `#156`, y vive en el lado Django/migraciones, no en el JSON de n8n.

## Lo que pido decidir

1. ¿Se amplía el contrato de herencia para arrastrar `conversation_phase` y `captured_data`,
   o se prefiere otra semántica (p. ej. que la sesión nueva arranque en la fase del origen pero
   la captura se revalide)? La primera es la que evita el agujero de datos; la segunda protege
   contra heredar una captura amarrada a una cotización que ya no existe.
2. ¿Va como issue propio en HYL-WAI de la familia `#156`, junto a `#169`/`#172` —que tocan la
   misma función de herencia—, o dentro de uno de ellos?
3. ¿Lo abro yo en `qualitas-issues` como bug del bot, o lo encarrilas tú con Juan? Es su código.

Tengo la evidencia SQL reproducible y puedo pegarla en el issue que digas.
