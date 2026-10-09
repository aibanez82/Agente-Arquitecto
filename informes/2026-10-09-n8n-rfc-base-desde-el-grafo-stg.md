# Informe — la base del RFC desde el grafo: aplicada en STG; aceptación cumplida y un control al 2/5

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** `dudas/2026-10-09-n8n-rfc-base-en-el-contexto-respuesta.md` (diseño aceptado).

**Bot STG:**

| versión | qué |
|---|---|
| `129a4b01` | el diseño |
| **`94e85a8c`** | el ajuste de la homoclave |

**Rama:** `fix/firmas-paquete-prompt-stg` (`scripts/firmas/cambio_rfc.py`, `cambio_rfc2.py`, `rfc-base.js` y el arnés).

## Qué hay

- **`Merge Session Data`:**
  - lleva `rfc-base.js` **literal**, con un puntero cruzado al `Calcular Base RFC` del IPG;
  - tiene un campo `rfcBase` que **solo** se rellena con nombre, paterno, **materno** y fecha válidos; si falta uno, `null`, sin valores parciales.
- **`AI Agent/text`:** `| rfc_base=…` en el `[CTX:]`.
- **Prompt:**
  - **fuera la fórmula y el ejemplo**, en los bloques de factura SÍ y NO;
  - la instrucción única que diste;
  - `save_group2_progress` pasa a «toma la base de `rfc_base`».
- **Ajuste (`94e85a8c`), interno y no copy:** la línea «SOLO pide la homoclave» queda **condicionada**:
  - **con `rfc_base`:** solo la homoclave, sin mostrar la base;
  - **sin `rfc_base`:** el RFC completo, nunca solo la homoclave.

## Pruebas

| prueba | resultado |
|---|---|
| fuera de n8n, `Merge Session Data` | Prado → `PAGJ921203`; sin materno, sin fecha, materno `N/A` o sin Grupo 1 → `null`. **Corpus #545 (88, con materno): la base del contexto es igual a la del algoritmo de la emisión, 88/88** |
| **arnés sin envíos, «Juan Prado Gómez», 3 turnos (serie → factura → homoclave)** | **`PAGJ921203` en el resumen 5/5** (antes del cambio: 1/5) |
| control: la base no sale suelta antes del resumen (turno de la homoclave) | **2/5**. En 3/5 el modelo aún dice «tu RFC base es **PAGJ921203**. Solo me falta la homoclave…» (siempre la base correcta) |
| sin materno | **4/5** piden el RFC completo sin inventar base. La quinta mezcla ruido de la sesión sembrada (cobertura sin elegir) y pide la homoclave |
| sin fecha | **5/5**, no inventa base |

**Primera tanda, antes del ajuste:** Prado con la base en el resumen 5/5 y la base suelta 5/5; sin materno 2/5.

## Lo que te subo

- **La aceptación principal se cumple:** «Prado» da 5/5 con `PAGJ921203` en el resumen.
- **El control de la base suelta se queda en 2/5.**
  - **Pese a la instrucción, el modelo enseña la base al pedir la homoclave.** Ahora siempre es la base correcta, la del grafo. **No sigo afinando el prompt:** con instrucciones no lo he conseguido de forma fiable.
  - **Opciones:**
    - **(a)** aceptarlo, porque la base que enseña es la correcta;
    - **(b)** una salida de grafo determinista para la pregunta de la homoclave (un texto fijo cuando `requiere_factura=SI`, hay `rfc_base` y falta la homoclave);
    - **(c)** una guarda de salida que quite la base suelta (10 caracteres sin homoclave) de ese turno.
  - **Recomiendo (a),** o (b) si el control es imprescindible.
- **Para Alberto:** la línea firmada del `#545` (plantilla del RFC) ya no está en el prompt; la sustituye la instrucción de `rfc_base`, como dijiste. Aviso: el viaje de prompt a PROD lleva también `Merge Session Data` y el `text` del AI Agent, que son grafo.

Agente: Agente-n8n

## Adenda (9 oct) — tu acuse: opción (a)

- **Control de la base suelta: retirado de la aceptación**, como dices. No toco más el prompt. Queda en STG `94e85a8c` y viaja con el paquete de prompt.
- **El fallo sin materno (pasada 3), literal:**

  > Veo que también falta elegir tu cobertura y forma de pago. Para darte tu RFC necesito la homoclave (3 caracteres) — ¿me la pasas? Y confírmame: ¿seguimos con Cobertura Amplia, pago anual?

  **No inventó ninguna base** (ni completa ni parcial: no hay ninguna cadena de 10 caracteres en el mensaje). **Pero no es solo ruido:** pidió la homoclave en vez del RFC completo, en un turno mezclado con el ruido de la sesión sembrada ("falta elegir tu cobertura y forma de pago"). Queda anotado: sin materno, 4/5 piden el RFC completo y 1/5 pide la homoclave **sin base**, es decir, el cliente tendría que dar el RFC completo de todas formas al confirmar.

## Adenda 2 (9 oct) — sin materno, repetido en sesiones limpias, y lo que llegaría a la emisión (nada tocado)

**Sesiones limpias.** Cotización 2345 (TAHOE 2020, Amplia y contado ya elegidos: sin el ruido de «falta elegir tu cobertura»), N=5.
- **3/5** piden el RFC completo.
- **2/5** vuelven a pedir la homoclave, sin inventar ninguna base. Ejemplo: «¿me compartes tu homoclave (los últimos 3 caracteres)? …».

**Medición, como pediste.** Repetí N=5 con un tercer turno en el que el cliente da solo la homoclave («mi homoclave es AB1»).
- **Qué guarda `Save Group2 Progress`:** en las **5/5**, `grupo2.rfc` sigue siendo `"N/A"`, con `requiere_factura="SI"`. **El modelo no guarda ningún RFC inventado** (ni de 10 ni de 13 caracteres).
- **Qué llegaría a `Call Issue Policy Real`:** ejecuté fuera de n8n los nodos **vivos** del IPG STG `b431ad23` sobre esos registros.
  - `Calcular Base RFC` da `{calculada: "PAXJ921203", aplicada: false, motivo: "sin_rfc_en_registro"}`: no toca nada.
  - `Build Emission Record` da `rfc=""` y `homoclave=""`, con **`_faltan` que incluye `"rfc"`**. Así que **`Record Incomplete?` corta la emisión y no llega nada a `Call Issue Policy Real`**.
  - El agente recibe `_msgFaltan`: «No se emitió: faltan datos en el registro. Pide al cliente SOLO estos datos (rfc)…». Los otros faltantes de la salida, como `telefono`, son artefactos de mi entrada fuera de n8n, no del caso.
- **Conclusión:** en este camino **no hay emisión con un RFC incompleto**. Falla cerrado: la guarda del registro exige el RFC de 13 caracteres cuando hay factura y devuelve al agente a pedirlo. **El coste** es un turno de más: el cliente da la homoclave, la emisión se niega y el bot le pide el RFC completo.

**No he tocado nada.** ¿Lo das por bueno, o quieres que la pregunta sin `rfc_base` sea determinista (un texto fijo del grafo cuando `requiere_factura=SI` y no hay `rfc_base`)?
