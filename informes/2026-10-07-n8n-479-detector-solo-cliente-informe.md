# Informe #479 — el detector de jailbreak escanea solo lo que escribe el cliente (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-479-el-detector-solo-escanea-al-cliente.md`, con tu respuesta a mi duda (IF
aprobado). **Estado:** aplicado en STG y aceptado **5/5, con los controles positivos en vivo**. **PROD no está tocado.**

## versionId y diff

**Bot STG:** `3ca60723` → **`b31b71a6`**. Respaldo: `backups/479/bot-stg-3ca60723-20261008T000621Z.json`.

- **`PII Sanitization`/`text`** (antes `{{ $json.chatInput }}`) pasa a ser solo el texto del cliente:
  - turno de texto → el `message.text.body` de `Session Context Builder`;
  - imagen con pie (`imageCaption` cadena) → el pie;
  - **cualquier otro caso** (sticker, audio, botón, imagen sin el campo) → `$json.chatInput`, **como hoy**.
- **IF nuevo `¿Sin texto del cliente?`**, entre `Basic Input Sanitization` y `PII Sanitization`. «Vacío» se decide en
  positivo: imagen con `imageCaption === null` o pie en blanco, o texto vacío tras recortar.
  - Con `true` se salta `PII Sanitization` y `Detect Jailbreak` → `Restore Context After Guardrail`, que repone el item de
    `Basic Input Sanitization`.
  - **Ante la duda no se salta:** si falta el campo, la forma es inesperada o es otro tipo de mensaje, el turno pasa por los
    guardarraíles.
- **Medido antes:** nadie lee `PII Sanitization` ni `Detect Jailbreak` por nombre, y lo que ve el agente sale de `Basic Input
  Sanitization`. **El `chatInput` del agente no cambia.**
- **No se tocan:** el detector, su umbral y su modelo, el #463 ni los `systemMessage`.
- **Diff contra el respaldo:**
  - hojas: `PII Sanitization/text` y las del IF;
  - connections: solo `Basic Input Sanitization` → IF → [`Restore Context After Guardrail` | `PII Sanitization`];
  - el resto idéntico; el workflow activo.
- **Código:** rama `fix/479-detector-solo-cliente`, `scripts/479/`.

**Por qué el IF.** Arnés temporal en STG, ya borrado: con `guardrailsInput` vacío, `Detect Jailbreak` sale por la salida 1 con
`executionFailed` («Bad request»). Con el #463, cada foto sin pie habría acabado en «Tuvimos un problema…». Es la duda `36d7e35`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS 8/8 offline** | `guardrailsInput` (el `text` del PII) por tipo de turno. Texto → el mensaje. Texto vacío → se salta. Foto sin pie (`null`) → se salta. Foto con pie → **solo el pie**, sin `[FOTO_VIN]` ni «TOPE DE FOTOS». Pie en blanco → se salta. Foto **sin el campo** `imageCaption` → **no se salta** (como hoy). Sticker → como hoy. Botón → como hoy. |
| 2 | **PASS, control positivo en vivo** | Teléfono de Alberto, sesión `waq_2380_6c9e48634200`. **80996**, jailbreak en texto: `guardrailsInput` = el texto → detector → `¿Jailbreak evaluado?` → aviso + `Increment` (0 → 1). |
| 3 | **PASS, control positivo en vivo con imagen** | **80997**, jailbreak como pie de foto. La imagen era sintética, así que la descarga falla y entra el fallback de visión, que inyecta su marcador. Aun así, `guardrailsInput` = **solo el pie** → detector → aviso + `Increment` (1 → 2). |
| nuevo | **PASS** | **80999**, foto sin pie: `¿Sin texto del cliente?` = true → **sin** PII ni detector → `AI Agent`, respuesta `sent`, sin la respuesta de error. Contador sin cambio. |
| 4 | **PASS** | **81001**, «No, gracias» → detector (salida 0) → `AI Agent`. **81003**, «¿Qué cubre la cobertura amplia?» → `RAG IA Agent`. Contador sin cambio en los dos. |
| 5 | **PASS** | Diff: arriba. |

**Contador:** los dos controles positivos lo subieron a 2. **Lo devolví a 0** (`is_banned=false`) y **cerré la sesión**.

— Agente n8n
