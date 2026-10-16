# Informe — SESIÓN A · `#551` adenda 8: el RFC del caso (i), arreglado en STG; puntos 1 y 2 del arnés

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md`, adenda 8.

## 1. El RFC del caso (i): la causa medida no es la que te dije

**Mi hipótesis del orden** (calcular la base antes de guardar la fecha) **era falsa**.

- **Lo que medí.** `Merge Session Data` calcula `rfcBase` leyendo SOLO `captured_data.grupo1`. En Recovery, mientras el grupo 1 está incompleto, los datos precargados viven en `captured_data.recovery_precarga.grupo1`, no en `grupo1`; lo dice `precarga.js`: «un grupo se escribe en grupoN SOLO si está completo».
  - Así que en Recovery el nombre nunca llega a la base hasta que el grupo 1 se completa y se guarda.
  - En el caso (i), además, la fecha llega en el mismo mensaje que «no requiero factura».
- **El modelo cumple el prompt.** La regla dice «Si no viene `rfc_base`, pide al cliente su RFC completo», y eso hizo.
- **Ninguna de tus dos propuestas cubre el caso (i):**
  - Recalcular tras `Save Group1` no llega al mismo turno. `Save Group1/2 Progress` son tools del agente (`ai_tool`), y `Merge Session Data` ya corrió antes del agente.
  - Que el resumen tome la base del registro tampoco: sin factura, el RFC no sale en el resumen. Lo que falla es la pregunta, no el resumen.
- **El arreglo, solo en `Merge Session Data · jsCode`, sin tocar el prompt:**
  - Cada campo sale del registro; si falta, de la precarga.
  - Para la fecha, si tampoco está, se usa la del mensaje de ESE turno, solo si trae **una única** fecha DD/MM/AAAA válida de alguien con 18 años o más.
  - Solo aplica en sesiones con `recovery_precarga`; sin ella, el bloque es idéntico al de antes.

| Prueba | Control (vivo `b321eb6c`) | Cambio |
|---|---|---|
| Batería offline (bloque viejo contra nuevo, mismas funciones RFC del MSD) | — | **10/10** |
| Arnés S2×3: «Sí, me interesa» → «Masculino» → «Nací el 15/06/1985 y no requiero factura» | **0/3**: pide el RFC (13 o «con 10 basta»); `rfc` guardado = `'N/A'` | **3/3**: `rfc_base` en el `[CTX:]`; `rfc` = la base (10 caracteres, correcta); pasa al resumen |

- **STG:** bot `b321eb6c` → **`3d31853c-7493-4ed0-8d92-47f73fe61d0e`**. Hojas y connections iguales al candidato, activo, espejo en `stg`.
- **Repo:** rama `fix/551-rfc-base-precarga` (`29e03805`), mergeada a `stg` (`971b9392`).
- **Para PROD:** el bloque viejo está ×1 en PROD `a75c713e`, así que el mismo cambio aplica tal cual. El viaje lo decides tú; no he tocado PROD.

## 2. ¿Pasa fuera del Recovery? No

- **El defecto exige `recovery_precarga`.** Sin ella, `rfcBase` sale de `grupo1`, que en el flujo normal se guarda completo antes de que se pregunte la factura (después del Grupo 3).
- **Medido en PROD.** Ámbito: todo `n8n_chat_histories`, mensajes `ai` que piden el «RFC completo/con homoclave» de 13 caracteres. Hay **2**, ninguno de este defecto: uno es el RFC de un tercero que paga y el otro, un RFC que el cliente dice que está mal. Ninguna de esas sesiones es de Recovery.

## 3. Arnés del punto 2 (sobre `b321eb6c`, sin envíos, sesiones sintéticas borradas)

| Caso | Resultado |
|---|---|
| (iii) S1 completo ×3 | **3/3**: pregunta solo la factura → resumen |
| S1sp: Django sin placas ×2 (#614) | **2/2**: no pide placas en ningún turno; el resumen va **sin** la línea «Placas:» |
| (i) S2 | defecto del §1; arreglado en STG |
| (ii) y (iv) | aplazados, como en la adenda 8: van después de la pregunta contundente |

**Observación (no la he medido más):** en S2, el género dado en el turno 1 no se guarda hasta el turno 2.
- `faltan` sigue listando `genero` al empezar el turno 2. `Save Group1` no se llama con el grupo incompleto, así que el modelo lo lleva en memoria de la conversación.
- Los 6 resúmenes salieron bien.

**PROD:** sin sesiones de Recovery todavía, porque la campaña no se ha lanzado (lo confirma Alberto). Tengo armada una vigilancia de solo lectura que avisa con la primera; entonces miro sus ejecuciones.

Agente: Agente n8n · A
