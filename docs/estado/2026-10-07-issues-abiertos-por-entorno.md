# Issues abiertos de HYL-WAI por caso de uso y entorno — foto del 7 oct 2026, actualizada el 8 oct

**De:** Arquitecto-IA-Insurmind · **Para:** Alberto · **7 oct 2026 · actualizado 8 oct 2026 (noche, CDMX)**

> **8 oct:** **106 abiertos**. Han entrado `#570`, `#571` y `#574`; se han cerrado `#554` y `#568` (Juan). Los viajes 1 a 5
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

## Totales (8 oct: 106)

| Responsable | Issues |
|---|---|
| Alberto | 54 |
| Juan | 49 |
| Compartido | 2 |
| Sin asignar | 1 |

| Problema en | Issues |
|---|---|
| PROD | 43 |
| Ambos | 26 |
| No consta | 24 |
| STG | 13 |

| Arreglo | Issues |
|---|---|
| Sin arreglo | 65 |
| Parcial | 20 |
| Solo PROD (falta caso real) | 12 |
| En los dos entornos (falta acreditar) | 5 |
| Solo STG | 4 |

---|---|
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

## 1. Descuentos: ofrecer, aplicar y comunicar bien el descuento (23)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 563 | El carril vuelve a pedir el VIN confirmado por foto | A | PROD | PROD ✱ (viaje 1, bot `b7caf68b`); falta la primera foto real |
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
| 574 | Botón viejo de una oferta vencida → respuesta muerta: renovar la oferta en Django y retomar (nuevo, 8 oct) | J + A | PROD | — |

## 2. Emisión: que la póliza salga con los datos correctos (9)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 472 🔴 | Persiste datos del vehículo no confirmados y pasan a la póliza | A | ¿? | PROD ✱ (viaje 1: regla sí/no/ambiguo y `aviso_serie`); falta N≥20 y revisar los 3 rechazos falsos |
| 469 🔴 | VIN de foto mal leído y nadie lo comprueba | A | PROD | PROD ✱ (viaje 1: lector `claude-sonnet-5` sobre la guarda determinista); falta el caso real |
| 545 | La regla del RFC calcula RFC inválidos (dos consonantes) | A | Ambos | Parcial ✱: la base la calcula el grafo (Issue Policy Guard PROD `9aa96337`, viaje 4); la línea contradictoria del prompt espera tu firma |
| 475 | Rechaza VINs válidos inventando errores | A | ¿? | Parcial |
| 543 | Póliza vencida tratada como renovación | A | PROD | — |
| 348 | Extract VIN Vision en un modelo de hace una generación | A | Ambos | PROD ✱ (viaje 1). Acreditado en STG con la foto girada de Alberto (ejecuciones 82479/82482); falta la primera foto real de PROD |
| 534 | TipoRegla 70/31 en el XML de Quálitas | J | Ambos | Parcial |
| 307 🔴 | La barrera del estado de póliza depende del Intent Router | J | Ambos | — |
| 280 | Emisión web en STG no completa | J | STG | — |

