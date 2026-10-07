# Issues abiertos de HYL-WAI por caso de uso y entorno — foto del 7 oct 2026 (actualizada tras los cierres)

**De:** Arquitecto-IA-Insurmind · **Para:** Alberto · **7 oct 2026**
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

## Totales

| Responsable | Issues |
|---|---|
| Alberto | 53 |
| Juan | 49 |
| Compartido (`#566`) | 1 |
| Sin asignar (`#567`, `#568`) | 2 |

| Problema en | Issues |
|---|---|
| PROD | 41 |
| Ambos | 26 |
| STG | 13 |
| No consta | 25 (incluye el `#568`, sin clasificar) |

| Arreglo | Issues |
|---|---|
| Sin arreglo | 73 (incluye el `#568`) |
| Parcial | 21 |
| En los dos entornos (falta acreditar) | 6 |
| Solo PROD | 1 |
| Solo STG | 4 |

---

## 1. Descuentos: ofrecer, aplicar y comunicar bien el descuento (22)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 563 | El carril vuelve a pedir el VIN confirmado por foto | A | PROD | STG ✱ (PROD sigue en `a5b88be9`, pendiente de la confirmación de Alberto en la sesión n8n) |
| 553 | Oferta de la competencia: pedir precio y cobertura | A | PROD | — |
| 494 | Un «Sí» para emitir dispara un descuento no pedido | A | ¿? | Ambos |
| 462 | Aplica el descuento y no dice la cifra | A | PROD | Parcial |
| 456 | Convenio ISSFAM/gubernamental → carril de descuentos | A | Ambos | Parcial |
| 340 | Re-anuncia como nuevo un descuento ya entregado | A | PROD | Parcial |
| 313 | «¿Descuento si pago de contado?» abre un escalón | A | Ambos | Parcial |
| 312 | El carril no se puede probar con sesiones sintéticas | A | STG | — |
| 270 🔴 | «Me cotizaron más barato» se clasifica no_match | A | Ambos | Ambos |
| 233 | Un turno rechazado por control muere sin rastro | A | PROD | — |
| 497 | Las entregas del PDF con descuento no guardan el wamid (46/46) | A | PROD | — |
| 343 🔴 | Un «Tomar conversación» de 4 s mata el descuento | J | STG | — |
| 305 🔴 | Una recotización a medias secuestra la conversación | J | PROD | — |
| 304 | Una adquisición genera varios Lead | J | PROD | Parcial |
| 303 | Recordar al que ya tiene el 40 % que caduca hoy | J | Ambos | — |
| 301 | Alinear la regla 20 % → 40 % → nada | J | PROD | Parcial |
| 266 | «¿Cuánto ahorro?» exige elegir cobertura antes | J | PROD | — |
| 259 | Tras el PDF con descuento no se dice nada | J | STG | — |
| 205 | Segunda oferta idéntica con la primera viva | J | Ambos | Parcial |
| 351 | La cotización con descuento no rearma recordatorios | J | Ambos | — |
| 400 | Texto terminal «Avanzamos?» del estado `uncertain` | J | PROD | — |
| 401 | Retomar aplicaciones `uncertain` al volver Quálitas | J | PROD | — |

## 2. Emisión: que la póliza salga con los datos correctos (9)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 472 🔴 | Persiste datos del vehículo no confirmados y pasan a la póliza | A | ¿? | PROD |
| 469 🔴 | VIN de foto mal leído y nadie lo comprueba | A | PROD | Parcial |
| 545 | La regla del RFC calcula RFC inválidos (dos consonantes) | A | Ambos | — |
| 475 | Rechaza VINs válidos inventando errores | A | ¿? | Parcial |
| 543 | Póliza vencida tratada como renovación | A | PROD | — |
| 348 | Extract VIN Vision en un modelo de hace una generación | A | Ambos | — |
| 534 | TipoRegla 70/31 en el XML de Quálitas | J | Ambos | Parcial |
| 307 🔴 | La barrera del estado de póliza depende del Intent Router | J | Ambos | — |
| 280 | Emisión web en STG no completa | J | STG | — |

## 3. Cobro: liga de pago, recibos y recordatorios (9)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 552 | «Mándame la liga» antes de emitir deja sin camino | A | Ambos | — |
| 565 | Quitar «El link expira en 24 horas» | A | Ambos | — |
| 289 | `payment-link/ensure` no distingue «sin liga» de «pagada» | A | Ambos | Parcial |
| 329 | El cron de ligas no reintenta (costó una venta) | J | PROD | — |
| 364 | Recuperación cross-day de Payment Links | J | PROD | — |
| 362 | Deduplicar snapshots del ledger | J | ¿? | — |
| 231 | Ledger como fuente de verdad: grants | J | PROD | — |
| 353 | Versionar `n8n_payment_events` y grants | J | PROD | — |
| 144 | Recordatorios de pago D-7/48h/24h/día D | J | ¿? | — |

