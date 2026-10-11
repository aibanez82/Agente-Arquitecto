# Informe · Agente n8n · A · #486: inventario del `systemMessage` del bot en PROD (`c31d2687`)

**Órdenes:**
- `Agente-n8n:handoffs/2026-10-10-486-inventario-prompt.md`;
- `Agente-n8n:handoffs/2026-10-10-A-noche-486-461-475.md` (1392aaed), orden de Alberto «si, lánzalo todo». Este segundo añade las contradicciones internas y lo que el grafo ya hace.

**Solo lectura.** Ni import, ni commit en `workflows/`, ni llamadas al modelo. Es el mapa, sin juicios: no califico nada.

## Fuente

| | PROD | STG |
|---|---|---|
| bot | `BtOaZm7WlZT-24V7hqCnF`, `versionId` **`c31d2687`**, activo, 445 nodos | `dNqtM20ij6ecZYAX`, `5adf0e57` |
| `AI Agent.options.systemMessage` | 90.279 caracteres, 1.122 líneas | 91.005 caracteres, 1.130 líneas |
| `RAG IA Agent.options.systemMessage` | 28.304 caracteres, 334 líneas | 28.893 caracteres, 339 líneas |

- **Método:** leí el `systemMessage` de PROD línea a línea, entero. `L<n>` es la línea (desde 1) y `off` es el desplazamiento en caracteres del inicio de esa línea, desde 0. Los recuentos son por regex, con el patrón al lado.
- **Ámbito:** el `AI Agent`. Del RAG doy solo los recuentos.
- **Diferencias STG−PROD en el `AI Agent`:** dos inserciones, ambas de la petición de llamada.
  - L44-46 de STG: la regla de llamada en la lista de escalamiento;
  - L354-358 de STG: la línea D, bloqueada para PROD por el `#592`.
  - Ningún otro hunk.

---

## 1. Recuento

| patrón (Python `re`) | AI PROD | AI STG | RAG PROD | RAG STG |
|---|---|---|---|---|
| `\bNUNCA\b` | 54 | 54 | 16 | 16 |
| `\bSIEMPRE\b` | 18 | 18 | 3 | 3 |
| `\bJAMÁS\b` | 1 | 1 | 1 | 1 |
| `\bPROHIBIDO\b` | 15 | 15 | — | — |
| `PROHIBID` (raíz, mayúsculas) | 16 | 16 | 17 | 17 |
| `\bprohibido\b` (minúsculas) | 1 | 1 | 3 | 3 |
| `(?i)\bopcional` | 2 | 2 | 0 | 0 |

**Las dos líneas de «opcional»:**
- L446: `**NÚMERO INTERIOR (OPCIONAL):**`;
- L453: «No digas nunca que son opcionales».

---

## 2. Mapa de bloques (`AI Agent`, PROD)

**Qué cuenta como encabezado:**
- una línea de nivel superior en MAYÚSCULAS que acaba en «:»;
- un delimitador `=== … ===` (sin contar los `FIN`).

La longitud va hasta el siguiente encabezado. Los sub-bloques (`CASO`, `EDGE CASE`, `REGLA CRÍTICA`) van con sangría.

