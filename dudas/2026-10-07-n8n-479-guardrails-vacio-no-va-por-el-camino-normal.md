# Duda #479 — con `guardrailsInput` vacío, `Detect Jailbreak` no sigue el camino normal (punto 4 del handoff)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-479-el-detector-solo-escanea-al-cliente.md`, punto 4: «si no, para y pregunta».
**Estado:** medido, sin construir. STG sin tocar. Va después del #552, que ya estoy construyendo.

## Lo medido

- **Dónde cambiar:** `Detect Jailbreak` escanea `$json.guardrailsInput`, que produce `PII Sanitization` a partir de su
  parámetro `text` (hoy `{{ $json.chatInput }}`). Lo que ve el agente **no** depende de eso: `Restore Context After Guardrail`
  repone el item de `Basic Input Sanitization`. Así que el cambio es solo el `text` de `PII Sanitization` →
  `messageType === 'text'` ? el texto del cliente : (imagen ? `imageCaption` || '' : '').
- **El problema (arnés temporal en STG, copias byte a byte de `PII Sanitization` + `Detect Jailbreak` + `Haiku`, ya borrado):**

  | Entrada | `PII` | `Detect Jailbreak` |
  |---|---|---|
  | `""` | pasa: `guardrailsInput: ""` | **salida 1**, `triggered: true`, **`executionFailed: true`**, «Guardrail validation failed: Bad request» |
  | «No, gracias» | pasa | salida 0 (`confidenceScore 0`) |
  | jailbreak evidente | pasa | salida 1 (`0.95`, sin fallo) |

  Con el #463, una salida 1 con `executionFailed` va a **`Guardrail Error Safe Reply`**. **Cada foto sin pie respondería
  «Tuvimos un problema procesando tu mensaje, ¿puedes repetirlo?»**, en vez de seguir al agente. No es el camino normal.

## Propuesta

Un **IF antes de `PII Sanitization`**: si el texto del cliente del turno está vacío, no hay nada suyo que escanear y el
turno **se salta los dos guardarraíles** hasta `Restore Context After Guardrail`, que ya repone el item de `Basic Input
Sanitization`. Con texto, pasa por `PII` + `Detect Jailbreak` como hoy, pero escaneando solo lo del cliente.

- **Ventaja:** el detector, su umbral, el #463 y lo que ve el agente no cambian. Las fotos sin pie dejan de pagar una llamada
  al modelo para nada.
- **Coste:** un nodo IF y una arista más que «solo cambiar el `text`».

¿Te vale? Con tu OK lo construyo **después** de entregar el #552.

— Agente n8n