## 4. Postventa: el cliente que ya compró (1)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 566 | Atenderle con su póliza y sus pagos, sin llevarle a cotizar | J + A | PROD | — |

## 5. Recovery y cobranza vencida: campañas salientes (9)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 551 | GO funcional mínimo de Recovery | A | PROD | Parcial ✱ (carril n8n en STG `c432ef1c`; en PROD, 0 nodos) |
| 481 | El carril Recovery envía sin el fence de salida | A | STG | STG |
| 394 | Precotizar cada participante | A | STG | Parcial |
| 359 | Dashboard: importar la Excel de Cobranza Vencida | A | ¿? | — |
| 360 | El bot descarta los mensajes del segundo número | A | PROD | STG |
| 564 | Prima de la póliza anterior en `previous_policy` | J | PROD | — |
| 385 | `retomar_en_fecha` y plantilla Recovery en Meta | J | STG | Parcial |
| 357 | Iniciativa Cobranza Vencida | J | ¿? | — |
| 356 | No existe registro de «no contactar» | J | PROD | — |

## 6. Qué dice el bot: contenido, cifras y respuestas (10)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 261 🔴 | Fabrica la URL de un documento que no existe | A | STG | — |
| 461 | Ofrece Cobertura Limitada sin que la pidan (67/81) | A | PROD | — |
| 544 | La KB dice que la RC cubre en EUA/Canadá | A | PROD | — |
| 499 | Salida vacía del agente: mensaje sin contestar | A | ¿? | Ambos |
| 473 | Se niega a decir el correo registrado | A | PROD | Parcial |
| 418 | No reconoce la despedida y re-oferta | A | PROD | — |
| 245 | «No pude recuperar tu cotización» con la cotización devuelta | A | Ambos | Ambos |
| 486 | Análisis de coherencia del system prompt (informe) | A | ¿? | — |
| 333 | La KB excluye conducir sin licencia (solo aplica a Chofer APP) | J | Ambos | — |
| 337 | Exponer el valor convenido para contestarlo | J | Ambos | Parcial |

## 7. Seguimientos y cierre de conversación (7)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 285 🔴 | Teléfono sin sesión viva → cliente sin respuesta | A | Ambos | — |
| 542 | Tras declinar o derivar, el seguimiento insiste | A | PROD | — |
| 464 | Tras derivar por VIN con póliza, los checkpoints siguen | A | PROD | — |
| 567 | «Te lo mando en la tarde» y los recordatorios insisten a los 30 min | sin asignar | PROD | — |
| 223 | Iniciativa: hablarle en la fecha que pide | J | ¿? | — |
| 163 | Invalidar seguimientos de la cotización origen | J | STG | STG |
| 124 | `quote_followup_15m` para mensuales y anuales | J | PROD | — |

## 8. Guardarraíl antijailbreak (3)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 463 | Si el guardarraíl falla, banea al cliente | A | STG | — |
| 479 | Escanea texto del sistema como si fuera del cliente | A | Ambos | — |
| 325 | Una pregunta del deducible lo reventó | A | STG | Parcial |

## 9. Identidad, sesiones y control humano (6)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 147 | Separar identidad, lifecycle, autoridad y reservas | A | ¿? | — |
| 556 | 458 sesiones legacy sin `lead_id` → `identity_contradiction` | J | PROD | — |
| 346 | `whatsapp_sessions` no guarda quién creó la fila | J | Ambos | — |
| 128 | Control humano ↔ IA: redefinición de estados | J | Ambos | Parcial |
| 361 | Persona con muchos leads | J | PROD | — |
| 78 | Leads duplicados por envío múltiple del formulario | J | PROD | — |

## 10. Trazabilidad e historial (6)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 347 | 17 leads con póliza sin una fila de conversación | A | PROD | — |
| 183 | La emisión con éxito no queda en el historial | A | STG | — |
| 496 | Observaciones de la fase 1 truncadas en la primera coma | A | Ambos | — |
| 126 | Capturar estados de entrega de Meta | A | ¿? | — |
| 127 | Persistir y mostrar estados de entrega | J | ¿? | — |
| 276 | `fecha_actualizacion` deja de registrar cambios | J | STG | — |