| L | off | long. | encabezado |
|---|---|---|---|
| 1 | 0 | 243 | `==== SYSTEM INSTRUCTIONS START ===` + `[CRITICAL: …]` |
| 6 | 243 | 500 | `SECURITY RULES (HIGHEST PRIORITY):` (hasta `=== END SECURITY RULES ===`, L14) |
| 16 | 743 | 1.560 | `PERSONA Y TONO (aplica a TODOS los mensajes al cliente):` |
| 30 | 2.303 | 557 | `REGLA DE SEGURIDAD — NOMBRE NO DISPONIBLE:` |
| 33 | 2.860 | 11.642 | `ESCALAMIENTO INMEDIATO A AGENTE HUMANO:` (sub-bloques a continuación) |
| 53 | | | ↳ `DECLINACIÓN EXPLÍCITA DEL LEAD (NO es escalamiento a humano):` |
| 65 | | | ↳ `RECHAZO BLANDO RECIÉN ENTREGADA LA COTIZACIÓN (NO es declinación, NO cierres la sesión):` |
| 89 | | | ↳ `OTRO VEHÍCULO (NO es escalamiento):` |
| 101 | | | ↳ `RENOVACIÓN DE PÓLIZA (NO es escalamiento):` |
| 107 | | | ↳↳ `LÍMITE DE 30 DÍAS (aplica a CASO A …)` |
| 130 | | | ↳↳ `DISAMBIGUACIÓN -- …` |
| 140 / 159 | | | ↳↳ `CASO A —` / `CASO B —` |
| 167 | | | (línea suelta) «Eres Carla, asesora de Quálitas…» |
| 169 | 14.502 | 2.715 | `CONTINUIDAD COMERCIAL V1 — PRIORIDAD SOBRE COPY GENÉRICO:` |
| 176 | 17.217 | 1.761 | `ASEGURAR LIGA DE PAGO — HYL-WAI #207:` |
| 186 | 18.978 | 2.776 | `PASO CRÍTICO INICIAL:` (+ 4 `EDGE CASE —` en L192, 195, 201 y 208) |
| 218 | 21.754 | 802 | `VALORES AMIGABLES PARA EL USUARIO:` |
| 236 | 22.556 | 295 | `LIMITACIÓN DE ALCANCE:` |
| 241 | 22.851 | 1.000 | `LÍMITES DE LONGITUD DE MENSAJES:` |
| 254 | 23.851 | 1.746 | `REGLAS GENERALES:` |
| 264 | 25.597 | 679 | `MANEJO DE PAUSA DEL CLIENTE (CUALQUIER FASE):` |
| 269 | 26.276 | 984 | `CONTENIDO NO SOPORTADO COMO DESPEDIDA SOCIAL ([MEDIA_NO_SOPORTADA]):` |
| 282 | 27.260 | 6.694 | `SALUDO Y SELECCIÓN DE PAQUETE (FASE: GREETING):` |
| 288 | | | ↳ `CASO A — paquete es null …` (A1 en L299, A2 en L320, `EDGE CASE` en L344, 361 y 372) |
| 352 | 33.954 | 2.582 | ↳ `MSI Y PAGO FRACCIONADO SON COSAS DISTINTAS — NO LAS MEZCLES NUNCA:` |
| 377 | | | ↳ `CASO B — paquete tiene valor …` |
| 390 | 36.536 | 738 | `CAMBIO DE COTIZACIÓN POR DESCUENTO:` |
| 400 | 37.274 | 44 | `RECOLECCIÓN DE DATOS (FASE: DATA_CAPTURE):` |
| 402 | 37.318 | 1.341 | `ESTRATEGIA DE RECOLECCIÓN EN 3 GRUPOS:` |
| 421 | 38.659 | 2.536 | `REGLAS ESPECIALES DE RECOLECCIÓN:` (CP, RFC Y FACTURA, NÚMERO INTERIOR, PLACAS) |
| 459 | 41.195 | 971 | `GRUPO 1 - DATOS PERSONALES:` |
| 484 | 42.166 | 9.782 | `GRUPO 2 - DATOS DEL VEHÍCULO (…):` (FOTO DE TARJETA en L503, `[IMAGEN_CLIENTE]` en L556, NIV ESCRITO en L572, «Cuando el cliente escriba un número de serie» en L575) |
| 595 | 51.948 | 58 | `GRUPO 3 - DIRECCIÓN Y CONTACTO (WITH COLONY VALIDATION):` |
| 597 | 52.006 | 1.957 | `IMPORTANTE - VALIDACIÓN DE COLONIA:` |
| 638 | 53.963 | 2.586 | `PROCESO DE VALIDACIÓN DE COLONIA:` (+ `OBLIGATORIO EN ESTE TURNO` en L658) |
| 679 | 56.549 | 555 | `NOTAS CRÍTICAS:` |
| 690 | 57.104 | 978 | `VALIDACIÓN (UNA VEZ, DESPUÉS DE CONFIRMAR GRUPO 3):` |
| 714 | 58.082 | 1.083 | `NOTAS IMPORTANTES PARA VALIDACIÓN:` |
| 725 | 59.165 | 238 | `RESULTADO DE VALIDACIÓN:` |
| 731 | 59.403 | 1.085 | `MANEJO DE EDGE CASES:` |
| 751 | 60.488 | 1.069 | `FASE DE RESUMEN (SUMMARY_CONFIRMATION):` |
| 767 | 61.557 | 1.257 | `MENSAJE ÚNICO - RESUMEN COMPLETO:` (+ `REGLA CRÍTICA` en L789 y `CIERRE DEL MENSAJE DE RESUMEN` en L791) |
| 793 | 62.814 | 380 | `IMPORTANTE:` |
| 799 | 63.194 | 2.489 | `ENVÍO DEL PDF/DOCUMENTO DE LA COTIZACIÓN:` (+ `REGLA CRÍTICA — ANTI-FABRICACIÓN DE URLs` en L801 y `DATO QUE VIVE EN UN DOCUMENTO` en L812) |
| 816 | 65.683 | 3.723 | `EMISIÓN DE PÓLIZA Y PAGO:` (+ `FUENTES DE DATOS PARA issue_policy` en L831, `REGLA CRÍTICA — DATOS INTERNOS` en L840 y `PROHIBIDO en el mensaje de emisión` en L865) |
| 869 | 69.406 | 597 | `IMPORTANTE:` |
| 879 | 70.003 | 5.944 | `MANEJO DE ERRORES:` (+ `EDGE CASE — No revivir la oferta…` en L917) |
| 927 | 75.947 | 1.310 | `=== INSTRUCCIÓN DE FASE (OBLIGATORIO) ===` → `=== FIN … ===` (L944) |
| 947 | 77.257 | 3.154 | `=== CAMBIO DE COTIZACIÓN (el cliente quiere ver otra suya) ===` → L995 |
| 998 | 80.411 | 1.487 | `=== SUMA ASEGURADA — DOS NÚMEROS SIN NOMBRE QUE NO SE NOMBRAN (#293) ===` → L1016 |
| 1018 | 81.898 | 880 | `=== QUÉ COTIZACIÓN ESTÁ ACTIVA ===` (sin `FIN`; acaba donde empieza L1031) |
| 1031 | 82.778 | 842 | `=== UN HECHO REGISTRADO NO SE DESMIENTE ===` → L1042 |
| 1044 | 83.620 | 1.474 | `=== ACOMPAÑAMIENTO AL PEDIR DATOS (#316) ===` → L1061 |
| 1063 | 85.094 | 1.266 | `=== LA LIMITADA NO SE OFRECE SOLA (#206) ===` → L1079 |
| 1081 | 86.360 | 1.577 | `=== TRADUCE LO QUE PIDE A LO QUE EXISTE (#334) ===` → L1100 |
| 1102 | 87.937 | 952 | `=== TEXTOS DE COBERTURA Y PRECIO (#461) ===` → L1107 |
| 1109 | 88.889 | 943 | `=== CUANDO EL CLIENTE TE CORRIGE (#340) ===` → L1115 |
| 1117 | 89.832 | 416 | `=== SEGURO DE LA AGENCIA O DEL FINANCIAMIENTO (#553) ===` → L1120 |
| 1122 | — | — | `=== SYSTEM INSTRUCTIONS END ===` |

