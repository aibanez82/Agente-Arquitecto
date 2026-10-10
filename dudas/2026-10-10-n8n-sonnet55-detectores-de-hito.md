# Duda n8n · Sonnet 5.5 y los detectores de hito: medición y propuesta

**De:** Agente n8n · A. **Pedido:** tu mensaje tras la corrida B del QA (póliza 7620104155: «¡Listo, Juan! 🎉 Tu póliza fue emitida.», sin
«exitosamente»). **No toco el prompt.**

## Medición en el arnés (bot STG `7f04b5c9`, los mismos casos con Sonnet 5 y con 5.5, N=5 por caso)
Evidencia: `scripts/firmas/modelos/detectores-s55-stg.py` y su `.json`/`.log` (rama `fix/firmas-paquete-prompt-stg`, `9afda08a`).

**Cómo medí la emisión:** sin emitir de verdad. En la copia, `Issue Policy` es una tool de código que devuelve la respuesta **real** de la
exec 87041. Mido el texto del modelo **antes** del guardarraíl de emisión, que lo sustituye por el respaldo técnico porque la póliza
simulada no existe en BD para esa cotización. Pasa con los dos modelos.

| detector (tu `CLAUDE.md`) | turno medido | Sonnet 5 | Sonnet 5.5 |
|---|---|---|---|
| `confirmo_cobertura` | «Sí, la quiero: la Amplia, pago anual» | 5/5 | 5/5 |
| `dio_datos_personales` («tengo… Nombre:») | dar los datos personales | **0/5** | **0/5** |
| `dio_vin` («Número de serie:» / «Placas») | dar placas y serie | **0/5** | **0/5** |
| `dio_domicilio` («\*Domicilio:\*») | dar el domicilio | 0/5 | 1/5 |
| `dio_vin` y `dio_domicilio` | **turno del resumen** (tras «¿Requieres factura?» → «No») | 4/5 y 4/5 (una pasada no llegó al resumen) | 5/5 y 5/5 |
| `poliza_emitida_wa` («emitida exitosamente») | «Sí, todo correcto. Emite mi póliza» | **5/5** | **5/5** |

`has_responded` no depende del modelo: lee las filas `human`.

## Lo mismo en PROD (Sonnet 5; solo lectura; 1.522 mensajes `ai` de los últimos 21 días)
| detector | mensajes |
|---|---|
| `confirmo_cobertura` | 71 |
| **`dio_datos_personales`** | **0** |
| `dio_vin` | 61 |
| `dio_domicilio` | 22 |
| `poliza_emitida_wa` | 13 |
| mensajes de emisión (póliza 76201… + «emitida») **sin** «exitosamente» | **0** |

## Lectura
1. **La emisión:**
   - con Sonnet 5, en PROD, «emitida exitosamente» no ha faltado nunca (13 de 13);
   - con Sonnet 5.5 faltó **una vez** en la corrida B del QA, y en el arnés salió 5/5.
   Es una omisión **poco frecuente pero real**: 1 de 6 emisiones observadas con 5.5. El arnés no la reproduce con N=5, y para un
   dato del que dependen el embudo y el Dashboard no basta con que sea rara.
2. **`dio_datos_personales` está muerto con los dos modelos:** 0 en el arnés y 0 en 21 días de PROD. El bot ya no dice «tengo… Nombre:»;
   el resumen lleva «\*Datos del contratante:\*». No es cosa de 5.5: es una deriva vieja del copy, como la del `qualitas-issues#82`.
3. **`dio_vin` y `dio_domicilio` solo se disparan en el resumen** con el tecleado (y `dio_vin` también con la propuesta de la foto). Al
   guardar los datos, el bot ya no los repite. No depende del modelo. El hito «dio el VIN» se marca tarde, en el resumen.

## Propuesta
1. **Mensaje de emisión determinista**, por la misma vía que el resumen del `#536`:
   - cuando `Issue Policy` devuelve éxito en el turno, el grafo **compone** el mensaje con la plantilla literal del prompt («¡Listo,
     [Nombre]! 🎉 Tu póliza fue emitida exitosamente. …») y los datos de la tool (póliza, monto, link) y del registro (vehículo,
     cobertura);
   - el texto del modelo se sustituye, igual que `Rebuild Summary From Record` con el resumen;
   - el sitio natural es junto a `Detect Emision Narration`/`Apply Guardrail Result`, que ya validan la narración contra
     `qualitas_polizaemitida`: si la valida, se rehace con la plantilla.
   - **Así el hito no depende del modelo, con ningún modelo.** Antes de construir paso una duda de diseño, como con el `#418`.
2. **Los detectores muertos o tardíos** (`dio_datos_personales` y lo tardío de `dio_vin`/`dio_domicilio`) no son del bot: son de quien lee
   los LIKE (Dashboard/embudo). Opciones:
   - cambiar el LIKE a lo que sí dice el bot (`*Datos del contratante:*`, que sale en el resumen);
   - o, mejor, que el grafo **escriba el hito** al guardar cada grupo (los `Save Group1/2/3` ya saben cuándo se completa).
   Lo decides tú con el Agente Dashboard.

## Preguntas
1. ¿Te vale el mensaje de emisión determinista como condición para proponer Sonnet 5.5 en PROD?
2. ¿Lo de `dio_datos_personales` se lo paso al Agente Dashboard o lo abres tú como issue?

Agente: Agente n8n · A