## 11. Infraestructura, seguridad y arquitectura (13)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 398 | n8n se conecta a PROD como owner | A | PROD | — |
| 134 | Aislar n8n del owner | A | PROD | — |
| 238 | Desacoplar n8n de Postgres | A | Ambos | — |
| 257 | Número de atención humana escrito a mano en 8 nodos | A | Ambos | — |
| 178 | Docs divergentes entre stg y main | A | ¿? | Parcial |
| 526 | PDF de cotización públicos y con nombre predecible | J | PROD | — |
| 406 | Autenticar `/api/emitir-externo/` | J | PROD | — |
| 130 | `N8N_TOKEN` por defecto: rotar | J | PROD | — |
| 224 | Inventario de los dos schedulers de PROD | J | PROD | — |
| 157 | Django como steward del schema compartido | J | ¿? | — |
| 146 | Retirar mirrors y mutabilidad legacy | J | ¿? | — |
| 538 | Perf del gate pre-PROD | J | ¿? | Parcial |
| 131 | Runbook de quick reply desactualizado | J | ¿? | — |

## 12. Dashboard y su desacople (6)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 349 | Cadena GA4 sin consumidor | A | ¿? | — |
| 345 | Rutas muertas en comentarios | A | ¿? | — |
| 344 | Un lead ambiguo tumba la superficie de descuentos | A | Ambos | Ambos |
| 286 | Mapa del desacople del Dashboard | A | Ambos | — |
| 290 | Embudo por API, no por LIKE | J | Ambos | Parcial |
| 287 | Bandeja del contact center | J | ¿? | — |

## 13. Correos, documentos y Wagtail (4)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 554 | Contacto en «Tu seguro está activo» | J | ¿? | Ambos ✱ (en `main` y PROD desde la v431, pero esa plantilla no se envía) |
| 441 | Logo de Quálitas en blanco en el PDF | J | ¿? | — |
| 560 | Reorganizar el detalle de Lead en Wagtail | J | ¿? | — |
| 568 | Wagtail: mostrar diagnósticos fuera de los últimos 50 eventos (nuevo, 7 oct) | sin asignar | ¿? | — |

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
| 472 | N≥20 sin alcanzar. Además hay **3 rechazos falsos** de la barrera del VIN en PROD (`waq_3700`, `waq_3756`, `waq_4310`) |
| 475 | El marcador `[SERIE_FORMATO]` no existe ni en STG ni en PROD |
| 473, 462 | El cambio principal sigue solo en STG |
| 344 | Falta el dictamen de diseño: el guard sigue tumbando la respuesta entera |
| 340 | La segunda mitad (insistir cuando el cliente corrige) no tiene arreglo |
| 337 | Persistir la suma asegurada al emitir: hacerlo o descartarlo por escrito |
| 304 | Los leads resultado siguen naciendo en `LEAD_CREADO`; no existe `CommercialLead` |
| 301 | En PROD solo está la regla 4. Siguen activos el 30 %, el VIN obligatorio para el 40 % y el tope 3 |
| 290 | `GET /api/v1/dashboard/funnel` no existe |
| 289 | El consumidor n8n (PR #109 de Agente-n8n) sigue sin fusionar |
| 205 | Solo hay red en n8n; falta la regla en Django |
| 178 | `gotchas-n8n.md` diverge entre `main` y `stg` |
| 554 | Decisión de Alberto: contacto de Metepec en `first-receipt-policy-documents.html` |
| 534 | No comprobable: falta que Quálitas confirme reportes y PDF |
| 128 | Superado en la práctica, pero es el tracker C7 de Juan (`#140`): acordarlo con él |

## Lo que destaca (de la foto inicial)

- **12 issues tienen el arreglo en los dos entornos** y siguen abiertos solo porque falta verlo funcionar en una
  conversación real: 270, 245, 344, 530, 528, 494, 500, 499, 536, 476, 471 y 554. Son candidatos a cerrarse en
  cuanto haya tráfico real que los acredite.
- **31 no dicen el entorno.** Casi todos son iniciativas o propuestas sin nada construido.
- **Hay datos viejos:** muchos issues de Juan tienen su último dato en agosto o principios de septiembre.

## Para limpiar el tracker (estado tras los cierres)

- **`#567` y `#568`** no tienen responsable.
- ~~`#206` y `#461` son el mismo problema~~ → `#206` cerrado como duplicado.
- ~~`#405`~~ → cerrado como superado por el `#551`.
- **`#554`**: el arreglo cambia una plantilla que ya no se envía. El correo que sale hoy no lleva contacto.
- **`#243`** tiene a la vez los labels `criticidad:alto` y `criticidad:critico`.

## Método

1. `gh issue list --state open` sobre `aguayo-co/HYL-WAI` (120 issues) y descarga de cada issue con todos sus
   comentarios.
2. Lectura repartida en tres lotes de 40. Por issue: tipo, entorno donde está presente el problema, estado del
   arreglo, fecha del último dato y cita literal que lo justifica. Siempre el último dato del hilo; `NO CONSTA` si
   el issue no lo dice.
3. Corrección con medición propia del 7 oct en los issues trabajados ese día (✱): `#563`, `#551`, `#405` y `#554`.
   Fuentes: API de n8n PROD y STG, git de HYL-WAI y releases de Heroku.
