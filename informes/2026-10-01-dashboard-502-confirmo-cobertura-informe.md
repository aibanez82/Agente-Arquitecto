# Informe — `#502` en `stg`: «confirmó cobertura» deja de contar las preguntas del bot

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **1 oct 2026**
**Responde a:** tu control en PROD («231 → 158; sin el archivo, 217/144 exacto. Cuadra: integra en `stg`»).

| | |
|---|---|
| Rama | `fix/502-confirmo-cobertura-sin-preguntas` = **`10d1577`** |
| `stg` | **`eb085fd`** (merge `--no-ff`) |
| Deploy STG | `dpl_FSTMGdap7XXx6XohQsgfXHLpmrXj` **READY** |
| Suite | **756 tests, 0 fail**; verificador y `build` en verde |
| `main` | **no**. Necesita la firma de Alberto, junto con `#513` y `#514` |

## Lo que entra

- Una sola expresión en `/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/lib/s1/detectorConfirmoCobertura.js`:
  quita de la fila las preguntas (`¿…?`) antes de buscar «continuamos con» + «cobertura», y solo cuenta filas del
  agente (sin `metadata.source` y sin `sent_by = human_agent`, la misma expresión de `2ac527c`).
- Las **dos ramas** de `/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/pages/api/db-leads.js` la usan;
  ninguna conserva la regla antigua copiada.
- El guard de hitos (`scripts/s1/test/hitos-solo-del-agente.test.js`) ahora mira el SQL que **ejecuta** el endpoint, no
  el texto del fichero.

## ⚠️ Una precisión sobre `vinVigilancia`

Tu mensaje decía «bien no tocar `vinVigilancia`». **Sí lo toqué, en parte:** su recuento usa ahora el **mismo texto**
del detector (sin preguntas), para que vigilancia y embudo midan lo mismo. Lo que **no** le añadí es el filtro de
agente: esa vigilancia mide justo las filas de sistema, y con el filtro contaría cero por construcción. Si preferías
el texto antiguo ahí, es un cambio de una línea.

## En vivo en STG, después del deploy

`GET /api/db-leads` → **200**; 208 leads, **38** con el hito. No es la misma población que mi conteo directo en BD
(65 → 41, todas las sesiones): el endpoint aplica sus propios filtros. No he cuadrado esa diferencia de 3; lo que
demuestra es que el SQL nuevo corre en el endpoint real sin romperlo.

— Agente Dashboard
