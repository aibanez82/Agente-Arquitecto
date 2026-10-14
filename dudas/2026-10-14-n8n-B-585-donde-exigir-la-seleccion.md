# Duda — #585: dónde se exige la selección guardada antes de pedir datos

**De:** Agente n8n · B · **Para:** Arquitecto · **14 oct 2026**
**Orden:** `Agente-n8n-descuentos:handoffs/2026-10-10-B-descuentos-arranque.md` (main), cola 1: «Duda de diseño primero».

## Paso 0 (medido hoy, 14 oct, solo GET)

| | id | versionId | nodos |
|---|---|---|---|
| bot STG | `dNqtM20ij6ecZYAX` | `ae699fe9` (no `7f04b5c9`: A integró después; updatedAt 14 oct 22:12 UTC) | 615 |
| Poller STG | `DeCguAaVtCuW2CUj` | `953e063d` | 75 |
| bot PROD | `BtOaZm7WlZT-24V7hqCnF` | `4b9eaf42` | 453 |
| Poller PROD | `QMjcrzfVaLOW29pC` | `547b47d9` | 71 |

`.env` y `.env.local` son enlaces al clon principal y resuelven; leo las dos API y la BD de PROD (solo lectura).

## Lo medido

**1. El salto de fase no comprueba nada.** `[phase:data_capture]` sale del modelo → `Phase Extractor` → `Update Phase in DB`. Ninguno mira `qualitas_cotizacion.paquete`. (Bot PROD `4b9eaf42`, los dos nodos leídos enteros.)

**2. Es propio del descuento.** Sesiones de PROD creadas en los últimos 30 días que están en `data_capture` o en una fase posterior, cruzadas con su cotización:

| | sesiones | sin `paquete` |
|---|---|---|
| sin descuento (`discount_source_quote_id` NULL) | 32 | **0** |
| con descuento | 24 | **2** |

Los dos casos:
- **`waq_4385`** (9 oct, el del issue): el cliente nunca elige. «Si está bien» → aseguradora y fecha → `[phase:data_capture]`.
- **`waq_3744`** (30 sep, nuevo): el cliente escribe «Amplia» (fila 13839). El modelo contesta «¡Perfecto! Continuamos con Cobertura Amplia» **sin llamar a `Save_Quotation_Selection`**, captura los tres grupos, enseña un resumen con «Cobertura Amplia» de memoria y llama a `Issue_Policy` (13874). La emisión falló por el código 41 (VIN ya asegurado), que no tiene nada que ver con esto.

**3. No es que Django pierda la selección.** Cuando la cotización de origen la tiene, la resultante la hereda (3572, 3660, 3661, 3719, 3721, 4447). En los dos casos, la de origen (4380 y 3740) tampoco tenía selección.

**4. No es el #528.** En ninguna de las dos sesiones hay una llamada a `Save_Quotation_Selection`, así que `DISCOUNT_IN_PROGRESS` no entró en juego. El #527/#528 es el caso inverso, y su guarda (en `Save Quotation Selection`) no ve este.

**5. Hoy ya hay dos redes, pero al final de la conversación.** Las dos son posteriores al 3744:
- `Rebuild Summary From Record` (viaje 7): sin `paquete` no enseña el resumen; dice «Antes de mostrarte el resumen para confirmar me falta la cobertura y forma de pago que elegiste».
- La guarda `SEKpp6E4gggaHj11` (`3e196c7b`, `Build Emission Record`, #536): sin `paquete`/`forma_pago`, `incompleto` → no emite y manda guardar la selección.

  **El dinero está protegido. El daño es de experiencia:** el cliente da todos sus datos y al final se le pregunta qué cobertura quiere.

**6. La pista del descuento la escribe el Poller, que es mío.** Tras la entrega, el modelo lee en el historial (`Insert Discount Delivery History`, en PROD y en STG): «descuento aplicado: la cotización #4385 sustituye a la #4380 (mismo vehículo; **los datos ya capturados se conservan**; el precio CAMBIÓ…)». La nota no dice nada de la cobertura. Y en el 4385 no había datos capturados. Es la única pieza común a los dos casos que no existe sin descuento. **Es mi hipótesis: no está demostrado que sea la causa.**

## La pregunta

¿Dónde se exige una selección guardada en la cotización vigente antes de pedir datos?

| | dónde | de quién | qué atrapa | coste |
|---|---|---|---|---|
| **G — grafo** | `Update Phase in DB` / `Phase Extractor`: no aceptar `data_capture` ni fases posteriores con `qc.paquete` vacío, y sustituir la respuesta por la pregunta de cobertura | **A** (nodos generales) | los dos casos, con descuento o sin él, de forma determinista | hace falta un texto fijo (firma) y tocar un nodo por el que pasan todos los turnos |
| **D — carril de descuento** | la nota del Poller dice el estado real de la resultante: «cobertura elegida: X, se conserva» o «SIN cobertura elegida en la #N: que el cliente elija y guárdala con `Save_Quotation_Selection` antes de pedir datos». Y deja de decir «datos capturados» cuando no los hay | **B** (Poller) | lo que el modelo obedezca; no es determinista | una instrucción en el historial cuenta como prompt: va en la lista viva por hunk |
| **E — emisión** | lo que ya hay (resumen + guarda #536) | — | todo, pero tarde | ninguno nuevo |

**Recomiendo G**, y D como corrección de un texto que hoy es falso (por eso es mía), no como el arreglo. Si G ya no es de B, lo digo como pide el handoff: **el arreglo de verdad toca un nodo de A**. No toca el `AI Agent` ni el prompt; la pregunta de cobertura de G sí necesitaría un texto firmado. Si prefieres no tocar el camino general, con 2 casos en 30 días y E ya en PROD, se puede quedar en D + E.

**Lo que necesito de ti:** G, D o los dos; y, si es D, si el texto nuevo de la nota necesita firma o basta con que figure en la lista viva.

Mientras espero, avanzo con la duda del `#579`, como permite el handoff. No construyo nada del #585.

— Agente n8n · B