Las filas ↳ son sub-bloques: van dentro de la longitud de su bloque padre. El orden de los bloques no sigue el de las fases: tras `MANEJO DE ERRORES` (L879) vuelven reglas transversales (L947-1120).

---

## 3. Referencias a cosas externas

### 3.1 Campos del `[CTX:]`

**Lo que el grafo emite** (`AI Agent.parameters.text` de PROD, literal):

> qid · vehiculo · phase · checkpoint · pendiente · session · phone · fecha_actual · serie\* · rfc_base\* · aseguradora\* · vence\*/dias\*/limite30\*/fecha_max\* · fecha_inicio\* · poliza=emitida\* · descuento=no_disponible\*

\* = condicional.

| campo | menciones en el prompt (patrón `\b<campo>\b`) | ¿define el significado? (literal, L · off) |
|---|---|---|
| `qid` | 5 (L38, 391, 1019, 1022, 1029) | **Sí.** L1019 · off 81.933: «La cotización activa de este turno es la del campo `qid` del prefijo [CTX: ...]… la ÚNICA fuente de verdad» |
| `vehiculo` | **0** | — |
| `phase` | 1 en forma `phase=` (L942) | Sí, por remisión. L942: «Si no estás seguro de la fase, consulta el valor phase= en el prefijo [CTX:...]». Valores en L932-936 |
| `checkpoint` | **1** (L398 · off 37.207) | **No.** Literal: «Continúa por donde ibas según el checkpoint del [CTX:].» El prompt no da los valores. El grafo emite `quote_sent`, `personal_data_captured`, `vin_plates_captured`, `rfc_digits_pending`, `address_captured`, `summary_pending` y `payment_link_sent` (`Merge Session Data`, `derivarCheckpoint`) |
| `pendiente` | 18 (6 con `pendiente=`) | **Sí**, por valores: L517-532 y L546-554. Lo da el grafo con `derivarPendiente`: «datos personales», «placas y número de serie», «domicilio», «RFC», «si quiere factura», «confirmación del resumen», «nada». **Literal en L522 · off 45.000:** «(datos personales, domicilio, RFC, factura, confirmación del resumen)»: pone «factura» donde el grafo emite «si quiere factura». L552 sí usa «si quiere factura» |
| `session`, `fecha_actual` | **0** | — |
| `phone` | 1 (L37, dentro de la URL del enlace `phone=`) | No como campo del `[CTX:]` |
| `serie` | `serie=` ×4 (L486, 490, 496) | **Sí.** L486: «Cuando el CTX de este turno incluya el campo `serie=` … el cliente YA te proporcionó su número de serie al solicitar el descuento» |
| `rfc_base` | 9 (L433, 434, 436, 440, 665, 666) | **Sí.** L433: «La base del RFC (10 caracteres) te la da el sistema en `rfc_base`». No dice que viaje en el `[CTX:]` |
| `aseguradora` | 3 en forma `aseguradora=` (L114, 133, 134) | Sí, en L133-135 |
| `vence` / `dias` / `limite30` / `fecha_max` | L110-128 | **Sí.** L110 da la forma y L113-126 los valores de `limite30` (dentro / fuera / vencida) |
| `fecha_inicio` | 9; como campo del `[CTX:]` solo L774 | Sí, en L774: «SOLO incluir esta línea si el [CTX:...] trae `fecha_inicio`» |
| `poliza=emitida` | 2 (L182 · off 18.287; L562 · off 48.226) | Uso condicional. No dice qué significa: se infiere del nombre |
| `descuento=no_disponible` | **0** | — |

