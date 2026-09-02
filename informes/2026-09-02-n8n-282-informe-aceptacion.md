# Informe `#282` — el clic del Quick Reply ya es un mensaje del cliente (STG). Aceptación por arnés: **7/7**

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
Handoff `2026-09-02-282-el-clic-tambien-es-un-mensaje.md` + respuestas `4716f8a` (opción A) y `9a384db` (coordenadas + alarma).

## 1 · Estado final del vivo

| | valor |
|---|---|
| Bot STG | `dNqtM20ij6ecZYAX`, versionId **`79ffebf2-24b3-4836-a3ed-9c112651bfb4`**, **307 nodos**, active |
| Cadena de versiones | `9d98ed2e` (base handoff) → `117e9721` (carril) → `90d7f718` (abanico, inerte pero inocuo) → `79ffebf2` (posición) |
| Espejo | `workflows/WhatsApp Insurance Quotation Bot_stg.json` en `origin/stg`, sincronizado tras cada PUT |
| Scripts | `scripts/282/`: `build-282-clic-es-mensaje-stg.py`, `fix-282-permutar-abanico-stg.py`, `fix-282-posicion-carril-stg.py`, `inyectar-clic-282-stg.py`, `verificar-orden-282-stg.py` + respaldo de `9d98ed2e` |

**Diff contra el respaldo `9d98ed2e`** (medido en cada verificación post-PUT):
- `parameters`: **solo** `Extract Quote Click` (ampliado: wamid/inboundTs/buttonTitle; guard `qc:` intacto por invariantes; aviso de posición funcional) y `Discount Reply Terminal` (pasajero: comentarios `#8542`→`#239`).
- Nodos nuevos (2): `Persist Click Human Row` (postgres, fail-open hacia Notify), `Restore Click Payload` (code).
- `connections`: `Extract → Persist → Restore → Notify`; abanico de `IF Direct Lane?` con salida 0 = `[Extract Quote Click, Discount Reply Intake]` (tu tabla del §3: 5/5).
- Posición: `Extract Quote Click` `[-4212, 1440]` → `[-4212, 400]` (**funcional**, gotcha 38); nada más se movió (verificado: dif_pos == [Extract]).
- `Notify Quote Click`: **byte a byte idéntico** (condición 6), verificado en los tres PUT.

## 2 · Las siete filas, medidas (arnés firmado, forma calcada de la exec real 27282)

Clic inyectado sobre la cotización 2316 (sesión activa del teléfono de prueba), exec **27930**:

| # | Criterio | Medido | PASS |
|---|---|---|---|
| 1 | exactamente una `human` y una `ai` | `human` 6224 «Ver la cotización» + `ai` 6225 `quote_document_sent` | ✅ |
| 2 | `human` con id menor | **6224 < 6225** (con la posición y=400; antes del arreglo: 6221<6222 al revés) | ✅ |
| 3 | mismo `session_id`, el de la cotización | las dos en `waq_2316_76c8e149a2fc`, resuelta por `payload_v1` | ✅ |
| 4 | `created_at` = timestamp de Meta | `2026-09-02 16:00:54+00` = epoch `1788364854` inyectado (insert real ~16:00:56) | ✅ |
| 5 | reenviar el mismo webhook no duplica | exec 27923: mismo wamid → `duplicado_wamid`, sigue **1** fila; la re-entrega tampoco se repite (`IF Already Sent?` corta por wamid) | ✅ |
| 6 | exactamente un `interes_confirmado` | 2316 sigue en **1** tras tres Notify — Django dedupe, `#135` intacto | ✅ |
| 7 | turno siguiente normal, sin comentar la fila | abajo, pegado | ✅ |

**Criterio 7, literal** (texto inyectado: «ya me llegó, gracias»):

> fila 6226 `human`: `=== USER INPUT ===  ya me llegó, gracias`
> fila 6227 `ai`: **«¡Con gusto, José! Aquí sigo cuando quieras continuar con tu contratación 🙂»** `[phase:greeting]`

No comenta la fila nueva; al contrario, el clic en su memoria es lo que hace inteligible el «ya me llegó». La fila del clic mejora el contexto, no lo ensucia.

## 3 · La alarma que pediste (§3 de 9a384db)

`scripts/282/verificar-orden-282-stg.py`, read-only, sale 1 si se viola:
- **estático**: `y(Extract) < y(Discount Reply Intake)` en el grafo vivo — la palanca real del v1;
- **dinámico**: `startTime(Extract) < startTime(Discount Reply Intake)` en la última exec de clic.

Corrida tras el arreglo: `OK estático (400<620)` + `OK dinámico (exec 27930: …855924 < …856360)`.
Defecto concreto que atraparía (criterio `#179`): el arrastre en la UI que reordena sin diff. El nodo lleva además el aviso **POSICIÓN FUNCIONAL** en `jsCode` y en `notes`.

## 4 · Hallazgos que quedan escritos

- **Gotcha 38** (`docs/gotchas-n8n.md`): en `executionOrder v1` el abanico se ordena por posición de lienzo (top-left first), no por `connections`; el orden solo lo prueba el `startTime`.
- **ORDER BY id confirmado en implementación**: `@langchain/community@1.1.27` (catálogo de n8n@2.28.7), `dist/stores/message/postgres.js:85`.
- `uq_chat_histories_wamid` existe en STG y PROD — sin migración pendiente con Juan.
- Comprobación §4 del handoff: `Limpiar Turno De Cambio` **no aplica** (el grupo del clic corta la cola; ventana teórica ≤110 ms, medida sobre 347 parejas).

## 5 · Lo que queda, y de quién es

- **El clic real de Alberto sobre cotización nueva + mensaje normal detrás** — tu criterio 7 de verdad, el que no firma un arnés. Todo listo para cuando lo ordenes.
- PROD: nada tocado, como manda el §6 del handoff. El viaje lo ordenas tú con este informe delante. Nota para ese día: en PROD el abanico de `IF Direct Lane?` y las posiciones parten de otra base — la pieza de posición se mide allí, no se copia.
- Efectos del arnés sobre el teléfono de prueba (ya avisados): 2 re-entregas del PDF de la 2316 y una respuesta del bot.

— Agente n8n
