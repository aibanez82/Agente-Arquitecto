# `#486` — Coherencia del `systemMessage` del bot: el juicio del Arquitecto y la lista numerada

**De:** Arquitecto-IA-Insurmind · **Para:** Alberto · **11 oct 2026**
**Sobre:** el inventario del Agente n8n · A (`informes/2026-10-11-n8n-A-486-inventario-prompt.md`, `a7e7f08`), sobre PROD **`c31d2687`** (90.279 caracteres, 1.122 líneas).
**Decisión de Alberto del 26 sep, vigente:** **no se modifica nada hasta que él lo autorice.** Esto es la lista; no hay cambios.

**Verificado por mí contra el prompt vivo** (`activeVersion` de `c31d2687`): los literales de L27, 179, 255, 310, 398, 433, 522, 552, 667, 703-704, 723, 759, 780, 817, 821-822, 862, 880 y 1073 están donde dice el inventario. **Medido por mí en PROD:** `qualitas_polizaemitida.fecha_limite_pago` es una **fecha** (`date`), normalmente la del día siguiente a la emisión. No es un plazo en horas.

## Criterio

Para cada contradicción: **qué rompe en una conversación real**, **a quién más afecta** (grafo, Django, Dashboard, detectores) y **dónde se arregla**. Si el dato es exacto o la regla es dura, lo pone el grafo (`#341`/`#324`). Si es tono o criterio, va en el prompt, con una sola redacción.

## La lista, por prioridad

### Alta: pueden dar un mensaje falso al cliente o romper un hito

**1. Dónde va la pregunta del resumen** (§5.1: L759 «AL INICIO», plantilla L787 al final y cierre L791).
- **Qué rompe:** el modelo elige; en 1 de cada 3 resúmenes con la plantilla nueva sube la pregunta (STG 16911).
- **Arreglo:** **decide Alberto** (en la bandeja de firmas, y recomiendo AL INICIO). Después, el **grafo compone el marco del resumen**, como `Recovery Resumen Template`, y en el prompt quedan una sola regla y la plantilla. Se retira el cierre de L791, que invita a una segunda pregunta y a un segundo emoji (ver el 7).

**2. Criterio de emisión exitosa** (§5.4: L817 «sin link_pago NO uses el mensaje de éxito» frente a L821-822 «NO dependas de link_pago, con frecuencia es null» y L880 «si trae link_pago → EXITOSA»).
- **Qué rompe:** con una emisión real sin link, el prompt manda a la vez dar el éxito y no darlo. El modelo puede decirle al cliente que falló una póliza que sí se emitió, o al revés.
- **A quién afecta:** al detector `poliza_emitida_wa` y al Dashboard.
- **Arreglo:** **el grafo.** Es el **mensaje de emisión determinista** (en la bandeja: base, fraccionado y sin link) junto con el **`#591`** (que no se narre una póliza que no existe). Con los dos en PROD, el bloque L816-868 se queda en una regla: «el mensaje de emisión lo compone el sistema; tú no lo redactes».

**3. El `checkpoint` sin definir** (§5.13: L398 «Continúa por donde ibas según el checkpoint del [CTX:]»).
- **Qué rompe:** **es la clase 1 del propio `#486`, la del `#474`, y sigue viva.** El modelo ramifica sobre siete valores que el prompt no explica, y que además nombran lo último hecho, no lo que falta.
- **Arreglo:** **quitar la frase.** `pendiente` ya está definido (L517-554) y es lo que debe guiar la continuación. **No** definir los valores de `checkpoint`.

### Media: incoherencias que el modelo resuelve a su manera

**4. «Nunca muestres números de póliza»** (§5.2: L255 frente a la plantilla de emisión L859 y L1036).
- **Arreglo, en el prompt:** L255 pasa a decir «IDs internos (`qid`, ids de base de datos)». El **número de póliza es un dato del cliente** y la plantilla firmada lo muestra. El folio `#<folio>` del cambio de cotización (L956) es deliberado y se queda.

**5. «24 horas» frente a «no prometer vigencia en horas»** (§5.3: L862 frente a L179).
- **Hecho medido:** Django da una **fecha límite**, no horas.
- **Arreglo:** en el mensaje de emisión determinista, «realiza tu pago **antes del [fecha_limite_pago]**», con el dato de la BD. **Ojo:** la plantilla base ya firmada dice «en las próximas 24 horas», así que el cambio **lo firma Alberto**. Lo añado a la bandeja.

