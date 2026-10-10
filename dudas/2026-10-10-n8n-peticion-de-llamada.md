# Duda n8n · cuando el cliente quiere llamar (textos A-D): diseño antes de construir

**Handoff:** `Agente-n8n:handoffs/2026-10-10-peticion-de-llamada-stg.md`. **Textos:** `informes/2026-10-10-mejoras-conversacion-peticion-de-llamada.md`.
**No he construido nada.** Prototipo del detector: `scripts/llamada/llamada.js` (rama `fix/firmas-paquete-prompt-stg`).
La escribo en un hueco de la batería de Sonnet 5.5 porque el `#580` aún no tiene handoff: **no adelanto la construcción a la cola.**

## Propuesta (filosofía del #418: lo exacto lo pone el grafo)
**1. Detector determinista**, sin modelo: `clasificaLlamada(texto)` devuelve `mencion`, `peticion`, `queja` o nada.
- `mencion`: «le llamo», «le marco», «manda a buzón», «no contestan», «le estoy llamando de este número».
- `peticion`: «quiero llamar», «quiero que me llamen», «prefiero por teléfono», «¿me pueden llamar?», «llámame», «¿a qué número llamo?».
- `queja`: «no me quiere responder», «nadie me contesta», «no me hace caso», «no me está respondiendo».
- **Nada**, a propósito:
  - «hablar con una persona / un agente / un asesor»: sigue escalando, regla 1;
  - «me llamo Juan…»: es un nombre, y en STG aparece dos veces;
  - «me marca error».
- **Medido:**
  - batería con las frases reales de `waq_4379` más negativos: **20/20**;
  - **STG: 0 marcas en 688 mensajes humanos.** STG no tiene peticiones de llamada reales, así que **el falso positivo que cuenta es el de
    PROD**, que mides tú con el mismo fichero.

**2. Contador en la sesión.** `captured_data.llamada = {a, b, c}`, escrito por una rama lateral **solo cuando el texto salió**, como el
gancho del `#418`. Las decisiones de `decideLlamada`:
- `mencion` sin A previo → **A**;
- `mencion` tras A, o `peticion` → **B**, una vez;
- `queja` → **C**, una vez;
- todo lo demás → **el modelo**, sin defender más el canal.

Con la secuencia real de `waq_4379` sale **A → B → modelo → modelo → C → modelo**. Nunca hay dos textos iguales (regla 3) ni más de dos
defensas (regla 2).

**3. Dónde:** un carril de respuesta fija **gemelo del `#418`** (fence, fila human, fila ai `llamada_fija` con `dispatch_id`), en la
misma cadena de IFs, decidido en `Merge Session Data`.

**4. B y su cifra:** `$[PRECIO_VIGENTE]` lo pone el grafo. Propongo una subconsulta nueva en `Resolve Session`: la `PrimaTotal` del XML
`<paquete elegido, o Amplia>_anual` de la cotización de la sesión. Es la misma fuente que ya leen el `#341` y el `#500`; tras un descuento,
la sesión apunta a la cotización con descuento.

**5. D, por el modelo con cifras del grafo:** en el `[CTX:]`, `| msi_anual=$7,880.90: 3x$2,626.97 · 6x$1,313.48 · 12x$656.74`. Son las
divisiones de la prima del punto 4, redondeadas al centavo. El modelo responde a lo que preguntó y pone esas cifras. Lo de los bancos
(BBVA en 3 y 6, no en 12) sale de la KB (fragmento 33): **no lo toco**. ¿O quieres que el grafo también lo prohíba?

**6. Prompt:** en «ESCALAMIENTO INMEDIATO A AGENTE HUMANO» se quita la llamada de la situación («quiere hablar con una persona, agente o
humano» se queda) y se añade una frase: «pedir una llamada no es pedir una persona: no mandes el enlace del agente». Es cambio del
systemMessage: firma de Alberto y la lista viva por hunk.

**7. Descuento:** el clasificador corre antes. Una petición de llamada con objeción de precio («le marco porque está caro») **la gana el
descuento**: el objetivo de Alberto es un mejor precio, y el detector de llamada **no entra en el veto** del `#494`/`#418`. El caso
contrario (una llamada sin precio clasificada como `PRICE_OBJECTION`) lo vería en tu medición de PROD.

## Preguntas
1. **B sin descuento:** el literal dice «te respeto el precio con descuento que ya tienes ($X)». Si la sesión **no** tiene descuento, es
   falso. ¿B solo con descuento, y sin él A (que habla de «precio preferencial»)? ¿O hace falta otro texto firmado?
2. «para la contratación pero no me responde» (14868) no dice «llamar». ¿Lo cuento como `mencion` si **un mensaje anterior del cliente**
   en la sesión habló de llamar (`prev_human_textos`)? Propongo que sí.
3. ¿El detector + el carril, con el modelo solo para D, te vale? ¿O prefieres D también fijo? Lo desaconsejo: D responde a una pregunta
   distinta cada vez.
4. ¿El contador vive por **sesión** o por **teléfono**? Propongo sesión, como el `gancho_pausa_usado`.

## Aceptación (cuando me des paso)
- La secuencia de `waq_4379` (14859-14886) en el arnés: A una vez, B una vez, nada repetido, ningún enlace del agente ante «quiero
  llamar», C ante «no me quiere responder» y D con las cifras exactas.
- «quiero hablar con un agente» sigue escalando.
- Regresión del `#418` y del límite de 30.

Agente: Agente-n8n