### 3.2 Marcadores

**El patrón de búsqueda es el literal exacto.** «Emisores» = nodos de código de PROD que contienen el literal.

| marcador | veces | L | define | emisores en el grafo |
|---|---|---|---|---|
| `[FOTO_VIN]` | 3 | 506, 533, 573 | Sí: L504-509 («información inyectada por el sistema…») | `Parse VIN Extraction`, `Image Budget Guard`, `Vision Pipeline Error Fallback` |
| `[IMAGEN_CLIENTE]` | 2 | 556, 557 | Sí: L557-568, con los valores de `tipo=` | `Parse VIN Extraction` |
| `[SERIE_SOSPECHOSA]` | 2 | 573, 575 | Sí: L573 | `Inject Serie Note` |
| `[MEDIA_NO_SOPORTADA]` | 3 | 269, 270, 278 | Sí: L270 | `Session Context Builder` |
| `[api_error:X]` | 9 | 837, 848, 883, 884, 891, 905, 909, 911, 915 | L915: «son procesados automáticamente — no son visibles al usuario» | lo escribe el modelo; lo retira `Detect API Failure` |
| `[phase:X]` | 4 | 929, 939, 940 | Sí: L928-943 | lo escribe el modelo; lo lee `Phase Extractor`, que bloquea `completed` |
| «TOPE DE FOTOS ALCANZADO» | 1 | 546 | Sí | `Image Budget Guard` |
| «TOPE DE LECTURAS DE TARJETA ALCANZADO» | 1 | 569 | Sí | `Parse VIN Extraction` |
| «Texto que el cliente escribió junto a la imagen» | 1 | 533 | Sí | `Parse VIN Extraction`, `Image Budget Guard`, `Vision Pipeline Error Fallback` |
| «quote_document_sent — descuento aplicado…» | 1 | 392 | Sí: L391-393 | `Merge Session Data`, `Build History Payload` y otros |

### 3.3 Tools conectadas al `AI Agent`

Hay 14 conexiones `ai_tool` medidas en PROD.

| tool (nodo) | cómo la nombra el prompt (recuento) | primera |
|---|---|---|
| Issue Policy | `issue_policy` 36 · `Issue Policy` 1 | L144 |
| Get Quotation Data | `get_quotation_data` 21 · `Get Quotation Data` 7 | L24 |
| Validate Personal Data | `validate_personal_data` 6 | L443 |
| Search Colony by Postal Code | `search_colony_by_postal_code` 3 | L601 |
| Save Group1/2/3 Progress | `save_groupN_progress` 1 / 6 / 1 · `Save_GroupN_Progress` 1 / 1 / 1 · `save_group1/2/3_progress` 1 | L471 |
| Save Policy Data | `save_policy_data` 2 | L823 |
| Mark Session Closed | **nunca por su nombre**: «usa la tool disponible para esto» (L44 y L56-57, cortado por un salto de línea), «la tool de cerrar sesión» (L73) | L44 |
| Listar Cotizaciones / Cambiar Cotizacion | 2 / 2 | L953 / L962 |
| Save Quotation Selection | 4 | L173 |
| Ensure Payment Link | 1 | L177 |
| Get Emission Record | `get_emission_record` 2 | L752 |

### 3.4 Fases (`[phase:]`)

Patrón `(?i)\b<fase>\b`:

| fase | veces | líneas |
|---|---|---|
| `greeting` | 6 | L17, 69, 265, 282, 530, 932 |
| `data_capture` | 7 | — |
| `summary_confirmation` | 4 | — |
| `policy_issuance` | 2 | — |
| `payment_pending` | 2 | — |
| `completed` | 2 | L939, solo para prohibirla |

`POLICY_ISSUANCE` en mayúsculas aparece en L795 como destino («Proceder a POLICY_ISSUANCE»).

### 3.5 Otras referencias sin definir en el prompt

