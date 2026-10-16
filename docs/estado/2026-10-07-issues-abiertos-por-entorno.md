# Issues abiertos de HYL-WAI por caso de uso y entorno — foto del 7 oct 2026, actualizada el 10 oct (cierre del día)

**De:** Arquitecto-IA-Insurmind · **Para:** Alberto · **7 oct 2026 · actualizado 10 oct 2026 (tarde, CDMX)**

> **10 oct, noche (prueba de Alberto en PROD):** **89 abiertos**. **Cerrados con su caso real (8):** `#544`, `#325`, `#313`, `#456`, `#261`, `#581`, `#418` y `#257`. **Nuevo:** `#593` (serie de foto descartada en silencio). `#475` confirmado con un caso real (VIN tecleado con O).
>
> **10 oct, noche:** **96 abiertos**. **Cerrados:** `#333` (licencia, «ni sí ni no») y `#589` (router de pagos), los dos en PROD y verificados (KB: 120 filas y la fila 122; bot `c31d2687`). **Nuevo:** `#592` (tope del 30 % en 12 MSI). Ver «Movimientos del 10 oct».
>
> **10 oct, cierre:** **97 abiertos**. **Cerrados por la tarde, con evidencia medida (8):** `#496`, `#349`, `#545`, `#469`, `#245`, `#344`, `#345` y `#588`. **Nuevos:** `#587`, `#589`, `#590` y `#591` (el `#588` se abrió y se cerró el mismo día). **Viajando a PROD** por orden de Alberto: `#333` (licencia, «ni sí ni no») y `#589` (router de pagos). Ver «Movimientos del 10 oct».
>
> **10 oct, noche:** **100 abiertos**. Nuevos `#585` y `#586`, los dos nuestros, salidos de la revisión de PROD de Mejoras y medidos por el Arquitecto. **Dashboard en PROD con el PDF del descuento** (`main` `313d375`; falta la prueba con la #4379). `#486`: el inventario del prompt, encargado al Agente n8n. Viaje 7 aún sin tráfico real: el último mensaje de cliente es del 9 oct a las 17:33. Ver «Movimientos del 10 oct».
>
> **10 oct:** **98 abiertos**. **Viaje 7 en PROD** (bot `1b869a0f`, Guard `3e196c7b`; Dashboard `d453998`). Juan cerró 8 en su auditoría final (`#259`, `#337`, `#463`, `#473`, `#479`, `#552`, `#564`, `#570`); el Arquitecto cerró el `#348`. Nuevos: `#579`, `#580`, `#581` (nuestros) y `#583` (Juan). Ver «Movimientos del 10 oct».
>
> **9 oct, tarde:** **103 abiertos**: entra el `#578`; cerrados `#347` y `#270` (barrido de la mañana) (orden de prioridades para Juan). **Viaje 6 en PROD** (bot `26dfbb82`, Guard `42309047`): textos firmados, base del RFC desde el grafo, respuesta fija del límite de 30 días y la fecha de inicio para la emisión. STG: la línea «Inicio de vigencia» lista para el próximo viaje; el proxy `autocache` instalado (igual que PROD).
>
> **9 oct, mañana:** 104 abiertos. Cerrados el 9 oct: `#565`, `#178` y `#398` (duplicado del `#134`). Nuevo: `#577` (Juan). Ver «Movimientos del 9 oct».
>
> **8 oct:** 106 abiertos. Han entrado `#570`, `#571` y `#574`; se han cerrado `#554` y `#568` (Juan). Los viajes 1 a 5
> están en PROD, verificados en vivo por el Arquitecto, y sus issues pasan a `PROD ✱` a la espera del caso real. Ver
> «Movimientos del 8 oct» y el **plan** al final.
**Fuente:** `aguayo-co/HYL-WAI`. Foto inicial: **120** issues abiertos (7 oct por la tarde). **Tras los cierres del
mismo día: 105** (16 cerrados con evidencia medida y 1 nuevo, el `#568`). Ver «Cerrados el 7 oct» y «Barrido de
cierre».

> ⚠️ **Es una foto y caduca.** Las columnas de entorno salen de **lo que dice cada issue** (cuerpo y comentarios,
> tomando el último dato del hilo), **sin medir contra los sistemas**. Solo las celdas marcadas con ✱ las he medido
> yo el 7 oct. Muchos issues de Juan tienen su último dato en agosto o principios de septiembre, así que su estado
> puede haber cambiado. Siguiente paso previsto: medir en vivo los críticos y los altos.

## Leyenda

- **Resp.:** A = Alberto (`aibanez82`) · J = Juan (`oilycoyote`).
- **Problema en:** dónde está vivo el fallo o dónde falta la mejora: `PROD`, `STG`, `Ambos`, o `¿?` si el issue no
  lo dice.
- **Arreglo:**
  - `—` sin arreglo;
  - `STG` o `PROD`, solo en ese entorno;
  - `Ambos`, en los dos, pero el issue sigue abierto porque falta acreditarlo en una conversación real;
  - `Parcial`.
- 🔴 = criticidad crítica por label o por título.

## Totales (15 oct: 89 en tablas + `#578`, la lista de prioridades)

| Responsable | Issues |
|---|---|
| Juan | 46 |
| Alberto | 41 |
| Compartido | 2 |

| Problema en | Issues |
|---|---|
| PROD | 48 |
| No consta | 20 |
| Ambos | 12 |
| STG | 9 |

| Arreglo | Issues |
|---|---|
| Sin arreglo | 57 |
| Parcial | 15 |
| Solo STG | 10 |
| Solo PROD (falta caso real) | 3 |
| En los dos entornos (falta acreditar) | 2 |
| Otro | 1 |
| Firmado, en curso | 1 |

---

## 1. Descuentos: ofrecer, aplicar y comunicar bien el descuento (22)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 608 🔴 | Cotizó con un CP que no es el suyo: no se puede corregir conservando el descuento y la póliza sale con un domicilio falso ✱ | A | PROD | STG ✱ provisional (`ae699fe9`/`02ed57c1`: la marca bloquea la emisión, pasa a una persona con el texto firmado y pausa los seguimientos); a PROD con orden; la recotización con otro CP, pedida a Juan |
| 585 | Tras el descuento pasa a pedir datos sin cobertura elegida (`paquete` y `forma_pago` en NULL) ✱ | A | PROD | — |
| 579 | Un timeout de Django deja la aplicación `uncertain` para siempre | A | PROD | — |
| 563 | El carril vuelve a pedir el VIN confirmado por foto | A | PROD | PROD ✱ (viaje 1, bot `b7caf68b`); falta la primera foto real |
| 553 | Oferta de la competencia: pedir precio y cobertura | A | PROD | PROD ✱ parcial (viaje 6: C9); C1-C8 pendientes |
| 494 | Un «Sí» para emitir dispara un descuento no pedido | A | ¿? | Ambos |
| 462 | Aplica el descuento y no dice la cifra | A | PROD | Parcial ✱: «PRECIO ORIGINAL» fijo pedido a Juan; la respuesta a la protesta, pendiente en n8n |
| 340 | Re-anuncia como nuevo un descuento ya entregado | A | PROD | PROD ✱ parcial (viaje 6: textos K); el grafo pendiente |
| 312 | El carril no se puede probar con sesiones sintéticas | A | STG | — |
| 233 | Un turno rechazado por control muere sin rastro | A | PROD | — |
| 497 | Las entregas del PDF con descuento no guardan el wamid (46/46) | A | PROD | — |
| 343 🔴 | Un «Tomar conversación» de 4 s mata el descuento | J | STG | — |
| 305 🔴 | Una recotización a medias secuestra la conversación | J | PROD | — |
| 304 | Una adquisición genera varios Lead | J | PROD | Parcial |
| 303 | Recordar al que ya tiene el 40 % que caduca hoy | J | Ambos | — |
| 301 | Alinear la regla 20 % → 40 % → nada | J | PROD | Parcial |
| 266 | «¿Cuánto ahorro?» exige elegir cobertura antes | J | PROD | — |
| 205 | Segunda oferta idéntica con la primera viva | J | Ambos | Parcial |
| 351 | La cotización con descuento no rearma recordatorios | J | Ambos | — |
| 400 | Texto terminal «Avanzamos?» del estado `uncertain` | J | PROD | — |
| 401 | Retomar aplicaciones `uncertain` al volver Quálitas | J | PROD | — |
| 574 | Botón viejo de una oferta vencida → respuesta muerta: renovar la oferta en Django y retomar (nuevo, 8 oct) | J + A | PROD | — |

## 2. Emisión: que la póliza salga con los datos correctos (6)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 593 | La serie de la foto que no casa con el auto cotizado se descarta en silencio: el bot la vuelve a pedir ✱ | A | PROD | STG ✱ (bot `676069a3`: nota `[SERIE_FOTO_NO_CUADRA]` con el texto aprobado; 3/3 + vivo 1/1, control 0/1) |
| 475 | VIN tecleado con formato inválido: motivo engañoso y bucle; el modelo afirma «ya tengo tu número de serie» sin guardarla ✱ | A | PROD | STG ✱ (bot `f0b69aee`: O→0 e I→1 pendientes de confirmar, nota de longitud, `aviso_serie` con el motivo real; textos de una I y de varias letras derivados, a revisar por Alberto) |
| 543 | Póliza vencida tratada como renovación | A | PROD | STG ✱ (bot `387fee41` / Guard `b46c8d48`: R0, a0 con enlace (texto a firma), b2 S y c2 S con «no es nuestra» comprobado por serie, y la pausa al bloquear; 21/21); a1/a2 esperan el `#566` |
| 534 | TipoRegla 70/31 en el XML de Quálitas | J | Ambos | Parcial |
| 307 🔴 | La barrera del estado de póliza depende del Intent Router | J | Ambos | — |
| 280 | Emisión web en STG no completa | J | STG | — |

## 3. Cobro: liga de pago, recibos y recordatorios (9)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 597 | Del pago a los documentos pasan ~3 h: los clientes desconfían (Montserrat, Hylant) ✱ | J | PROD | — (medido: la orden se crea a la hora en punto y el envío sale cada 2 h a las :15; mediana de 135 min) |
| 583 | Diagnóstico de la derivación previa al enlace de pago (OPL) | J | ¿? | — |
| 289 | `payment-link/ensure` no distingue «sin liga» de «pagada» | A | Ambos | PROD ✱ (viaje 2); el caso «ya pagada» se acredita con la primera póliza pagada real |
| 329 | El cron de ligas no reintenta (costó una venta) | J | PROD | — |
| 364 | Recuperación cross-day de Payment Links | J | PROD | — |
| 362 | Deduplicar snapshots del ledger | J | ¿? | — |
| 231 | Ledger como fuente de verdad: grants | J | PROD | — |
| 353 | Versionar `n8n_payment_events` y grants | A | ¿? | — (el paquete `088981f6` de Juan, en la cola de la sesión A) |
| 144 | Recordatorios de pago D-7/48h/24h/día D | J | ¿? | — |

## 4. Postventa: el cliente que ya compró (1)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 566 | Atenderle con su póliza y sus pagos, sin llevarle a cotizar | J + A | PROD | — |

## 5. Recovery y cobranza vencida: campañas salientes (8)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 551 | GO funcional mínimo de Recovery | A | PROD | Parcial ✱: **E2E de Recovery completo en STG** (10 oct, Alberto: plantilla → PDF con el 30 % → precarga → póliza `7620104157`); falta el viaje coordinado con Juan. Defecto de forma: la pregunta del resumen va al principio (a firma) |
| 481 | El carril Recovery envía sin el fence de salida | A | STG | STG |
| 394 | Precotizar cada participante | A | STG | Parcial |
| 359 | Dashboard: importar la Excel de Cobranza Vencida | A | ¿? | STG ✱ (el consumidor de `leads/bulk` en `stg` `fa183a8`, 891/891); **bloqueado**: Excel v2 + consentimiento (Hylant) y token de owner de STG (Juan) |
| 360 | El bot descarta los mensajes del segundo número | A | PROD | STG |
| 385 | `retomar_en_fecha` y plantilla Recovery en Meta | J | STG | Parcial |
| 357 | Iniciativa Cobranza Vencida | J | ¿? | — |
| 356 | No existe registro de «no contactar» | J | PROD | — |

## 6. Qué dice el bot: contenido, cifras y respuestas (7)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 610 | Un «Ok gracias» o una frase ambigua guarda la cobertura y pasa a pedir datos (`Save_Quotation_Selection` sin aceptación) ✱ | A | PROD | — (propuesta: una guarda del grafo que exija aceptación explícita, como con el VIN) |
| 609 | Un recibo de luz como comprobante de domicilio se clasifica como comprobante de pago ✱ | A | PROD | STG ✱ (`02ed57c1`: tipo `comprobante_de_domicilio`, el domicilio se ofrece y se guarda solo con confirmación; si el CP es otro, se aplica el `#608`); a PROD con orden |
| 594 | Iniciativa: la póliza actual del lead (foto o PDF) → nodo especialista que la lee, comparador y argumento ✱ | A | PROD | — (diseño en `docs/iniciativas/2026-10-10-poliza-del-lead-…`; esperan las fuentes de los dos «número 1») |
| 592 | 12 meses sin intereses: tope del 30 % de descuento en CUALQUIER póliza; la KB lo limita a negocios especiales y el bot ofrece 12 MSI tras descuentos ✱ | A | PROD | — (espera a Hylant: ¿nuestros 20/30/40 % cuentan? El texto D de la llamada, bloqueado para PROD) |
| 461 | Ofrece Cobertura Limitada sin que la pidan (67/81) | A | PROD | PROD ✱ (viaje 6, bot `26dfbb82`: textos firmados en el prompt); el grafo (Limitada solo con permiso) pendiente |
| 499 | Salida vacía del agente: mensaje sin contestar | A | ¿? | Ambos |
| 486 | Análisis de coherencia del system prompt (informe) | A | ¿? | STG ✱ (bot `2cf93cb6`: paquete 3-4-6-8-9-10-11-14, solo el systemMessage del AI Agent; arnés N=20 80/80 con el cambio y 80/80 el control: quita incoherencias latentes, no cambia lo medido; 3, 4 y 14 sin ejercitar) |

## 7. Seguimientos y cierre de conversación (10)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 596 | Textos de urgencia para clientes dormidos y tras el descuento o la pausa (Montserrat, Hylant) | A | PROD | Parcial: STG (bot `c39407d1`) el texto 3 de la pausa, con y sin descuento (sin 12 MSI hasta el `#592`), y fuera la única promesa de «hoy» del prompt; texto 2 aparcado para la sesión B; los de Django, pedidos a Juan |
| 586 | «Cancelar» al seguimiento «¿Avanzamos?»: el agente cierra la sesión y manda el enlace del especialista ✱ | A | PROD | **PROD ✱** (`dcfb7a13`: B → A → silencio, sin enlace ni cierre); **solo falta la pausa de los seguimientos**, que espera el `reason` de Juan |
| 285 🔴 | Teléfono sin sesión viva → cliente sin respuesta | A | Ambos | STG ✱ (bot `03b09269`), **en pausa**: Juan propone una solución más sencilla |
| 542 | Tras declinar o derivar, el seguimiento insiste | A | PROD | — |
| 464 | Tras derivar por VIN con póliza, los checkpoints siguen | A | PROD | STG ✱ (cubierto por el cableado del `#577`) |
| 567 | «Te lo mando en la tarde» y los recordatorios insisten a los 30 min | A | PROD | Firmado; la pausa de seguimiento, propuesta a Juan (`#578`) |
| 223 | Iniciativa: hablarle en la fecha que pide | J | ¿? | — |
| 163 | Invalidar seguimientos de la cotización origen | J | STG | STG |
| 124 | `quote_followup_15m` para mensuales y anuales | J | PROD | — |
| 577 | Dejar de mandar checkpoints cuando el bot ya dijo que no se puede emitir y derivó | A | PROD | STG ✱ (Django `#600` + n8n: bot `cd512e34` / Guard `c31a3c54`; el PUT de pausa solo al derivar con la marca); falta que Juan confirme en Django |

## 8. Guardarraíl antijailbreak (0)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|

## 9. Identidad, sesiones y control humano (5)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 556 | 458 sesiones legacy sin `lead_id` → `identity_contradiction` | J | PROD | — |
| 346 | `whatsapp_sessions` no guarda quién creó la fila | J | Ambos | — |
| 128 | Control humano ↔ IA: redefinición de estados | J | Ambos | Parcial |
| 361 | Persona con muchos leads | J | PROD | — |
| 78 | Leads duplicados por envío múltiple del formulario | J | PROD | — |

## 10. Trazabilidad e historial (4)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 183 | La emisión con éxito no queda en el historial | A | STG | — |
| 126 | Capturar estados de entrega de Meta | A | ¿? | — (veredicto del 25 ago: failed y delivered; duda de diseño en la cola de la sesión A) |
| 127 | Persistir y mostrar estados de entrega | J | ¿? | — |
| 276 | `fecha_actualizacion` deja de registrar cambios | J | STG | — |

## 11. Infraestructura, seguridad y arquitectura (10)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 134 | Aislar n8n del owner | A | PROD | — |
| 238 | Desacoplar n8n de Postgres | A | Ambos | — |
| 526 | PDF de cotización públicos y con nombre predecible | J | PROD | — |
| 406 | Autenticar `/api/emitir-externo/` | J | PROD | — |
| 130 | `N8N_TOKEN` por defecto: rotar | J | PROD | — |
| 224 | Inventario de los dos schedulers de PROD | J | PROD | — |
| 157 | Django como steward del schema compartido | J | ¿? | — |
| 146 | Retirar mirrors y mutabilidad legacy | J | ¿? | — |
| 538 | Perf del gate pre-PROD | J | ¿? | Parcial |
| 131 | Runbook de quick reply desactualizado | J | ¿? | — |

## 12. Dashboard y su desacople (4)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 590 | El hito `dio_datos_personales` está muerto (0 de 1.869 mensajes en 21 días) ✱ | A | PROD | — (diseño aprobado: `asegurado OR grupo1` heredado; PROD 21 + 23 → 28; a `stg`) |
| 286 | Mapa del desacople del Dashboard | A | Ambos | — |
| 290 | Embudo por API, no por LIKE | J | Ambos | Parcial |
| 287 | Bandeja del contact center | J | ¿? | — |

## 13. Correos, documentos y Wagtail (3)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 441 | Logo de Quálitas en blanco en el PDF | J | ¿? | — |
| 560 | Reorganizar el detalle de Lead en Wagtail | J | ¿? | Parcial (PR #569 a `stg`) |
| 571 | Wagtail: seguimientos, Recovery y recordatorios en el perfil del Lead (nuevo) | J | ¿? | — |

---

## Movimientos del 10 oct

**Viaje 7 en PROD, verificado por el Arquitecto:** bot `1b869a0f`, Guard `3e196c7b`. Lleva `#472` (confirmación de la foto y
guardado de la serie), `#581` (imágenes que no son tarjeta, con el Dashboard en `d453998`), `#418` (despedidas), `#257` (número de
atención humana en `WA Config`), «Inicio de vigencia» y la pasarela caída. Antes del import se frenó y se arregló una regresión:
las imágenes sumaban al baneo por fuera de alcance.
**Cerrados:** el `#348` (Arquitecto, con el primer caso real de foto en PROD) y 8 en la auditoría final de Juan (`#259`, `#337`,
`#463`, `#473`, `#479`, `#552`, `#564`, `#570`).
**Nuevos:** `#579` (timeout de Django en descuentos), `#580` (fugas de razonamiento), `#581` (imágenes) y `#583` (Juan, OPL).
**En STG:** Recovery con la precarga del contexto (`#551`), Sonnet 5.5 en pruebas, el `#580` diseñado y la petición de llamada
firmada (textos A, B, B sin descuento, C y D).
**Noche:**
- **Revisión de PROD de Mejoras** (tras los viajes 6 y 7): no hay regresiones, pero solo hay 13 sesiones reales. L1 sale literal y c1 parafraseado. El viaje 7 sigue sin un solo caso real.
- **Nuevos, medidos por el Arquitecto en PROD:**
  - `#585`: tras el descuento (`waq_4385`) el bot pasa a pedir datos sin cobertura guardada.
  - `#586`: el «Cancelar» del seguimiento (`waq_4383`) lo atiende el agente, que cierra la sesión y manda el enlace del especialista. El «Cancelar» del descuento sí sale por el carril determinista.
- **Dashboard:** el PDF del descuento está en PROD (`main` `313d375`, PR #33, Production READY). Falta la prueba con la #4379. El `#344` y el `#349` están en diseño.
- **`#486`:** el inventario del `systemMessage` vivo está encargado al Agente n8n (`handoffs/2026-10-10-486-inventario-prompt.md`), el último de su cola. No se toca nada sin la autorización de Alberto.

**Tarde y cierre:**
- **Cerrados (8), cada uno con la evidencia en su issue:**
  - `#496`: observación de la Limitada, con la fila 30 de PROD y el sha igual a la respuesta.
  - `#349` (GA4 fuera), `#344` (degradar por cadena) y `#345` (rutas en comentarios): en PROD, verificados en `main` y en Vercel.
  - `#545`: RFC de Prado → `PALJ880315`, aceptado por el QA de Quálitas.
  - `#469`: par bueno/roto del VIN tecleado.
  - `#245`: los dos controles.
  - `#588`: 17 vectores de la KB regenerados en PROD.
- **Nuevos:**
  - `#587`: Meta, el 500 de `template_ids`.
  - `#589`: router de pagos.
  - `#590`: hito muerto del Dashboard.
  - `#591`: el guardarraíl de emisión solo reconoce `76200`.
- **Dos sesiones del Agente n8n:** A integra y B construye los descuentos (`#585`, `#579`, `#340`). El protocolo está en `Agente-n8n:handoffs/2026-10-10-protocolo-dos-constructores.md`.
- **Recovery (`#551`):** E2E completo en STG con la póliza `7620104157`.
- **En la bandeja de firmas:** el mensaje de emisión (fraccionado y sin link) y el orden de la pregunta del resumen.
- **Sonnet 5.5:** no bloquea por los detectores («emitida exitosamente» 5/5; PROD 13/13). Falta la orden de Alberto.

**Noche (cont.):**
- **En PROD:** `#333` (KB, viaje 1) y `#589` (bot `1b869a0f` → `c31d2687`, solo `Intent Router`). Cerrados.
- **Nuevo `#592`:** los términos de Quálitas ponen un tope del 30 % a los 12 MSI en cualquier póliza. Se pregunta a Hylant. La llamada está en STG (`5adf0e57`) con D bloqueado para PROD.
- **`#591` v2** en STG y en la bandeja de firmas.
- **`#587`:** causa medida y arreglo aprobado. **`#590`:** diseño aprobado.
- **Trabajo nocturno lanzado:** n8n·A (`#486`, `#461`, `#475`), QA (llamada, `#591` con emisión y regresión 5.5), Mejoras (`#586`, `#543`) y Dashboard (`#587`, `#590`).

- **Mejoras (nocturno):** los textos del `#586` (A/B) y del `#543` (a0, b2 y c2) están en la bandeja de firmas. Los seguimientos tras un error 41 van al `#577`.

- **`#587`** en el `stg` del Dashboard (`ecd7719`), verificado por mí: el Preview carga Meta con 200.

- **Prueba de Alberto en PROD** (Camry, #4394 → #4395): **8 issues cerrados** con su caso real (Texas, deducible, contado, ISSFAM → descuento del 30 %, PDF sin URL inventada, imagen que no es tarjeta, despedida D2 y número de atención humana en `WA Config`). Salieron dos defectos: `#593` (nuevo) y el `#475` (VIN con O: «ya tengo tu número de serie» falso y bucle). El `#472` y el `#563` quedan sin ejercitar: la tarjeta era de otro auto.

- **Iniciativa nueva `#594`** (Alberto): leer la póliza actual del lead (foto o PDF) con un **nodo especialista**, compararla con nuestra cotización (comparador determinista) y argumentar. Espera las fuentes citables de «Quálitas número 1 en autos» y de la atención de siniestros.

- **`#591` v2:** el control positivo con una emisión real en STG pasa. Listo para PROD con la firma de Alberto. **Sonnet 5.5** omite «exitosamente» en 2 de 2 emisiones reales en STG, así que no va a PROD sin el mensaje de emisión determinista.

- **14 oct:** Juan terminó la parte de Django del `#577` (PR #600, verificado en STG). El cableado de n8n (PUT de pausa antes de la derivación, que cubre también el `#464`) está encargado a la sesión A. La responsabilidad del `#577` pasa a Alberto.

- **14 oct:** entran el `#596` y el `#597` (Montserrat, Hylant): el `#596` asignado a Alberto (pasa por Mejoras) y el `#597` a Juan, con la causa medida (un proceso cada 2 h). Entra el `#605` (URL Fidelity Guard roto en STG, encontrado por la sesión A), que va antes del `#577`.

- **`#596`:** Mejoras midió que **«válido solo hoy» no es verdad** (cotizaciones emitidas al mismo precio hasta 35 días después; lo he confirmado). La decisión V/H y los tres textos están en la bandeja. Afecta también a la firma del `#567` («vence hoy») y a «DESCUENTO ADICIONAL para HOY». Nuevo caso del `#340` en `waq_4427`.

- **`#605` cerrado** (URL Fidelity Guard sin `URL`, en STG). **`#577`** cableado en STG (la marca en el Guard y el PUT al derivar), con el cambio exacto y la evidencia en el issue; falta la validación de Juan en Django.

- **`#606`** (lo detectó el Dashboard): los envíos huérfanos eran el corte de `Message Budget Guard` (límite de 10 en saludo), disparado por una **reacción** y por un «gracias» tras la despedida. Ese camino no escribe el historial. Historial y reacciones, encargados; el límite y el texto, a decisión de Alberto.

- **`waq_4420` (caso completo):** el bot prometió tres veces «te contacto» sin que nada lo cumpla. Texto a la firma («escríbeme a partir del…»); el caso se ha llevado al `#223` (recordatorio por fecha, bloqueado por la plantilla de Meta de Juan) y al `#567` (seguimientos tras pedir contacto).

- **Firmas:** 5 del 11 oct se quedaron sin atender hasta hoy (el Arquitecto no miró la bandeja) y 4 son de hoy. **El `#591` va a PROD.** Cola de STG para la sesión A: no prometer contacto, la pregunta del resumen al principio, `#586` B, `#543` S, emisión determinista (fraccionado + b1) y `#596` H.

- **`#591` cerrado en PROD** (`af2cbaee`, dos nodos, 84/84 emisiones reales pasan). Nuevo **`#607`** (un falso positivo con una explicación del proceso). **`#606` en STG.**

- **Paso 1 del plan de cierre (Alberto):** aprobados los textos del `#593` y el `#475`, el paquete de prompt del `#486` y la higiene (`#147` cerrado como no planificado; `#238` aparcada; `#126` y `#353` encargados; `#134` a hablar con Juan). Retención: el siniestro y la queja conservan la respuesta de hoy. `#607` v1.1 en verde en STG.

- **Caso de hoy en PROD (`waq_4442`, Camry):** el cliente iba a emitir con una colonia de un CP que no es el suyo, y Alberto avisó a Montserrat. Nuevos **`#608`** (no se puede recotizar con otro CP conservando el descuento) y **`#609`** (el recibo de la luz tomado por un comprobante de pago); el VIN de 16 caracteres, al `#475`.

- **`#472` cerrado** con el caso real `waq_4398` (12 oct): la guarda impidió guardar una serie de foto sin confirmar. Sin casos reales todavía: `#563` (carril de descuento con foto), `#494` (0 vetos), `#289` (1 pagada desde el 9 oct, sin pasar por la liga) y `#499`.

- **E2E del QA en STG** (`327de5ea`): **`#606`, no prometer contacto y el resumen pasan 3/3**, listos para el viaje. El **2.º «Cancelar» del `#586` falla** (Terminal Sink sin envío): arreglo encargado y no viaja.

- **`#587` cerrado en PROD** (Dashboard `1eda3e6`): el Resumen vuelve a cargar Meta. El despliegue en Vercel es de segunda mano: al Arquitecto se le caducó el token.

- **Día de viajes a PROD:** viaje 1, el **`#607`, cerrado** (PROD `af2cbaee` → `d3a660c2`, un nodo). Sigue el viaje 2 (`#606`).

- **Viaje 2: `#606` cerrado** (PROD `d3a660c2` → `97822428`). El inventario de cambios de los viajes 3 y 4 está revisado. En STG, el 2.º «Cancelar» del `#586` ya está arreglado (`29c034e1`).

- **Viaje 3: el resumen con la pregunta al principio, en PROD** (`97822428` → `5abccce9`, 3 hunks del prompt y `Rebuild Summary From Record`), verificado. Es el punto 1 del `#486` y la firma `resumen-orden-pregunta`.

- **Nuevo `#610`** (Mejoras): un «Ok gracias» guarda la cobertura sin aceptación (`waq_4419`, `waq_4447`). Pendiente de Alberto: si una **pausa** («voy a checarlo») debe abrir el carril de descuento, como pasa hoy en `waq_4451`, o recibir el gancho D2.

- **Viaje 4: no prometer contacto, en PROD** (`5abccce9` → `80fe1b49`: 2 hunks del AI Agent, el `vuelve_desde` en el `[CTX:]`, la regla 14 del RAG y el límite de 30 en `Merge Session Data`), verificado. El bot deja de prometer «te contacto» (caso `waq_4420`). Sigue el viaje 5 (`#580`).

- **Viaje 5: `#580` cerrado** (PROD `80fe1b49` → `4b9eaf42`, solo `Outbound Leak Guard`, sin la frase D). **El día de viajes termina:** `#607`, `#606`, resumen, no prometer contacto y `#580` en PROD, los cinco verificados por el Arquitecto. PROD queda en `4b9eaf42`.

- **`#586` verde en STG** (QA C 3/3 sobre `ae699fe9`/`1e11ea53`), listo para PROD con orden de Alberto. STG descongelado (adenda 9).

- **`#608` y `#609` en STG** (bot `02ed57c1`), verificados por el diff; el siguiente en la cola es la retención con su adenda 1.

- **15 oct: el `#586` en PROD** (`4b9eaf42` → `dcfb7a13`), verificado, con la cadena del «no» hasta `IF Identity Intent?`. Solo queda la pausa (Juan).

- **`#543` S en STG** (bot `387fee41`, Guard `b46c8d48`). a0 lleva el enlace; su texto está a la firma.

- **Mensaje de emisión determinista en STG** (bot `387fee41` → `820c08d4`): el grafo compone «emitida exitosamente» con la fila de `qualitas_polizaemitida` del turno y la liga de la API (contado, fraccionado y b1 sin liga); `URL Fidelity Guard` admite esa liga. Arnés 30/30, a mitad de turno 12/12, vivo 6/6. Nodos y cableado comprobados por el Arquitecto en el vivo de STG. **A PROD necesita orden de Alberto (toca emisión)**. Sin ejercitar: emisión real contra Quálitas QA y la respuesta de la API de liga en PROD justo tras emitir.

## Movimientos del 16 oct

- **`#612` nuevo (alto, A, PROD):** un «gracias» en `data_capture` muere en `Update Phase in DB` (`there is no parameter $4`) y el cliente no recibe respuesta. Lo trajo el viaje 2 del 14 oct (adenda 1 del `#606`) y **sigue en PROD `dcfb7a13`**. Arreglo en STG (`queryReplacement` como array; vivo `676069a3`, comprobado por el Arquitecto); el viaje lleva un solo nodo. Sin caso real medible: PROD no guarda las ejecuciones con error.

- **En STG, con informe:** `#596` (texto 3 de la pausa), `#475` (serie tecleada) y `#593` (serie de la foto que no cuadra). Bot STG `676069a3`.

- **`#486` (paquete de prompt) en STG** (bot `676069a3` → `2cf93cb6`). Comprobado por el Arquitecto contra el export anterior: solo cambia el systemMessage del `AI Agent` (12 bloques contiguos de diff para los 14 hunks del informe), conexiones idénticas. La cola de la sesión A queda vacía; el `#126`, aparcado hasta el contrato de Juan.

---

## Movimientos del 9 oct

**A PROD, verificado por el Arquitecto:** `#544` (base de conocimiento sobre EUA y Canadá: el 113 reescrito con la RC por
el endoso de bienvenida, el 43 retirado y el 114 con la excepción). Validado por Alberto desde su teléfono en STG.

**Firmas de Alberto:** las diez propuestas firmadas (`docs/estado/2026-10-09-firmas-de-alberto.md`). El paquete de prompt
está en STG (bot `94e85a8c`), con la base del RFC calculada por el grafo. **No viaja a PROD hasta que esté al 100 % en
STG** (decisión de Alberto). Quedan dos defectos previos por arreglar en STG: la pregunta repetida sobre la aseguradora
y que el bot enseña al cliente su cálculo del límite de 30 días.

**Cerrados:** `#565` (frase de las 24 h fuera del bot en PROD), `#178` (paridad de docs en Agente-n8n, PR #110) y `#398`
(duplicado del `#134`).
**En pausa:** `#285`, completo en STG, a la espera de la propuesta de Juan.
**Nuevo:** `#577` (Juan), dejar de mandar checkpoints tras una derivación. El `#464` espera su decisión.
**Pedido a Juan en el `#462`:** que el «PRECIO ORIGINAL» del PDF sea fijo (sale de la primera cotización, no se recalcula).
**Prioridades de Juan:** `#578`, con el orden que propone Alberto.
**Firmas:** la página [Firmas del bot](https://claude.ai/artifact/G4D8psUfUYCYFbSMeheHs9) queda como bandeja permanente:
cada propuesta nueva entra allí, con su caso real.

---

## Movimientos del 8 oct

**A PROD, verificado en vivo por el Arquitecto** (acuses en `informes/2026-10-0{8,9}-n8n-prod-viaje-*-acuse.md`):

| Viaje | Issues | PROD queda en |
|---|---|---|
| 2 | `#552`, `#289` | bot `fe9c5213` |
| 1 | `#563`, `#472`, `#348` (y el lector que acredita el `#469`) | bot `b7caf68b` |
| 3 | `#325`, `#463`, `#479`, `#570` | bot `458024c6` |
| 4 | `#545` (la parte del grafo) | Issue Policy Guard `9aa96337` |
| 5 | `#496`, `#565` | bot **`9c813fc3`** |

**Nuevos:** `#570` (memoria del guardarraíl, ya en PROD), `#571` (Wagtail, Juan) y `#574` (botón viejo de una oferta
vencida; propuesta de renovación en Django enviada a Juan).
**Cerrados por Juan:** `#554` y `#568`. **Juan ha fusionado a `stg`:** PR #569 (`#560`), #572 (`#568`) y #573 (contrato v2 de Recovery).

---

## Plan para seguir corrigiendo (propuesta del 8 oct)

### Fase 0 — Cerrar lo que ya está hecho (Arquitecto, sin coste)
- **Ya:** `#565` (la frase aparece 0 veces en PROD).
- **Con el primer caso real de PROD**, que vigila `vigia-cierres.sh`: la foto (`#563`, `#472`, `#469`, `#348`), la liga
  (`#552`, `#289`), el guardarraíl (`#325`, `#463`, `#479`, `#570`), la Limitada (`#496`) y la primera emisión con RFC
  calculado (la parte del grafo del `#545`).
- **Siguen esperando su caso real** desde antes: `#494`, `#456`, `#313`, `#270`, `#245`, `#499`.

### Fase 1 — Sesión de firmas (Alberto, unos 30 min)
Propuestas listas en `informes/2026-10-07-textos-para-firma-461-418-261-543-340.md`: `#461`, `#418`, `#261`, `#543` y `#340`.
Además: el C9 del `#553`, el texto «sin humano» del `#257`, la línea del RFC del `#545`, el correo bajo pregunta del
`#473` (ya en STG) y la contradicción del número 5537511678 en la regla RENOVACIÓN.
**Desbloquea un viaje de prompt (6) y uno de grafo para `#261`/`#257` (7).**

### Fase 2 — n8n sin firma, a STG de uno en uno (Agente n8n + QA con tu teléfono)
| Orden | # | Por qué ahora |
|---|---|---|
| 1 | `#285` 🔴 | Teléfono sin sesión viva → el cliente se queda sin respuesta. Tu decisión del 5 oct ya está tomada (contestar al que escribe, no iniciar) |
| 2 | `#464` (alto) | Tras derivar por VIN con póliza activa, los checkpoints siguen. Repetido en PROD el 3 oct |
| 3 | `#462` (alto) | El descuento se aplica y no se dice la cifra. Hay un paquete parcial en STG |
| 4 | `#544` (alto) | El fragmento 43 de la KB contradice la Cláusula 9ª (RC en EUA/Canadá): es una corrección de dato |
| 5 | `#542`, `#233`, `#475` | Seguimiento tras declinar, turno rechazado sin rastro, VIN válido rechazado |
| — | `#574` (parte n8n) | En cuanto Juan fije el contrato de renovación |
| — | `#347` | Medido: en mi población son leads que cerraron por web, no pérdidas. Propongo cerrarlo con esa evidencia |

### Fase 3 — Lo de Juan (yo lo redacto y se lo mando; el orden lo fijas tú)
- 🔴 `#305` (una recotización a medias secuestra la conversación), `#343` (un «Tomar conversación» de 4 s mata el
  descuento) y `#307` (la barrera del estado de póliza depende del Intent Router).
- **Seguridad:** `#406` (`/api/emitir-externo/` sin autenticar), `#526` (PDF públicos y con nombre predecible) y `#130`
  (rotar el token).
- **Venta:** `#574` (renovar oferta vencida), `#551` (campaña Recovery a un participante limpio), `#329` (el cron de
  ligas no reintenta: costó una venta) y `#301`/`#303`/`#304` (regla de descuentos).
- `#356` (registro de «no contactar»): **bloquea** cualquier campaña saliente nueva.

### Fase 4 — Higiene del tracker
- Duplicados: `#134` ↔ `#398` (n8n como owner de PROD). `#126` ↔ `#127` son un par n8n/Django: enlazarlos.
- `#567` sin responsable. `#128`: acordar su cierre con Juan. `#497` aparcado a la espera de su respuesta.
- Docs: `#178` y `#131`.
- Iniciativas que no son bugs (`#238`, `#286`, `#147`, `#157`, `#146`, `#144`, `#223`, `#357`): moverlas a una columna
  «Iniciativas» del Project para que no se mezclen con los fallos.

**Decisiones que te tocan:** (1) cuándo hacemos la sesión de firmas; (2) el orden de la lista de Juan; (3) si se cierra
el `#347` con la medición.

---

## Cerrados el 7 oct (16), cada uno con su comentario de evidencia medida

| # | Qué | Cómo |
|---|---|---|
| 492 | Issue Policy omite el email | Resuelto: 5 emisiones reales posteriores con el correo correcto; 0 errores «Faltan campos: email» después del arreglo |
| 471 | Placas «opcionales» | Resuelto: guarda en PROD desde el 25 sep; 5 emisiones reales con placas válidas |
| 476 | El pie de foto no llega al agente | Resuelto: 4 pies de foto reales llegan al modelo y el bot los usa |
| 466 | La IA sobrescribe el correo canónico | Resuelto: defensa n8n (25 sep) y fence Django en PROD desde la v425; 0 de 11 pólizas con correo distinto |
| 536 | La emisión toma los datos del modelo | Resuelto: póliza 7620103949 con datos e importe iguales a la cotización |
| 530 | Mensaje durante el aviso de descuento cruza respuestas | Resuelto: caso real `waq_4338` |
| 528 | «ok» durante el descuento guarda una cobertura | Resuelto: caso real, aplicación 117 |
| 243 | Cotización vieja durante el descuento | Resuelto: 8 actuaciones reales de la guarda; 0 respuestas del agente en vuelo |
| 342 | Mensajes del cliente sin fila en el historial | Resuelto: 234 filas `client_message_342` |
| 339 | El anuncio del descuento no anuncia nada | Resuelto: caso real, cotización 4336 |
| 207 | El bot no entrega la liga de pago | Resuelto: dos casos `available` reales, pólizas pagadas |
| 500 | La guarda de cifras corta decimales | Resuelto **con salvedad**: ninguna cifra real ha dependido solo de `fuentesB` |
| 328 | «Sin costo extra» al trimestral | Resuelto **con salvedad**: las frases literales de prueba no se han dado en PROD |
| 405 | Sesión propuesta para Recovery | Superado por el `#551`: la parte Django está en PROD |
| 190 | Recotizar a Limitada | Superado: la Limitada viene en el 100 % de las cotizaciones; caso real `waq_4344` |
| 206 | Ofrece la Limitada sin pedirla | Duplicado del `#461`, al que se copió su criterio |

## Barrido de cierre del 7 oct: medidos en vivo y NO cerrables todavía

Se midieron en vivo los 35 issues con algún arreglo declarado. Estos siguen abiertos, con lo que les falta:

| # | Qué falta |
|---|---|
| 494, 469, 456, 313, 270, 245, 499 | El arreglo está vivo en PROD, pero aún no ha habido el caso real que lo acredite |
| 472 | PROD ✱ (viaje 7: «Están bien» y guardado determinista de la serie); falta el caso real |
| 475 | El marcador `[SERIE_FORMATO]` no existe ni en STG ni en PROD |
| 473, 462 | El cambio principal sigue solo en STG |
| 344 | Falta el dictamen de diseño: el guard sigue tumbando la respuesta entera |
| 340 | PROD ✱ parcial (viaje 6: textos K); el grafo pendiente |
| 304 | Los leads resultado siguen naciendo en `LEAD_CREADO`; no existe `CommercialLead` |
| 301 | En PROD solo está la regla 4. Siguen activos el 30 %, el VIN obligatorio para el 40 % y el tope 3 |
| 290 | `GET /api/v1/dashboard/funnel` no existe |
| 289 | PROD ✱ (viaje 2); el caso «ya pagada» se acredita con la primera póliza pagada real |
| 205 | Solo hay red en n8n; falta la regla en Django |
| 534 | No comprobable: falta que Quálitas confirme reportes y PDF |
| 128 | Superado en la práctica, pero es el tracker C7 de Juan (`#140`): acordarlo con él |

## Lo que destaca (de la foto inicial)

- **12 issues tienen el arreglo en los dos entornos** y siguen abiertos solo porque falta verlo funcionar en una
  conversación real: 270, 245, 344, 530, 528, 494, 500, 499, 536, 476, 471 y 554. Son candidatos a cerrarse en
  cuanto haya tráfico real que los acredite.
- **31 no dicen el entorno.** Casi todos son iniciativas o propuestas sin nada construido.
- **Hay datos viejos:** muchos issues de Juan tienen su último dato en agosto o principios de septiembre.

## Para limpiar el tracker (estado tras los cierres)

- ~~`#567` sin responsable~~ → asignado a Alberto el 8 oct (`#568` lo cerró Juan).
- ~~`#206` y `#461` son el mismo problema~~ → `#206` cerrado como duplicado.
- ~~`#405`~~ → cerrado como superado por el `#551`.
- ~~`#554`~~ → cerrado el 8 oct.
- **`#243`** tiene a la vez los labels `criticidad:alto` y `criticidad:critico`.

## Método

1. `gh issue list --state open` sobre `aguayo-co/HYL-WAI` (120 issues) y descarga de cada issue con todos sus
   comentarios.
2. Lectura repartida en tres lotes de 40. Por issue: tipo, entorno donde está presente el problema, estado del
   arreglo, fecha del último dato y cita literal que lo justifica. Siempre el último dato del hilo; `NO CONSTA` si
   el issue no lo dice.
3. Corrección con medición propia del 7 oct en los issues trabajados ese día (✱): `#563`, `#551`, `#405` y `#554`.
   Fuentes: API de n8n PROD y STG, git de HYL-WAI y releases de Heroku.
