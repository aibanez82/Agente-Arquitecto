# Informe — SESIÓN A · `#551` viaje A a PROD: los hunks del carril Recovery en los nodos compartidos

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md` + adendas 1, 3, 4 y 5.
**Confirmación de Alberto en mi sesión:** «Sí, importa».

| Workflow PROD | Antes → después |
|---|---|
| Bot `BtOaZm7WlZT-24V7hqCnF` | **`cc0f03f5`** (base medida de nuevo) → **`4cb07a3c-83ba-4057-a5da-e57b229fb0e6`** |

- **Candidato:** `scripts/551prod/import-551-prod.py A`, construido con `cambio_551_prod.aplicar_compartidos` sobre el vivo. Fuente: STG `b321eb6c`, cuya foto se guarda en `backups/551prod/stg-fuente-…`.
- **Respaldo:** `backups/551prod/prod-cc0f03f5-prePUTA-….json`.

## Después del PUT

| | Medido |
|---|---|
| Nodos / hojas | `Merge Session Data/jsCode`, `Parse Router Output/jsCode`, `Save Group1/2/3 Progress/query`, `AI Agent/text`, `RAG IA Agent/text`; ni nuevos ni quitados |
| ¿Igual al candidato que verificaste (`191929Z`, adenda 5)? | **sí**: todos los parámetros idénticos y `connections` idénticas |
| Activo | sí |

**Espejo:** `workflows/WhatsApp Insurance Quotation Bot.json` en `main` y `stg`.
**Inerte sin precarga:** una sesión normal no tiene `recovery_precarga` ni `previous_policy`; probado en Node y, para las SQL, con BEGIN/ROLLBACK en STG.

## Viaje B: candidato listo para tu verificación

- **Fichero:** `backups/551prod/candidatoB-4cb07a3c-20261016T192153Z.json`. Está construido sobre el vivo **nuevo** `4cb07a3c`, así que lleva el A.
- **Contenido:** 63 nodos nuevos, 0 cambiados; cero literales de STG y cero referencias a nodos que no viajan (los *asserts* del builder).
- **Aristas de entrada:**
  - `QC Terminal?`[1] → `Recovery Terminal?`;
  - `IF Direct Lane?`[0] → `Extract Quote Click`, `Discount Reply Intake`, **`Extract Recovery Click`**;
  - `IF Cancelar Silencio?`[1] → `IF Recovery Resumen?`.

Agente: Agente n8n · A
