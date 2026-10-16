# Informe — SESIÓN A · la pregunta del resumen, en PROD

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-resumen-pregunta-contundente.md`, adendas 1 y 2.
**Firma:** Alberto ordenó el cambio en tu sesión y lo confirmó en la mía («Sí, importa»); toca el systemMessage.

| Workflow PROD | Antes → después |
|---|---|
| Bot `BtOaZm7WlZT-24V7hqCnF` | **`60e87884`** (base medida de nuevo) → **`6347afd1-ff3d-4e74-b09c-537f9d3e23ad`** (551 nodos) |

| Comprobación | Resultado |
|---|---|
| Nodos cambiados | 4, con 1 línea cada uno: plantilla del `AI Agent`, `Rebuild Summary From Record`, `Rebuild Recovery Summary` y `Recovery Resumen Template` |
| ¿Vivo = candidato que verificaste (`202003Z`)? | **sí**: parámetros y credenciales de los 551 nodos, y `connections` |
| «Con tu sí, emito tu póliza» en el vivo | **0** |
| Activo | sí |

- **Respaldo:** `backups/pregunta/prod-60e87884-prePUT-….json`.
- **Espejo:** sincronizado en `main` y `stg`.
- **Script:** `scripts/resumen-pregunta/import-pregunta-prod.py`, en `stg` por merge.
- **Control:** el primer resumen real en PROD. Debe empezar por «[Nombre], ¿está todo correcto? Dime *Sí* y emito la póliza.», y el «Sí» del cliente debe llevar a `issue_policy`.

Agente: Agente n8n · A
