# Pendiente de PROD — para el OK de Alberto a su vuelta

**De:** Arquitecto-IA-Insurmind · **Abierto:** 7 oct 2026 · **Documento vivo:** se actualiza con cada paquete.
**Regla:** mientras Alberto está fuera no viaja nada a PROD
(`docs/estado/2026-10-07-autonomia-mientras-alberto-fuera.md`). Aquí queda cada paquete **verificado en STG por
el Arquitecto** y listo para su OK.

## Paquetes listos para tu OK

| # | Qué cambia para el cliente | Verificado en STG | Toca emisión/dinero/prompt | Notas para el viaje |
|---|---|---|---|---|
| 563 | El carril del descuento ya no vuelve a pedir el VIN que el cliente acaba de confirmar por foto | ✅ E2E del QA 5/5 (ejecuciones 80296-80319), verificado por el Arquitecto | Descuento | Orden de import publicada (`7f169ff`), parada en la capa de permisos del Agente n8n. **Viajar junto con el `#472`**, porque los dos tocan la misma regla de afirmación |
| 565 | El mensaje de emisión ya no dice «El link expira en 24 horas» | ✅ Medido: 0 apariciones en STG `85837dbf`; 1 en PROD `a5b88be9` | Texto del mensaje de emisión | Cambio de una frase |

## En curso en STG (todavía no listos)

| # | Qué | Estado |
|---|---|---|
| 463 | El guardarraíl que no pudo evaluar no suma para banear al cliente | Handoff `3e80cc1d` lanzado |
| 472 | La confirmación del VIN de foto se reconoce bien; si la serie no se guarda, el bot lo sabe | Handoff `2c0f97a5` en cola tras el `#463`. **Riesgo:** desde el 6 oct, un VIN de foto descartado bloquea la emisión |

## Necesitan tu firma de texto (propuestas en preparación)

`#553` · `#461` · `#418` · `#261` · `#543` · `#545` · `#340` (segunda mitad).

## Necesitan tu orden aunque no sean de n8n

| # | Qué | Por qué es tuyo |
|---|---|---|
| 178 | Publicar `gotchas-n8n.md` en `main` de Agente-n8n | `main` de cualquier repo es tuyo |

Agente: Arquitecto-IA-Insurmind
