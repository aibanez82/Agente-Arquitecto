# Informe — SESIÓN A · `#551` viaje B a PROD: el carril Recovery (63 nodos) ACTIVO

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md` + adendas 1, 3, 6 y 7.
**Confirmación de Alberto en mi sesión:** «Sí, importa».

| Workflow PROD | Antes → después |
|---|---|
| Bot `BtOaZm7WlZT-24V7hqCnF` | **`4cb07a3c`** (base medida de nuevo) → **`a75c713e-c16f-4bde-90de-b2051e0f8a77`** (538 nodos) |

- **Candidato:** `import-551-prod.py B`, con fuente STG `b321eb6c`.
- **Respaldo:** `backups/551prod/prod-4cb07a3c-prePUTB-….json`.

## Después del PUT

| | Medido |
|---|---|
| Nodos | 63 nuevos (los del inventario), 0 cambiados, 0 quitados |
| ¿Igual al candidato que verificaste (`192153Z`, adenda 7)? | **sí**: parámetros, credenciales y `connections` idénticos |
| Aristas de entrada | `QC Terminal?`[1] → `Recovery Terminal?`; `IF Direct Lane?`[0] + `Extract Recovery Click`; `IF Cancelar Silencio?`[1] → `IF Recovery Resumen?` |
| Activo | sí |

**Espejo:** `main` y `stg`.

## Control (adenda 3)
**El primer envío real a un teléfono nuestro.** Lo que hay que mirar en esa ejecución:
- entrada por `IF Direct Lane?` → `Extract Recovery Click` (el botón de la plantilla);
- `Call Recovery Quote Context` contra `seguroautoqualitas.com` → 200;
- `Validate Recovery Envelope` con la precarga;
- `Send Recovery Document` con el PDF;
- después, la conversación con el `[CTX:]` (`faltan`/`precargado`).

## Pendiente (punto 2, arnés en STG): un hallazgo
- **Qué pasa.** Caso (i), solo faltan género y nacimiento: en el tercer turno, «Nací el 15/06/1985 y no requiero factura», el bot pide **el RFC con homoclave** en vez de usar la base del sistema y pasar al resumen.
- **Hipótesis, sin confirmar:** la `rfc_base` se calcula en `Merge Session Data` al empezar el turno, antes de que se guarde la fecha que acaba de llegar, así que en ese turno no hay base.
- **Lo que no he medido aún:** si en el turno siguiente se corrige solo.
- **El resto de casos:** te los paso en el informe del punto 2 cuando acabe.

Agente: Agente n8n · A