**6. `validate_personal_data` con email y teléfono** (§5.5: el ejemplo de L703-704 frente a «NO se incluyen» de L723).
- **Arreglo, en el prompt:** quitar las dos líneas del ejemplo. Riesgo bajo: el Issue Policy Guard ya toma los dos del registro.

**7. Emojis** (§5.8: «máximo UNO» en L27 frente a 🎉 en la plantilla y 😊 en el ejemplo de L791). Se resuelve con el 1.

**8. Ofrecer otra forma de pago en A1** (§5.7: A1 prohíbe cualquier variante que diga «forma de pago»; el `#206`, en L1073, dice que ofrecer cambiar la forma de pago es legítimo).
- **Arreglo, en el prompt:** manda el `#206`, que es posterior, firmado y más específico. Se quita «forma de pago» de la lista de A1. La prohibición de A1 se queda para la **cobertura**.

**9. «Cobertura Amplia» fijo en U1 y U2** (§5.9: L809-810 frente a `paquete_nombre` de L224).
- **Qué rompe:** con la Limitada, U1 y U2 dicen «Amplia».
- **Arreglo, en el prompt:** `[Cobertura]` como marcador en los dos.

**10. Placas «obligatorias» frente a «[PLACAS si proporcionadas]»** (§5.10: L450 frente a L780).
- **Arreglo:** «Placas: [PLACAS]». Ya lo exige el guard (`#471`), y el bloque lo rehace `Rebuild Summary From Record`.

**11. El RFC base: «nunca lo calcules» frente a «RFC base calculado»** (§5.11: L433/440 frente a L667, 700, 720 y 789).
- **Arreglo, en el prompt:** en todas, «la `rfc_base` que da el sistema». La regla buena es la del `#545`, ya cerrado.

**12. «Mensaje de respaldo», sin literal y con dos sentidos** (§3.5: L40 lo usa para el enlace de escalamiento; las otras 13 veces, para el fallo técnico. El grafo **no** manda ningún texto de fallo tras un `[api_error]`).
- **Qué rompe:** el modelo improvisa el texto de fallo.
- **Arreglo:** L40 pasa a decir «el enlace de arriba». Para el fallo técnico, **un literal firmado**, o un texto del grafo en la salida de `Is API Error?`. **Lo firma Alberto.**

**13. `descuento=no_disponible` sin explicar** (§3.1: el grafo lo emite y el prompt no lo menciona nunca).
- **Arreglo:** una línea que diga qué significa (no ofrecer ni prometer descuento), **o** retirarlo del `[CTX:]` si no hace falta. Lo decide la sesión B (descuentos) en una duda.

### Baja: higiene, después de lo anterior

**14. `pendiente`: «factura» frente a «si quiere factura»** (§5.12, L522 frente a L552). Se alinea al literal del grafo.

**15. Duplicados literales** (§4.1: «17 caracteres…» ×6, colonia «EXACTA» ×6, «tool de seguimiento interno» ×4…). Se consolidan en un sitio cada uno. **No se toca la redacción.**

**16. Reglas que el grafo ya cumple** (§6: despedida, límite de 30, liga sin póliza, identidad, fuera de alcance…). **No se borran a ciegas:** el grafo no cubre todos los casos (por ejemplo, la despedida en `data_capture`). Cada retirada, con un arnés N≥20 antes y después del comportamiento.

**17. Las menciones a MSI «3, 6 o 12»** (L266, L348 y L353, y en el grafo D2, `Figure Fidelity Guard` y `Parse Discount Classification`): **esperan al `#592`** (lo pregunta Alberto a Hylant).

**18. La descripción de `serie` en `Validate Personal Data`** («9th char is a digit or X»): no es exacta, porque el dígito verificador puede ser X por cálculo, no por regla. Se alinea con el canon VIN v2 (`#477`). Viene de la duda del `#475`.

## Cómo propongo hacerlo, si Alberto lo autoriza

- **Primero** el 1, el 2 y el 5. Ya están en la bandeja de firmas o dependen de ella. Son grafo y textos firmados.
- **Después**, un **paquete de prompt** con 3, 4, 6, 8, 9, 10, 11, 12 (solo L40), 14 y 15. Son redacción, sin cambios de comportamiento buscados. Con arnés N≥20 en sesiones limpias sobre los comportamientos afectados (resumen, emisión, RFC sin factura, forma de pago en A1, U1/U2 con Limitada), y **delta por hunk** antes del viaje.
- El 13 y el 17, en sus issues. El 16, uno a uno.

_Arquitecto-IA-Insurmind_
