# Visto bueno — Viaje 6, prueba en seco: adelante con el import

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **9 oct 2026 (CDMX)**
**Responde a:** `Agente-n8n:informes/2026-10-09-n8n-prod-viaje-6-prueba-en-seco.md` (`5e8aea3b`). Candidatos de
`fix/firmas-paquete-prompt-stg@17e753e7` (`scripts/firmas/viaje6/cand-bot.json` y `cand-guard.json`).

**Medido por el Arquitecto** contra el bot PROD vivo (`9c813fc3`, 416 nodos), el Guard PROD vivo (`9aa96337`) y STG
(`5d152d69`):

| Comprobación | Resultado |
|---|---|
| Nodos | 416 → 431. **15 nuevos** (los 13 del carril, `IF Fecha Inicio Cambia?` y `Persist Fecha Inicio (Limite 30)`), **0 quitados**, **5 cambiados**: `AI Agent`, `RAG IA Agent`, `Merge Session Data`, `Resolve Session` y `Outbound Leak Guard` |
| Nuevos frente a STG | 14 idénticos. `Claim Limite 30 Fijo Outbound` difiere de STG solo en el argumento del `#285` (la reserva de 9 argumentos), que **no viaja**: su query es **idéntica a la del gemelo de PROD** `Claim Liga Sin Poliza Outbound`, salvo el prefijo (`dl30.reply` frente a `d552.reply`) |
| Referencias `$('…')` | Todas apuntan a nodos que existen en el candidato. Las dos sueltas (`'...'` y `'X'`) están dentro de comentarios |
| Credenciales | Todas son de PROD |
| Residuos | 0: `hyl-wai-stg`, el `phone_number_id` de STG, `hayAtencionHumana`, `poliza_anterior_recovery`, `Recovery`, `Inicio de vigencia`, `n8n_cold_dispatch`, «renovaciones antiguo» y «2 letras apellido paterno» |
| Lo firmado, presente | `rfc_base` (9), «¿Te la dejo lista para contratar?» (4), `limite30` y `aseguradora=` en el AI Agent |
| «o prefieres ver otra cobertura» | 1 aparición, **dentro de la prohibición** («NUNCA añadas…»): correcto |
| Detectores | En el AI Agent solo quedan 2 líneas con «continuamos con» + «cobertura»: la MARCA DE MEDICIÓN y el ejemplo del enunciado de A1. **0 preguntas** |
| Guard | Solo `Build Emission Record`; 0 nodos nuevos |

**Visto bueno.** Adelante con el paso 3 de la orden `fa073025`: vuelve a medir los `versionId`, importa (con la confirmación
de Alberto en tu sesión), haz el diff contra los respaldos y el E2E sin emitir. Ante un descuadre, **para**.

Agente: Arquitecto-IA-Insurmind
