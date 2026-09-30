# Informe — `#506` y `#510` en `stg`

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **30 sep 2026**
**Responde a:** `handoffs/2026-09-30-506-510-dos-mentiras-de-la-pantalla.md` (`a15ce9a`)

| | Rama | Merge en `stg` |
|---|---|---|
| `#506` | `fix/506-fallos-no-comprobables` = **`c3340fb`** | `3940071` |
| `#510` | `fix/510-quote-document-sent-es-evento` = **`1dffd61`** | **`e63862f`** (cabeza de `stg`) |

Suite, verificador y `build` en verde en cada rama; en `stg`, **719 tests, 717 pass, 0 fail**. Desplegado. `main` no.

## `#506` — los fallos del agente ya no dicen 0 cuando no se pudo leer

- Tres estados, como `enviosColgados.js`: hay algo · limpio («Fallos del agente: 0 en los últimos 60 min.») ·
  **no comprobable**, con su motivo. Sin lectura, `fallosAgente` es `null`: no dispara ni apaga ninguna regla.
- **La alerta de silencios sigue funcionando** aunque el ledger falle (test).
- **Test fail-first con un `42501`**: fallaba contra el código anterior.
- **Un segundo cero mudo que encontré al releer mi propio cambio:** si fallaba la PRIMERA lectura (la de silencios),
  se salía antes de mirar el ledger, y los fallos volvían a salir «0» por el valor por defecto. Cerrado, con su test.
- La bandeja pinta el estado de la señal en una línea discreta; el recuadro fuerte (tres o más) no cambia.
- **En vivo en STG:** `GET /api/alertas/salud-bot` → «Fallos del agente: 0 en los últimos 60 min.», comprobable.

## `#510` — `quote_document_sent` se enseña como evento, no como mensaje del bot

- **Visor:** evento centrado y neutro, «📎 Se envió el PDF de la cotización», con la explicación si la trae. Se
  convierte en `separarMarcadores`, **el mismo filtro por el que pasan el historial actual y el heredado**, así que
  tampoco sale como «📚 Contexto heredado».
- **Lista:** la vista previa **sí enseñaba el marcador en crudo**, así que entra aquí: ahora dice «📎 Se envió el PDF
  de la cotización».
- **Coincidencia exacta** (`=== 'quote_document_sent'` o empieza por `'quote_document_sent —'`, quitando solo el
  espacio de los extremos) **y solo en filas del bot**.
- **La fila de la base no se toca.**
- **Tests fail-first contra los handlers REALES** de conversación y de bandeja, con las dos formas, con un texto de
  cliente que empieza por «quote» (se queda como mensaje suyo) y con el texto junto a la foto del `#487` (sigue).
  Comprobé que el de la lista fallaba **por el motivo correcto** —el marcador en crudo—, no porque el handler
  reventara.
- **Un riesgo que miré antes de tocar nada:** el emparejamiento de envíos huérfanos casa el ledger con los mensajes del
  bot, y el PDF sale por `s1.quotedoc`. Si la nota dejara de contar como mensaje del bot, ese envío podría aparecer como
  huérfano. **No pasa:** el emparejamiento se calcula antes de la conversión (`conversation.js:432` frente a
  `separarMarcadores`), y hay un test que fija ese orden.
- **En vivo en STG:** STG tiene 160 filas con la nota en 103 sesiones. El visor del lead 1388 devuelve **1 evento
  `envio_pdf` y 0 mensajes con el marcador en crudo**.

— Agente Dashboard
