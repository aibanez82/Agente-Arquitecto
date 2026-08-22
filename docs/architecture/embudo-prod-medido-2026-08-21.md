# El embudo real de PROD, medido — 21 ago 2026

Medido por el Arquitecto contra Postgres de PROD. **1.089 sesiones, 9 jun → 21 ago 2026** (~10 semanas).

## Dónde se muere la gente

| Etapa | Sesiones | Lectura |
|---|---|---|
| Nunca hubo mensaje humano | **752** | el lead no contestó al primer WhatsApp; el bot ni entra en juego |
| Escribió y no pasó de las primeras vueltas | **190** | de ellas **67 ya habían confirmado cobertura**, 5 dieron VIN, **0 dieron datos personales** |
| Captura de datos | 75 | |
| Resumen / emisión | 14 | (8 `summary_confirmation` + 6 `policy_issuance`) |
| **Póliza emitida, sin pagar** | **20** | ~$124.700 MXN citados en 9 de las 20 (cifra del Agente Mejoras Conv.) |
| **Cerradas** | **38** | |

**De 337 personas que llegaron a escribir, se cierran 38: un 11%.**
**De 58 pólizas emitidas, 20 nunca se cobran: un 34%.**

Aguante de los que escribieron: **93 escribieron un solo mensaje y se fueron** · 116 escribieron 2-3
· 86 escribieron 4-9 · 50 escribieron 10 o más.

**El bot siempre contestó**: cero sesiones con mensaje humano y sin respuesta del bot. Cuando alguien
se va, no es porque no le respondieran.

## ⚠️ `conversation_phase` miente — no construir nada encima

De las **190** sesiones marcadas `greeting`, **67 habían confirmado cobertura** y 5 habían dado el
VIN según el texto real de la conversación. Es el bug `#82`: la fase se queda clavada y **devuelve un
valor plausible en vez de fallar**.

Cualquier embudo, informe o detector construido sobre `conversation_phase` sale mal. Usar
`n8n_chat_histories` con los detectores de texto de `CLAUDE.md`, con la limitación del `#183` encima:
de cada turno solo persiste el **último** intercambio de tool, así que **nada que cuente llamadas a
herramientas es fiable** — solo lo que lee texto.

## Otros hechos medidos el mismo día

- **`estatus_pago` no es fiable**: 52 `PENDIENTE` y 6 `PAGADO` de 58, con pólizas de julio ya
  cobradas. La verdad del pago está en `conciliacion_pagos`. *(Corrige una afirmación mía previa de
  que Django «nunca» escribe `PAGADO`: lo escribe poco, no nunca — y la diferencia importa si algo
  va a leer ese campo.)*
- **`url_pasarela_pago` está vacío en todas las filas**: Django manda el link por correo y no lo
  persiste. Es la causa raíz de que el bot no pueda reenviarlo cuando el cliente lo pide.
- **Las sesiones no se cierran**: 1.066 abiertas frente a 15 cerradas.

## Para qué se midió

Para ordenar el desarrollo por dónde se pierde el dinero, no por dónde miramos primero. El cubo del
cobro —los 20— es **el más pequeño de todos**, y era el único que estábamos analizando.

La petición de informe al Agente Mejoras Conversación derivada de esto cubre el embudo entero, no
solo el cobro. Copia en `~/Desktop/peticion-informe-embudo-completo.md`.
