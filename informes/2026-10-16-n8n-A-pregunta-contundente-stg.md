# Informe — SESIÓN A · la pregunta del resumen, más contundente: en STG

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**

**Orden:** `Agente-n8n:handoffs/2026-10-16-A-resumen-pregunta-contundente.md` (texto firmado por Alberto), más las adendas 9 y 13 del `#551`.

**STG:** bot `739ac62d` (lo que dejó B, medido otra vez antes del PUT) → **`575da028-6892-494d-b313-30441c0f6f89`**.
- Hojas y connections, iguales al candidato. Activo.
- Respaldo: `backups/pregunta/bot-stg-739ac62d-….json`.
- Repo: rama `feature/resumen-pregunta-contundente`, mergeada a `stg`.

## Delta por hunk (medido en el vivo: 4 nodos, 1 línea cada uno)

| Nodo | Antes | Después |
|---|---|---|
| `AI Agent` · systemMessage (plantilla del resumen) | `"[Nombre], ¿todo correcto? Con tu sí, emito tu póliza.` | `"[Nombre], ¿está todo correcto? Dime *Sí* y emito la póliza.` |
| `Rebuild Summary From Record` · jsCode | `(pila ? pila + ', ¿todo correcto?' : '¿Todo correcto?') + ' Con tu sí, emito tu póliza.'` | `(pila ? pila + ', ¿está todo correcto?' : '¿Está todo correcto?') + ' Dime *Sí* y emito la póliza.'` |
| `Rebuild Recovery Summary` · jsCode | ídem (`pila`) | ídem |
| `Recovery Resumen Template` · jsCode | ídem (`nombre`) | ídem |

**Otras apariciones: ninguna.**
- Barrí «todo correcto / Con tu sí / emito tu/la póliza» en todos los nodos de todo `workflows/*.json` de `main` y del STG vivo.
- Solo salen estos 4 y los dos lectores de la respuesta del cliente (`Detect Confirmation` y `Route Normal Guard`), que no cambian.
- **En PROD ya existen los 4 sitios**: los del Recovery llegaron con el viaje B. Tu orden decía 2.

## Aceptación (arnés sin envíos; emisión SIMULADA con el Guard temporal)

| Caso | Base | Cambio | Control |
|---|---|---|---|
| Normal, con nombre: «No» a la factura → resumen → «Sí» → `issue_policy` → «emitida exitosamente» | 739ac62d | **3/3** | 0/1 (texto viejo; también emite) |
| Normal, con nombre: lo mismo con «\*Sí\*» | 739ac62d | **3/3** | 0/1 (ídem) |
| Recovery S1: el resumen lo monta `Rebuild Summary From Record` | 739ac62d | **3/3** | — |
| Recovery S1b: carril directo (`Rebuild Recovery Summary` + `Recovery Resumen Template`) | 739ac62d | **3/3** | 0/3 en 3d31853c |
| Sin nombre: expresión EXACTA de los 3 nodos de código, evaluada con `pila`/`nombre` = '' y 'Juan' | — | **6/6 offline** | — |

**Sin ejercitar:**
- **Sin nombre, en vivo.** Con el nombre vacío el bot lo pide antes de resumir (3/3 en b321eb6c), así que en conversación no se alcanza. Solo se acredita offline.
- **El «Sí» dentro del carril Recovery hasta emitir.** La confirmación pasa por el mismo `Detect Confirmation` que en el flujo normal, que sí está ejercitado.

**El control de los dos casos normales y el de S1b se midió en una base anterior** (3d31853c), **no en 739ac62d.** Entre medias, B (#613) cambió `Merge Session Data` y `AI Agent`. La pregunta vieja estaba en la misma línea (×1, mismo ancla).

**PROD:** cambia el systemMessage, así que necesita la firma u orden de Alberto. No he tocado nada.

**Siguiente:** los casos (ii) y (iv) del arnés del #551.

Agente: Agente n8n · A
