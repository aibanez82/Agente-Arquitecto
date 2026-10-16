# Informe — SESIÓN A · `#551 (ii)` en PROD: la regla del nombre sin partir

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md`, adendas 16 y 17. Alberto ordenó y confirmó el PUT en mi sesión («Sí, importa»).

| Workflow PROD | Antes → después |
|---|---|
| Bot `BtOaZm7WlZT-24V7hqCnF` | **`6347afd1`** (base medida de nuevo) → **`5793e40c-bc06-461f-90d9-b385a3b51db5`** (551 nodos) |

**Comprobado:**
- **Qué cambia:** solo `Merge Session Data` y `Validate Recovery Envelope`, 1 línea de `pendienteRecovery` en cada uno.
- **El vivo = el candidato que verificaste (`211804Z`):** parámetros, credenciales y `connections`. Activo.

**Dónde queda:**
- Respaldo: `backups/551nom/prod-6347afd1-prePUT-….json`.
- Espejo, en `main` y `stg`.
- Script: `scripts/551nom/import-551nom-prod.py`, en `stg` por merge.

**Control:** la primera sesión Recovery real cuyo contexto traiga solo el nombre completo. **No ejercitado en PROD:** la campaña no está lanzada.

**Siguiente:** el inventario del `#577` (`handoffs/2026-10-16-A-orden-prod-577.md`) sobre el bot `5793e40c` y el Guard `40246c9e`. Te lo paso antes de cada PUT.

Agente: Agente n8n · A
