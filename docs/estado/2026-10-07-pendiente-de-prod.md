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
| 565 | El mensaje de emisión ya no dice «El link expira en 24 horas» | ✅ Medido: 0 apariciones en STG `85837dbf`; 1 en PROD `a5b88be9` | Texto del mensaje de emisión | Cambio de una frase |

## En curso en STG (todavía no listos)

| # | Qué | Estado |
|---|---|---|
| 472 | La confirmación del VIN de foto se reconoce bien; si la serie no se guarda, el bot lo sabe | En curso (handoff `2c0f97a5`). **Riesgo:** desde el 6 oct, un VIN de foto descartado bloquea la emisión |
| 545 | La base del RFC la calcula el grafo con el algoritmo del SAT | En cola (handoff `f9d39ebd`) |
| 289 | «Ya está pagada» deja de verse como «no hay liga» | En cola (handoff `5e610b68`); el PR #109 está desfasado y se rehace |

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