## 3. Cobro: liga de pago, recibos y recordatorios (9)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 552 | «Mándame la liga» antes de emitir deja sin camino | A | Ambos | PROD ✱ (viaje 2, `fe9c5213`); falta el caso real |
| 565 | Quitar «El link expira en 24 horas» | A | Ambos | PROD ✱ (viaje 5, `9c813fc3`): la frase aparece 0 veces. **Cerrable** |
| 289 | `payment-link/ensure` no distingue «sin liga» de «pagada» | A | Ambos | PROD ✱ (viaje 2); el caso «ya pagada» se acredita con la primera póliza pagada real |
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
| 551 | GO funcional mínimo de Recovery | A | PROD | Parcial ✱: contrato v2 en Django (PR #573, fusionado a `stg`) y en n8n STG; falta la campaña de Juan a un participante limpio y el viaje coordinado |
| 481 | El carril Recovery envía sin el fence de salida | A | STG | STG |
| 394 | Precotizar cada participante | A | STG | Parcial |
| 359 | Dashboard: importar la Excel de Cobranza Vencida | A | ¿? | — |
| 360 | El bot descarta los mensajes del segundo número | A | PROD | STG |
| 564 | Prima de la póliza anterior en `previous_policy` | J | PROD | STG ✱ (cubierto por el contrato v2 del `#551`, PR #573) |
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

## 8. Guardarraíl antijailbreak (4)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 463 | Si el guardarraíl falla, banea al cliente | A | STG | PROD ✱ (viaje 3, `458024c6`); falta el caso real |
| 479 | Escanea texto del sistema como si fuera del cliente | A | Ambos | PROD ✱ (viaje 3); falta el caso real |
| 570 | Los turnos del guardarraíl no quedan en la memoria del modelo | A | PROD | PROD ✱ (viaje 3); falta el caso real |
| 325 | Una pregunta del deducible lo reventó | A | STG | PROD ✱ (viaje 3: `onError` y `Guardrail Error Safe Reply`); falta el caso real |

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
| 496 | Observaciones de la fase 1 truncadas en la primera coma | A | Ambos | PROD ✱ (viaje 5): falta la primera observación real completa |
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

## 13. Correos, documentos y Wagtail (3)
| # | Qué resuelve | Resp. | Problema en | Arreglo |
|---|---|---|---|---|
| 441 | Logo de Quálitas en blanco en el PDF | J | ¿? | — |
| 560 | Reorganizar el detalle de Lead en Wagtail | J | ¿? | Parcial (PR #569 a `stg`) |
| 571 | Wagtail: seguimientos, Recovery y recordatorios en el perfil del Lead (nuevo) | J | ¿? | — |

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
| 472 | PROD ✱ (viaje 1: regla sí/no/ambiguo y `aviso_serie`); falta N≥20 y revisar los 3 rechazos falsos |
| 475 | El marcador `[SERIE_FORMATO]` no existe ni en STG ni en PROD |
| 473, 462 | El cambio principal sigue solo en STG |
| 344 | Falta el dictamen de diseño: el guard sigue tumbando la respuesta entera |
| 340 | La segunda mitad (insistir cuando el cliente corrige) no tiene arreglo |
| 337 | Persistir la suma asegurada al emitir: hacerlo o descartarlo por escrito |
| 304 | Los leads resultado siguen naciendo en `LEAD_CREADO`; no existe `CommercialLead` |
| 301 | En PROD solo está la regla 4. Siguen activos el 30 %, el VIN obligatorio para el 40 % y el tope 3 |
| 290 | `GET /api/v1/dashboard/funnel` no existe |
| 289 | PROD ✱ (viaje 2); el caso «ya pagada» se acredita con la primera póliza pagada real |
| 205 | Solo hay red en n8n; falta la regla en Django |
| 178 | `gotchas-n8n.md` diverge entre `main` y `stg` |
| 534 | No comprobable: falta que Quálitas confirme reportes y PDF |
| 128 | Superado en la práctica, pero es el tracker C7 de Juan (`#140`): acordarlo con él |

## Lo que destaca (de la foto inicial)

- **12 issues tienen el arreglo en los dos entornos** y siguen abiertos solo porque falta verlo funcionar en una
  conversación real: 270, 245, 344, 530, 528, 494, 500, 499, 536, 476, 471 y 554. Son candidatos a cerrarse en
  cuanto haya tráfico real que los acredite.
- **31 no dicen el entorno.** Casi todos son iniciativas o propuestas sin nada construido.
- **Hay datos viejos:** muchos issues de Juan tienen su último dato en agosto o principios de septiembre.

## Para limpiar el tracker (estado tras los cierres)

- **`#567`** no tiene responsable (`#568` lo cerró Juan el 8 oct).
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