- **«mensaje de respaldo»: 14 apariciones** (L40, 190, 758 «respaldo técnico», 837, 838, 848, 882, 883, 891, 905, 911, 1040…). **Ningún literal lo define.**
  - L40 · off 3.684 lo usa para el **mensaje de escalamiento**: «responde ÚNICAMENTE con el mensaje de respaldo de arriba» (el único texto «de arriba» es el enlace de L37).
  - El resto lo usa para el **fallo técnico**.
  - El grafo tiene sus propios textos de fallo: `Send Generic Error Message` («Tuve un problema técnico al consultar tu información…») y `Send Agent Error Fallback` («Tuvimos un problema procesando tu mensaje, ¿puedes repetirlo?»). Ninguno sale de `[api_error]`: `Is API Error?` lleva sus dos salidas a `Update Phase in DB` (medido en `connections`).
- **«M24»** (L213 · «mismo criterio que M24»): no se define en el prompt.
- **«la regla 0 de FASE»** (L532, 554, 563): se define en L939.
- **Números de issue citados en el texto:** `#62`, `#207`, `#206`, `#248`, `#288`, `#293`, `#316`, `#323`, `#334`, `#340`, `#461` y `#553`.

---

## 4. Duplicados

Un **duplicado literal** es una frase de 9 palabras normalizadas que se repite en dos o más líneas. Un **duplicado de materia** es la misma regla escrita en sitios distintos.

### 4.1 Literales (los que dicen lo mismo)

| materia | líneas |
|---|---|
| «Solo puedo ayudarte con la contratación de tu póliza de auto…» | 11, 239 |
| cerrar sesión «usa la tool disponible para esto» | 44, 56 |
| «Como tu póliza anterior ya venció, no es una renovación…» | 125, 163 |
| copy de `discount_processing` | 174, 881 |
| copy de la pasarela caída con `poliza=emitida` | 182, 562 |
| «no vuelvas a presentarte ni repitas "Soy Carla"» | 292, 381 |
| «3 grupos pequeños SIN confirmación entre cada uno» | 403, 870 |
| «La base del RFC (10 caracteres) te la da el sistema en `rfc_base`…» (línea idéntica) | 433, 440 |
| «es una tool de seguimiento interno, nunca la menciones ni muestres su resultado» | 472, 585, 653, 824 |
| «17 caracteres, sin las letras I, O ni Q» | 478, 501, 580, 885, 886, 887 |
| «Si tienes una foto de tu tarjeta de circulación…» | 480, 582 |
| «aplica la regla 0 de FASE» | 531, 554, 563 |
| colonia «EXACTA de la base de datos» | 613, 630, 642, 647, 681, 706 |
| ciudad / estado «inferido de la base de datos SEPOMEX» | 707-708, 718-719 |
| «no es un fallo de sistema: NO muestres el mensaje de respaldo y NO agregues [api_error…]» | 884, 891, 904, 909 |
| «Espera la NUEVA respuesta del usuario antes de reintentar» | 888, 900 |

### 4.2 Dos versiones que no dicen lo mismo, lado a lado

| materia | versión 1 | versión 2 |
|---|---|---|
| diferir 30 días | L118 · off 10.834: «Por ahora solo puedo diferir el inicio de tu póliza hasta 30 días. La fecha más lejana que puedo ofrecerte es el [fecha_max]. ¿Quieres que la iniciemos en esa fecha, o prefieres que te contacte más cerca…?» | L896 · off 72.520: «Por ahora solo puedo diferir el inicio de tu póliza hasta 30 días a partir de hoy. ¿Me confirmas una fecha dentro de ese rango?» (el `invalid_range` de Django) |
| preguntar la fecha de vencimiento | L128: «¿Qué día exacto vence tu seguro actual?» (también L142) | L164: «¿Qué día vence tu póliza actual? Te puedo preparar la nueva para que empiece justo ese día…» |
| la serie, en los textos de error | L885: «debe tener exactamente 17 caracteres, sin espacios ni guiones y sin las letras I, O ni Q» | L886: «17 caracteres, sin las letras I, O ni Q» (sin «espacios ni guiones») |

### 4.3 Materias escritas en varios sitios

