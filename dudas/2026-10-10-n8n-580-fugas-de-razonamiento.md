# Duda n8n · #580: red general de fugas de razonamiento (diseño antes de construir)

**Handoff:** `Agente-n8n:handoffs/2026-10-10-580-fugas-de-razonamiento.md`. **No he construido nada.** Prototipo:
`scripts/580/fuga-razonamiento.js` (rama `fix/firmas-paquete-prompt-stg`, `bc2e7d0c`). Lo hice mientras corre la batería
de Sonnet 5.5, que va antes en la cola.

## Corpus de STG (medido)
- **Universo:** 969 filas `ai` de STG, sin las `Calling …` ni `quote_document_sent`.
- **Primera búsqueda ancha** (los patrones de abajo, más «debo» y «esto es» sueltos): 14 candidatos.
  - **8 son los seguimientos de Django** «(ESTO ES UN TEST) ¡Seguimos por aquí!…»: no son fugas y la red los respeta.
  - **Fugas reales:**
    - 5136: «El cliente se refiere a la Amplia con descuento (ya consultada arriba…). Ya tengo los datos de precio; solo necesito
      confirmar…»;
    - 6106: «Debo cortar aquí: lo que hice en el turno anterior fue un error grave — inventé una "emisión exitosa"…»;
    - 11710: «El cliente está pidiendo renovar… Esto es CASO B de renovación.»;
    - 6043 y 6518: «La serie tiene solo 17 caracteres válidos que debo revisar… cuento 18… Déjame verificar…». **El prototipo no la
      cubre:** es un monólogo de conteo mezclado con lo que sí va al cliente. Ver la pregunta 3.
- **Del arnés y del informe:** la 85229 («Esto es un rechazo blando (…). Pregunto por la objeción.»), la del KIA de PROD («El cliente
  sigue insistiendo… No debo… Debo mantenerme…») y la fila 8591 de PROD («De acuerdo a la regla 10 sobre promociones…»).

## La red (una sola fuente, por línea, el mismo mecanismo que la del límite de 30)
Solo patrones de **forma** (el modelo hablando de sí, del cliente en tercera persona o citando su prompt), nunca de tema:

| patrón | qué cubre | qué NO toca |
|---|---|---|
| `tercera_persona` | línea que **empieza** por «El/La cliente» + un verbo de razonamiento (está, sigue, insiste, pide, se refiere…) | «Para el cliente que paga anual…» |
| `esto_es` | «Esto es un rechazo / caso / objeción / pausa… / CASO X» | «Esto es lo que incluye tu Cobertura Amplia:» y «(ESTO ES UN TEST)» |
| `debo` | línea que **empieza** por «Debo / No debo» **sin** destinatario | «Debo pedirte tu RFC» (pedir**te**, te, tu, usted…) |
| `regla_n` | «de acuerdo a / según / aplico la regla N» | — |
| `seccion_prompt` | nombres de secciones del prompt en mayúsculas: EDGE CASE, REGLA CRÍTICA, ESCALAMIENTO INMEDIATO, MANEJO DE PAUSA, CASO X… | — |
| `accion_propia` | «Procedo a / Voy a aplicar… / Pregunto por la objeción» | «Paso a pasito…» |
| `claves_ctx` | `[CTX`, `qid=`, `phase=`, `pendiente=`, `poliza_anterior…`, `checkpoint=` | — |

- **Batería:** 21/21 (10 positivos reales y 11 negativos dirigidos al cliente).
- **STG:** 3 marcas de 969, **las tres fugas reales**; 0 falsos positivos.
- Se quitan las líneas marcadas. Si el mensaje se queda vacío, sale el original con la marca (`fugaRazonamiento580: 'vacio'`).

## Lo que te pido
1. **El corpus de PROD**, como dice el handoff. Patrón de búsqueda, sobre `message->>'content'` de las filas `ai` (sin `Calling %` ni
   `quote_document_sent`), en regex de Postgres, sin distinguir mayúsculas:
   `(^|\n)\s*(el|la) client[ea] |(^|\n)\s*(no )?debo |regla [0-9]|esto es (un|una|el|la|caso)|procedo (a|con)|edge case|caso [a-z]\M|rechazo blando|escalamiento inmediato|\[ctx|qid=|phase=|pendiente=|poliza_anterior`
   El falso positivo de PROD lo mides tú con `fuga-razonamiento.js`, como en las anteriores.
2. **Una sola fuente.** El `Outbound Leak Guard` de STG ya lleva el `META_551` del `#551` B2 (tercera persona, «Esto es CASO X» y claves
   del [CTX:]), que es un subconjunto de esta red. ¿Lo sustituyo por la red general? Así hay una sola lista, y el `#551` viajaría sin su
   propia red. Propongo que sí.
3. **El monólogo de conteo** (6043/6518): ¿añado `Déjame verificar` y `cuento N caracteres` como patrones? ¿O se queda fuera, porque
   esa línea mezcla un dato que sí va al cliente (la serie)?
4. **Línea en el prompt:** propongo **no** ponerla de momento. La red tapa la salida; si tu medición de PROD encuentra formas que la red
   no puede ver sin falsos positivos, la planteamos como instrucción interna.

## Aceptación (cuando me des paso)
- Los positivos del corpus de PROD y de STG cubiertos.
- 0 falsos positivos en tu medición de PROD.
- Regresión del límite de 30: `red-limite30.js` llevará un puntero a esta red, y las dos corren en el mismo nodo, en orden.
- Arnés: la 85229 reproducida (prompt de control) sale sin la línea.

Agente: Agente-n8n
