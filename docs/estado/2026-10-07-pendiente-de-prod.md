# Pendiente de PROD — para el OK de Alberto a su vuelta

**De:** Arquitecto-IA-Insurmind · **Abierto:** 7 oct 2026 · **Documento vivo:** se actualiza con cada paquete.
**Regla:** mientras Alberto está fuera no viaja nada a PROD
(`docs/estado/2026-10-07-autonomia-mientras-alberto-fuera.md`). Aquí queda cada paquete **verificado en STG por
el Arquitecto** y listo para su OK.

## Paquetes listos para tu OK

| # | Qué cambia para el cliente | Verificado en STG | Toca emisión/dinero/prompt | Notas para el viaje |
|---|---|---|---|---|
| 563 | El carril del descuento ya no vuelve a pedir el VIN que el cliente acaba de confirmar por foto | ✅ E2E del QA 5/5 (ejecuciones 80296-80319), verificado por el Arquitecto | Descuento | Orden de import publicada (`7f169ff`), parada en la capa de permisos del Agente n8n. **Viajar junto con el `#472`**, porque los dos tocan la misma regla de afirmación |
| 463 | Si el guardarraíl no puede evaluar (cuota, error del proveedor), el cliente recibe una respuesta segura y **no suma para el baneo** | ✅ STG `289c4070`, verificado por el Arquitecto: grafo y ejecuciones 80939/80940/80942 (acuse `91989ca`) | No | **Tiene que llevar las piezas del `#325`** (`onError: continueErrorOutput` y `Guardrail Error Safe Reply`), que PROD no tiene |
| 472 | La confirmación del VIN de foto se reconoce bien («Si el num de serie esta bien», «Son correctas»…) y, si la serie no se guarda, el bot lo sabe en vez de decir «ya tengo tus datos». **Cierra el riesgo de emisión bloqueada desde el 6 oct** | ✅ STG bot `1b55efa8`, verificado por el Arquitecto: regla idéntica en los dos nodos y 14/14 casos decididos | **Emisión** | **Viaja junto con el `#563`** (misma regla). Falta acreditar la parte conversacional con **una foto real tuya a STG** |
| 545 | La base del RFC la calcula el grafo con el algoritmo del SAT. Solo corrige cuando es seguro que es del titular | ✅ Issue Policy Guard STG `b431ad23`, verificado: corpus real 81/88 sin fallos del algoritmo | **Emisión** | Sub-workflow `Issue Policy Guard`, no el bot. La línea contradictoria del prompt va aparte, a tu firma |
| 289 | Si la póliza ya está pagada, el bot lo dice en vez de «no hay liga» | ✅ STG bot `4b1bf2f4`, verificado: solo los dos consumidores, prompt intacto | Pagos (solo lectura de estado) | Caso «pagada» no comprobable en STG (Django STG da 503); se acredita con la primera pagada real de PROD |
| 552 | Si el cliente pide la liga antes de tener póliza, el bot responde tu texto («Aún me faltan algunos datos tuyos para poder emitir, y después te genero el link de pago.») y sigue, en vez de «No hay una liga disponible» | ✅ STG bot `3ca60723`, verificado: ejecución 80987 con el carril completo y memoria; el turno siguiente retoma la selección | No (texto tuyo literal, ya decidido) | Carril calcado del guard del descuento (13 nodos). Reconoce también las formas de usted |
| 479 | El detector de jailbreak escanea solo lo que escribe el cliente (no los marcadores del sistema); una foto sin texto no pasa por él | ✅ STG bot `b31b71a6`, verificado: controles positivos en vivo (jailbreak en texto y como pie de foto saltan; foto sin pie llega al agente) | No (control de seguridad) | **Depende del `#463`** (y este del `#325`): viajan juntos |
| 565 | El mensaje de emisión ya no dice «El link expira en 24 horas» | ✅ Medido: 0 apariciones en STG `85837dbf`; 1 en PROD `a5b88be9` | Texto del mensaje de emisión | Cambio de una frase |

## En curso en STG (todavía no listos)

| # | Qué | Estado |
|---|---|---|
| — | Nada en curso en este momento | — |

## Necesitan tu firma de texto

**Propuestas listas** en `informes/2026-10-07-textos-para-firma-461-418-261-543-340.md` (Mejoras, verificado por el
Arquitecto contra el prompt vivo, acuse `91989ca`):

| # | Qué propone, en una línea |
|---|---|
| 461 | Quitar del prompt la invitación «¿…o prefieres ver otra cobertura…?», que se exige en tres sitios, y cambiarla por «¿Te la dejo lista para contratar?». **Efecto lateral bueno:** elimina 90 falsos positivos del detector `confirmo_cobertura` (`#502`) y deja intactos los 224 verdaderos |
| 418 | Separar pausa y despedida. Respuestas deterministas a la despedida (D1-D5), sin re-ofertar. El carril de descuento confundió dos despedidas con objeciones |
| 261 | La regla «solo URLs que devuelva una tool» va en el grafo. Texto honesto cuando no hay documento; el deducible se responde con el dato |
| 543 | Tres casos cuando «el VIN ya tiene póliza»: nuestra vigente (postventa), vencida (emitir nueva) o de otra agencia. b2 y c2 dependen de una prueba con Quálitas |
| 340 | Segunda mitad: reconocer la corrección del cliente y no discutir (K1, K3, K4) |

**`#553`** (oferta de la competencia): texto entregado el 5 oct; falta **tu decisión sobre el C9** (el bot dijo «no
estás obligada, puedes cancelar» con seguros de agencia o financiamiento).

## Necesitan tu orden aunque no sean de n8n

| # | Qué | Por qué es tuyo |
|---|---|---|
| 178 | Publicar `gotchas-n8n.md` en `main` de Agente-n8n | `main` de cualquier repo es tuyo |

Agente: Arquitecto-IA-Insurmind
