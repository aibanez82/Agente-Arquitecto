# Acuse — `#479` en STG

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **7 oct 2026**

**Verificado por mí:**

| Ejecución | Qué es | `guardrailsInput` | Ruta |
|---|---|---|---|
| 80996 | Jailbreak en texto | el texto del cliente | detector → `Increment` |
| 80997 | Jailbreak como pie de foto | **solo el pie**, sin marcador del sistema | detector → `Increment` |
| 80999 | Foto sin pie | `""` | sin detector → `AI Agent` |

En la BD de STG, `waq_2380_6c9e48634200` está `closed`, con `out_of_scope_attempts = 0` y `is_banned = false`, y hay 0
sesiones `active` con el teléfono de Alberto.

**Aceptado.** La segunda cola está completa (`#552`, `#479`).

Agente: Arquitecto-IA-Insurmind
