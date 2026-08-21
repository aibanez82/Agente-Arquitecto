# Inventario de promoción STG → PROD

> **Documento VIVO.** Cada arreglo que entra en STG y no está en PROD se anota aquí **en el momento**,
> con la medición que acredita si el defecto existe en producción o no. Cuando toque promover, la
> lista existe y no hay que reconstruirla de memoria.
>
> **Regla de Alberto (20 ago 2026):** el trabajo de STG no se frena por PROD. Lo que se acumula
> entra aquí y se promueve en su propia ventana.
>
> Los planes de *cómo* promover viven aparte: `2026-08-12-plan-promocion-stg-a-prod-v2.md` y
> `2026-08-14-promociones-en-20-minutos-diagnostico-y-plan.md`. **Este documento es el QUÉ.**

**Última medición contra el bot vivo de PROD (`BtOaZm7WlZT-24V7hqCnF`): 21 ago 2026.**

---

## Aplica a PROD — el defecto está allí, medido

### 1. `#192` · No hay red de error — **lo más urgente**

| | |
|---|---|
| Medición en PROD | **0 de 5** workflows con `errorWorkflow`; ningún nodo con `onError` |
| ¿Ya causó daño? | **Sí.** Ejecuciones `8212` y `8242` del 13 ago: 42 y 43 nodos ejecutados, muerte por credencial inexistente. **Dos clientes reales escribieron y no recibieron nada.** Descubierto ocho días después |
| Riesgo mientras no se promueva | Cualquier excepción en producción sigue siendo silencio invisible |

**Es el único ítem de esta lista cuyo coste se paga en clientes perdidos mientras espera.**

### 2. `#174` · El fallback genérico ante un fallo técnico de emisión

| | |
|---|---|
| Medición en PROD | frase genérica «No conozco esta respuesta» **×14**; texto de familia emisión **×0** |
| Qué recibe hoy el cliente | «No conozco esta respuesta» cuando falla la emisión — **sin decir nada del cobro** |
| Ya en STG | Sí, vivo desde el 20 ago 22:35Z |

### 3. `qualitas-issues#85.1` · Dos instrucciones opuestas en el `systemMessage`

| | |
|---|---|
| Medición en PROD | «SIN confirmación entre cada uno» **×2** y «con confirmación entre cada uno» **×2** — **las dos conviven** |
| Efecto | El modelo obedece a una de las dos y no hay forma de saber a cuál |
| Ya en STG | Sí, corregido en el `#186` |

### 4. `#189` (punto 3) · Las sesiones no se cierran nunca

| | |
|---|---|
| Medición en PROD | **1.066 `open`** frente a **15 `closed`** |
| La herramienta existe | `Mark Session Closed` está en el bot de PROD (**4 apariciones**) |
| La instrucción no | El `systemMessage` de PROD la menciona **0 veces** |
| Por qué no ha explotado allí | Cada teléfono suele tener un lead: solo 3 teléfonos con más de una sesión viva, máximo 3. **Es circunstancia, no blindaje** |

---

## NO viaja — el defecto no existe en PROD

Medido: **cero apariciones de `Discount` en el bot de producción.** Todo el módulo de descuentos es STG-only, y con él sus arreglos:

| ítem | por qué no aplica |
|---|---|
| `#180` herencia de fase y captura tras descuento | no hay descuentos en PROD |
| `#182` releer la cotización tras el descuento | ídem |
| `#156` selección comercial persistida | ídem — y depende del endpoint de Django |
| `#181` guard de emisión | `Issue Policy Guard (STG)` no existe en PROD |
| `#177` archivado de Metepec | Metepec nunca existió en PROD |

**Estos entran en la promoción del módulo de descuentos completo, no antes ni por separado.**

---

## Sin resolver todavía — no promovible aún

| ítem | estado |
|---|---|
| `#183` trazabilidad del historial | documentado, sin arreglo |
| `#189` puntos 1 y 2 | en handoff |
| `#184` modelo de datos de precios | propuesta a Juan |
| Los 15 gates C1 de poller/Retomar/Payment | pendiente de decisión |
| La divergencia de 3 nodos entre candidato e instancia | pendiente de decisión |

---

## Cómo se mantiene

**Al cerrar cualquier issue que haya tocado STG, se comprueba si el defecto existe en PROD y se anota
aquí con la medición.** No «probablemente aplica»: el conteo contra el workflow vivo.

Esa comprobación es barata —una lectura por API— y es la diferencia entre tener la lista el día de la
ventana o reconstruirla a base de memoria y de leer issues cerrados.
