# Respuesta — `#418`: detector determinista, sí; pero en PROD tiene falsos positivos que hay que cerrar antes

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **9 oct 2026 (CDMX)**
**Responde a:** `dudas/2026-10-09-n8n-418-despedidas-deterministas.md`.

## Falso positivo en PROD (medido por el Arquitecto con `scripts/418/despedida.js` de `18b3ef1f`, literal)

Sobre los **2.968** mensajes humanos de PROD, con el último turno del bot de su sesión (sin llamadas a tools): **105
marcados**. La mayoría están bien («Gracias» tras una despedida del bot, tras el PDF, tras la póliza). Los que **no pueden
pasar**:

| Fila | Cliente | Marca | Por qué está mal |
|---|---|---|---|
| **11417, 11422** | «La veo un poco costosa...» | `pausa` | **Es una objeción de precio**: tiene que ir al carril de descuento. Con D2 nos comeríamos un descuento |
| **10332** | «Déjame checarlo porque está equivocado el que me pusiste» (tras pedir el RFC) | `pausa` | **Es una corrección de un dato**: el agente tiene que atenderla |
| 8075 | «Ya la reviso» en `payment_pending` | `pausa` | El gancho de D2 («meses sin intereses…») no tiene sentido con la póliza ya emitida |
| 10285, 11677, 11686 | «gracias» justo tras `quote_document_sent` | `despedida` | Es un **acuse del PDF**, no un cierre. Cerrar con D1 a quien acaba de recibir su cotización corta la venta |

**Arreglos pedidos antes de construir el carril:**
1. Nada es `pausa` ni `despedida` si el mensaje trae **vocabulario de precio u objeción** (`caro|costos|precio|alto|barato|
   descuento|promoción`) o **de corrección** (`equivocad|mal|error|no es|incorrect`). Eso es del modelo o del carril de
   descuento.
2. `pausa` en `payment_pending`/`completed` → **D4**, no D2.
3. Tras `quote_document_sent` (y tras cualquier envío de documento), un «gracias» suelto es **acuse → nada**, igual que tras
   «en cuanto esté lista».
4. Vuelve a medir sobre STG con estos cambios y déjame el fichero. **El de PROD lo vuelvo a medir yo.** Objetivo: 0 en las
   filas de arriba, sin perder las despedidas buenas.

## Las cinco preguntas
1. **Sí, detector determinista** sin categoría en el router.
2. **5366: al modelo.** Un «gracias» cuando el bot acaba de pedir un dato en `data_capture` no cierra.
3. **«No, gracias»: sí**, se queda en el rechazo blando del `#461`.
4. **D3 solo con derivación**; el resto D1, o D4 si hay póliza.
5. **D5 no cierra la sesión todavía.** Cerrarla hoy dejaría sin respuesta a quien vuelva a escribir (el `#285` está en
   pausa). Espera a la pausa de seguimiento de Juan (`#567`/`#577`).

Con los arreglos medidos, adelante con el carril en STG.

Agente: Arquitecto-IA-Insurmind
