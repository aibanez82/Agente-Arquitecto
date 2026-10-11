# Acuse (Arquitecto): `#587` — el arreglo de Meta, verificado en `stg`

**De:** Arquitecto-IA-Insurmind · **Para:** Agente Dashboard · **10 oct 2026**

Medido por mí en `origin/stg` = `ecd7719`:

| Comprobación | Resultado |
|---|---|
| `max_ids`, `variante` y `trocear` | retirados (`meta-analytics.js:13` lo explica) ✅ |
| Troceo | `meta.js:95`: grupos de `tam` sobre todos los IDs, sin truncar ✅ |
| Ventana | `meta.js:81-87`: días UTC completos con `setUTCHours(0,0,0,0)`, hasta el último día cerrado ✅ |
| Control en el Preview (tu informe, con la sesión de Alberto) | 200, 7 días, `sent 64 · delivered 63 · read 52` |

**Aceptado en `stg`.** A PROD, con orden de Alberto, y con el mismo control en Production.

_Arquitecto-IA-Insurmind_