- **Ofrecer la Limitada:** L297 · off 28.458 («NUNCA añadas «¿o prefieres ver otra cobertura o forma de pago?» ni menciones la Limitada»), L310-312 (A1), L1064-1078 (#206), L1095-1097 (frontera con el #334) y L1104 (texto L2).
- **Criterio de emisión exitosa:** L817, L820-822 y L880. El detalle va en §5.4.
- **Link de pago tras la emisión:** L819, L828 y L829.
- **Email y teléfono internos:** L684, L723, L832-833, L840-851 y L866.
- **«No ofrezcas el link del agente»:** L58, 87, 91, 104-105, 161 y 923.
- **Placas obligatorias:** L450-457, L715 y L780 (este último va en §5.10).
- **Una sola confirmación del flujo:** L403-409, L677, L734 y L870-871.
- **Precio consultado en el turno:** L170 y L982-994.
- **MSI 3, 6 o 12** (relevante para el `#592`, sin juicio): L266 · off 25.893, L348 · off 33.658 y L353 · off 34.023. En el RAG, L122 de PROD. En el grafo, el texto D2 de `Merge Session Data` (#418) lleva el mismo literal del gancho de pausa de L266, y `Figure Fidelity Guard` y `Parse Discount Classification` también contienen «3, 6 o 12».

---

## 5. Contradicciones internas: pares de literales sobre la misma materia que ordenan cosas distintas

Sin calificar. Están en el orden en que aparecen en el prompt.

**5.1 Dónde va la pregunta del resumen** (la del handoff)
- L759 · off 61.125: «Envía UN solo mensaje con toda la información consolidada, con la pregunta de confirmación AL\nINICIO del mensaje (no al final) — WhatsApp trunca mensajes largos con "Leer más" y la pregunta\nquedaría oculta si va al final.»
- Plantilla firmada, L787 · off 62.198 (última línea de la plantilla de L767-787): «[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.»
- L791 · off 62.408: «CIERRE DEL MENSAJE DE RESUMEN: si agregas algo después del bloque de domicilio, NUNCA termines con una pregunta binaria seca… ej. "¡Confírmame para asegurar esta tarifa antes de que cambie! 😊"»
- **El grafo:** `Rebuild Summary From Record` (#536) rehace solo el bloque de datos; «del modelo quedan la apertura, el cierre y la línea del vehículo». Dónde va la pregunta lo sigue decidiendo el modelo.

**5.2 Mostrar números de cotización o de póliza**
- L255 · off 23.869: «1. Nunca muestres números de ID de cotización o póliza al usuario»
- Frente a:
  - L859: «Póliza: [NÚMERO]» (plantilla de emisión);
  - L1036 · off 83.224: «confirma la emisión con el número registrado»;
  - L956 · off 77.802: «"1. #<folio> — <MARCA MODELO AÑO> (actual)"»;
  - L971: «"Listo, seguimos con la #<folio> (<vehículo>)…"».
- **El grafo:** `Filter System Leaks` tacha «cotización id … <dígitos>» y `POL-\d+`, no los números de póliza.

**5.3 Plazo del pago en horas**
- L179 · off 17.667: «business_date y due_date no autorizan a prometer vigencia en horas.»
- L862 · off 69.125: «Para activar tu cobertura, realiza tu pago en las próximas 24 horas:» (plantilla de emisión)

**5.4 Criterio de emisión exitosa** (el H8 del primer barrido, re-medido sobre `c31d2687`)
- L817 · off 65.709: «…si la llamada falló o no devolvió link_pago, NO uses el mensaje de éxito bajo ninguna circunstancia»
- L821-822 · off 66.398: «NO dependas de que link_pago venga presente, con frecuencia es null aunque la emisión sí haya sido exitosa»
- L880 · off 70.022: «si el body trae link_pago → la emisión fue EXITOSA (muestra el link de pago). Si el body trae status:"error" o un campo code → la emisión FALLÓ»
- Y L819 · off 66.234: «issue_policy retorna AUTOMÁTICAMENTE el link de pago en su respuesta», con L829: «Muestra el link de pago inmediatamente…»

**5.5 Qué lleva `validate_personal_data`**
- L703-704 · off 57.648, dentro del bloque de L692-712: `"email": "...",` y `"telefono": "...",`
- L723 · off 59.003: «**email y telefono**: NO se incluyen en validate_personal_data.»

**5.6 Confirmar el Grupo 3**
- L403 · off 37.357: «SIN confirmación entre cada uno»; L655 · off 54.881: «sin repetirlos ni pedir "¿Correcto?", pasa directo a preguntar por la factura»
- Frente a:
  - L691 · off 57.156: «Cuando el usuario confirme el Grupo 3, llama validate_personal_data»;
  - L680 · off 56.565: «**Siempre valida la colonia** antes de confirmar el Grupo 3»;
  - L873 · off 69.646: «Valida UNA VEZ cuando tengas TODOS los datos (después de confirmar Grupo 3)»;
  - el título de L690.
- Confirmaciones dentro de la captura: L437 · off 39.833 («Confirma el RFC completo: "Tu RFC es …, ¿es correcto?"»), L512 · off 44.175 (VIN de foto, «pide que confirme explícitamente») y L744 («Re-confirma y continúa»).

**5.7 Ofrecer otra forma de pago en el turno en que se piden los datos**
- L310-312 · off 30.646 (A1): «No emitas "¿Continuamos con esta opción o prefieres ver otros planes de pago?" NI NINGUNA VARIANTE, incluidas las que sustituyen "planes de pago" por "cobertura", "forma de pago", "otra opción" u "otros precios".»
- L1073 · off 85.881 (#206): «La forma de PAGO es otra cosa y no entra aqui: ofrecer cambiarla es legitimo. Lo que no se ofrece en ese turno es cambiar de COBERTURA.»

**5.8 Emojis**
- L27 · off 2.131: «Emoji: máximo UNO por mensaje»
- La plantilla del resumen lleva «🎉» (L768), y el cierre de ejemplo de L791 añade «😊».

**5.9 El nombre de la cobertura en U1 y U2**
- L224 · off 22.011: «PREFERENTE: si la opción viene de opciones_cotizacion y trae paquete_nombre, usa ESE nombre tal cual»; L771: «Cobertura: [Cobertura Amplia/Limitada]»
- L809 · off 64.393 (U2) y L810 · off 64.860 (U1) escriben «Cobertura Amplia» fijo dentro del texto.

**5.10 Placas en la plantilla del resumen**
- L450-453 · off 40.653: «**PLACAS DEL VEHÍCULO (OBLIGATORIAS):** … No digas nunca que son opcionales»
- L780 · off 62.029: «Placas: [PLACAS si proporcionadas]»

**5.11 El RFC base, ¿lo calculas tú?**
- L433 / L440: «Úsala tal cual; NUNCA la calcules tú.»
- Frente a:
  - L667 · off 55.762: «rfc=<RFC base calculado>»;
  - L700 · off 57.422: «Sin factura: RFC base calculado»;
  - L437: «[RFC_CALCULADO]»;
  - L720 · off 58.660: «RFC calculado + homoclave»;
  - L789: «el RFC fue calculado internamente».

**5.12 Los valores de `pendiente`.** Ya está en §3.1: L522 dice «factura» y L552 y el grafo, «si quiere factura».

**5.13 El `checkpoint`.** Ya está en §3.1: L398 ramifica sobre un campo cuyos valores el prompt no define. `pendiente` sí está definido.

---

## 6. Lo que el grafo ya hace y el prompt sigue pidiendo al modelo

Grafo de PROD `c31d2687`. «Carril fijo» = el grafo responde y el modelo no corre en ese turno.

| mecanismo determinista (nodos) | lo que hace | texto del prompt sobre la misma materia |
|---|---|---|
| **Despedida fija** (#418: `IF Despedida Fija?`, `Despedida Fija Copy` y su carril; textos D1-D5 en `Merge Session Data`) | Clasifica la despedida: no actúa en el primer mensaje, ni con «No…» (rechazo blando), ni en `data_capture`. Elige D1-D5; D2 = gancho de pausa, una vez por sesión, y lo anota en `Persist Gancho Pausa` | L264-266 MANEJO DE PAUSA, con el gancho **literal igual a D2** · L80-83 cierre del rechazo blando («Perfecto, gracias por tu tiempo…») · L86 «NO aplica después de emitida la póliza… es cortesía, despídete» · L269-280 despedida con media · L1060 «Un "gracias" … mientras captas datos es cortesía» (el grafo tampoco actúa ahí) |
| **Límite de 30 fijo** (`IF Limite 30 Fijo?`, `Limite 30 Fijo Copy`, `Persist Fecha Inicio (Limite 30)`) y su red en `Outbound Leak Guard` (líneas que narran la cuenta) | Responde con los literales firmados de CASO A, fuera y vencida, y guarda `fecha_inicio` | L107-128 (la cuenta, los tres textos, «NUNCA hagas tú la cuenta…») · L140-150 texto de CASO A · L163-164 b1 y c1 |
| **Liga sin póliza** (#552: `IF Liga Sin Póliza?` y su carril) | «Aún me faltan algunos datos tuyos para poder emitir, y después te genero el link de pago.» | L177-184 ASEGURAR LIGA DE PAGO (no trata el caso sin póliza) |
| **Identidad** (#254: `IF Identity Intent?`, `Identity Reply`) | «Soy Carla, un asistente con inteligencia artificial…» | L18-19 «preséntate como "Soy Carla, de Quálitas"». No hay regla sobre «¿eres un bot?» |
| **Parámetro Quálitas** (#249: `IF Qualitas Parameter Intent?`) + `Filter System Leaks` §2.b | Ruta propia y filtro del término | L170-172 (`qualitas_parameter`, «NUNCA lo menciones…») |
| **Estado de la póliza** (#275: `IF Policy Status Intent?`, `IF Payment Question?`) + red #275/#279 en `Outbound Leak Guard` («una póliza emitida no se desmiente») | Ruta propia, y quita la negación de una emisión registrada | L1031-1041 UN HECHO REGISTRADO · L925 |
| **Fuera de alcance** (`Check Out of Scope`, `Out of Scope Guard`) | Ruta propia | L236-239 LIMITACIÓN DE ALCANCE |
| **Jailbreak** (`Detect Jailbreak`, `Ban Guard`, `Guardrail Error Safe Reply`) | Guardrail antes del modelo | L6-12 SECURITY RULES |
| **Fase** (`Phase Extractor`) | Lee `[phase:]` y bloquea `completed` (#69) | L927-944 y L939 regla 0 |
| **`[api_error]`** (`Detect API Failure`) | Retira el marcador | L915 |
| **Fugas** (`Filter System Leaks`) | Tacha IDs de cotización, `POL-`, el Parámetro Quálitas, fugas del prompt y de tools, y restos de expresiones | L7, L12, L17, L172 y L255 |
| **Número del agente** (#517 en `Outbound Leak Guard`) | Sustituye el enlace viejo | L37 (enlace) |
| **Cifras** (`Figure Fidelity Guard`, #341/#500) | Valida las cifras contra las fuentes del turno | L985-994 (precio consultado) · L358-359 · L1012 (suma asegurada literal) |
| **Correo** (`Email Fidelity Guard`, #473) | Correo distinto del canónico → lo sustituye | L842-847 |
| **Guardarraíl de emisión** (`Detect Emision Narration` → `Validate Emision Against DB` → `Apply Guardrail Result`). En PROD es la versión de prefijo (`76200\d{5}`, «emitida exitosamente», URLs de pago); la del `#591` (regla por cotización) está en STG | Bloquea una emisión narrada que no está en `qualitas_polizaemitida` | L817 ANTI-FABRICACIÓN (issue #62) · L1031-1041 |
| **Resumen desde el registro** (#536: `Summary Reply?`, `Read Summary Record`, `Rebuild Summary From Record`) | Rehace el bloque de datos; si falta algo, pide lo que falta en vez de mostrar el resumen | L752-758 (`get_emission_record`, «los tomas SOLO de lo que devuelva») · plantilla L767-787 · L789 (RFC sin factura: el grafo lo omite si `requiere_factura≠SI`) |
| **Issue Policy Guard** (tool `Issue Policy` → workflow `SEKpp6E4gggaHj11`): registro de emisión, placas (#471), correo canónico (#466/#492) | Toma los datos del registro y exige placas | L450-457 y L715 (placas) · L831-838 · L723 · L832-833 |
| **Validate Personal Data** (`toolCode`) | Valida el formato (incluido el VIN) | L690-727 · L575 (b) |
| **VIN tecleado** (`Detect Typed VIN`, `Check Typed VIN`, `Inject Serie Note`, `Persist Typed VIN`) | Inyecta `[SERIE_SOSPECHOSA]` | L572-575 · L478 / 501 / 580 (formato para el cliente) |
| **VIN de foto** (`Parse VIN Extraction`, `IF Foto VIN Valid?`, `Detect Confirmation` (#472 sí/no/ambiguo), `Persist Guard Foto VIN`) | Lee la foto, decide la confirmación y persiste | L503-516 («pide que confirme explícitamente … ANTES de llamar save_group2_progress»; «NUNCA guardes un dato de foto sin esa confirmación») |
| **Tope de imágenes** (`Image Budget Guard`, #474/#581) | «TOPE DE FOTOS ALCANZADO» | L546-554 |
| **Limitada observada** (`IF Limitada Observada?`, #461 fase 1) | **Solo observa:** «limitada» en la salida sin «limitad/cobertura/opcion/paquete/plan» en el mensaje del cliente | L1063-1079 (#206) · L297 · L1104 |
| **Carriles de descuento** (sesión B: `Discount Phase 2 Claim` y el resto; desde el #156 todo texto libre entra por ahí) | Clasifica, ofrece, aplica y veta | L170-175 CONTINUIDAD COMERCIAL · L372-375 · L390-398 · L810 (U1) · L1103-1106 · L1112 (K1) |
| **Petición de llamada** (solo STG `5adf0e57`, «Llamada Fija») | Textos A, B y C | En PROD: L43 «Usuario quiere hablar con una persona, agente o humano» (lista de escalamiento). En STG se añade la aclaración de L44-46 |

---

## Lo que este inventario no cubre

- Solo lleva el `AI Agent`. El RAG tiene únicamente recuentos.
- No mide si el modelo cumple cada regla en tráfico real. Es un mapa del texto y del grafo.
- §5 enumera pares con literales y no los gradúa.
- §6 empareja por materia, no por cobertura exacta: que el grafo actúe no quiere decir que cubra todos los casos de la regla del prompt. Donde el grafo se aparta a propósito (despedida en `data_capture`, primer mensaje), lo digo.

— Agente n8n · A
