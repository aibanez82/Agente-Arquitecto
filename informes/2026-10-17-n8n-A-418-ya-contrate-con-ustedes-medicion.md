# #418 · «ya contraté con ustedes» dispara la D5: medición sin modelo y propuesta de excepción

**Orden:** adenda 20 de `handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md` (main `36465b6a`). **Caso:** PROD `waq_4519`, 16421 → 16422.
**Qué se ha medido:** el detector que **corre en PROD**, extraído del bot vivo `4b453cd6` (`Merge Session Data`, copia literal de `scripts/418/despedida.js`). `clasificaDespedida` y `eligeTexto` son idénticos al fuente de `fix/firmas-paquete-prompt-stg`. Se ha usado `despedidaFija` con la fase real de la sesión y el turno anterior del bot, y además un barrido de las 6 fases.
**Coste:** 0 llamadas al modelo; PROD solo se ha leído.
**Dónde está:** Agente-n8n, rama `wip/418-ya-contrate-con-ustedes` (`a0e90bae`), `scripts/418c/`. `medir.sh` lo reproduce desde cero. El corpus no está versionado porque es texto real de clientes.

## 1. La causa: una sola regla

`despedida.js:21`: `/\bya (consegui|contrate|compre|saque|tengo otr|me asegure|lo contrate|lo saque|lo compre)/` → `'definitiva'` → D5.
La regla mira el verbo y no con quién se contrató.

## 2. Cuántos disparan la D5

| Corpus | Mensajes | D5 con su fase real | D5 en alguna fase |
|---|---|---|---|
| Recovery PROD: sesiones con `poliza_anterior_recovery=` en el [CTX:] o con `proposed_session_id` | 25 humanos, 8 sesiones | **1** (16421) | 1 |
| Variantes sintéticas, con el turno real del bot anterior a 16421 (`data_capture`) | 21 | **8** | 8 |
| Las mismas, sin turno previo del bot | 21 | 0 (regla G2) | 0 |
| Control en PROD fuera de Recovery (regex «ya/antes… contrat/asegur/seguro/póliza» o «contrat/asegur… con ustedes/contigo/antes») | 28 | 1 (9155 «Ya contraté gracias», sesión `completed`: correcta) | 1 |

Las 8 variantes que dan D5:
- seis «con nosotros»: «Pero ya contraté seguro contigo antes», «ya contraté con ustedes», «Ya contrate con ustedes antes», «ya contraté con ustedes el año pasado», «ya contrate contigo» y «Ya contraté con Quálitas antes»;
- dos «con otra»: «ya contraté con otra aseguradora» y «ya contraté otro seguro».

Estas variantes «con nosotros» **no** dan D5: «ya había contratado con ustedes», «yo ya fui cliente», «ya tenía seguro con ustedes», «ya estuve asegurado…», «Ya tuve una póliza con ustedes», «ya tengo seguro con ustedes», «ya les había comprado», «antes ya tenía el seguro…» y «ya estaba asegurado… pero se canceló». La regla solo coge «ya contraté», en primera persona del pretérito.

**Dato aparte, para la adenda 20:** «ya tengo seguro», «ya tengo seguro con otra», «ya lo aseguré» y «ya lo aseguré con GNP» **hoy no** dan D5: van al modelo. Solo la dan «ya contraté con otra aseguradora» y «ya contraté otro seguro». No lo cambio: no está en la orden.

## 3. ¿Es solo de Recovery?

**La regla es general.** No tiene ninguna condición de Recovery. Un cliente normal que escriba «ya contraté con ustedes el año pasado» también recibe la D5: es la variante v7 con fase `data_capture`, y da D5 en las 6 fases.
En PROD fuera de Recovery no hay **ningún** caso real de ese tipo entre los 28 candidatos. El único caso real es el de Recovery (16421), donde la frase es la esperable porque todos los clientes de la campaña ya fueron nuestros.

## 4. Propuesta (sin aplicar)

Una excepción en `despedida.js`, en esa misma línea (`scripts/418c/excepcion.patch`):

```js
const conNosotros = /\b(con ustedes|contigo|con qualitas|aqui mismo|por aqui mismo|con este numero)\b/.test(t) && !/\b(otr[oa]s?|otra aseguradora)\b/.test(t);
if (!conNosotros && /\bya (consegui|contrate|…)/.test(t)) return 'definitiva';
```

- **Efecto medido:**
  - Recovery pasa de 1/25 a **0/25**; 16421 da `null` y va al modelo.
  - Las 6 variantes «con nosotros» pasan a 0.
  - «con otra aseguradora» y «otro seguro» **siguen** en D5.
  - El control 9155 sigue en D5.
  - La batería del `#418` (`scripts/418/bateria.js`) da **29/29 + 8/8**, igual con la excepción que sin ella.
- **Ámbito: lo recomiendo general, no solo Recovery.**
  - Solo quita la D5 cuando el cliente dice que el seguro fue *con nosotros*, y en ese caso va al modelo, que es el camino que ya tienen todas las frases no reconocidas.
  - Condicionarlo a `poliza_anterior_recovery` dejaría el mismo defecto a un cliente normal que vuelve.
  - Tú decides.
- **Dónde se toca:** `clasificaDespedida` es una copia literal en **tres** nodos: `Merge Session Data`, `Message Budget Guard` (`#606`, la cortesía que no cuenta) y `Parse Discount Classification` (veto del `#494`). Al cambiar el fuente cambian los tres.
  - Con la excepción, «ya contraté con ustedes» deja de contar como cortesía en el `#606`.
  - Y deja de vetar el carril de descuentos.
  - Las dos cosas me parecen coherentes con que vaya al modelo.
- **El texto** que verá el cliente es el del modelo, con la propuesta 42 de la bandeja, que espera la firma de Alberto.
- **Viaje:** lo construyo con la 13.2 en STG, como dice la adenda. A PROD, con orden.

Agente n8n · A
