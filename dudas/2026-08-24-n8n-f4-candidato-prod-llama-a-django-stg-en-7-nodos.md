# F4 — el candidato PROD llama a Django de STG en 7 nodos: falta la fila de URL en la tabla

> Agente n8n · 24 ago 2026 · **Bloqueante del paso 3 (regenerar candidatos).** Los pasos 1 y 2 están
> hechos; no sigo con el 3 sin tu decisión, porque cambia el artefacto más allá de lo que el
> handoff ordena.

## Estado de la fase al escribir esto

| Paso | Estado |
|---|---|
| 1 · Error Handler PROD | **HECHO** — id `oTZ86TYMitK2bSur`, 7 nodos, activo, 01:32:49 UTC. Credencial nueva `vQRRtc5qegPhKvCd` (`n8n API PROD (Error Handler)`, httpHeaderAuth para el self-call a la API; la creó Alberto en su shell). Telegram → `HjpZPCiP7NgG5dMs` (chatId 357953725, el mismo del Monitor), WhatsApp → `PbzXr53disA74eew`, URL del fetch → `https://n8n.srv1325340.hstgr.cloud`, rótulo de alerta «n8n PROD». |
| 2 · Issue Policy Guard PROD | **HECHO** — id **`SEKpp6E4gggaHj11`**, 5 nodos, activo, 01:33:50 UTC. URL verificada leída de la instancia: `https://seguroautoqualitas.com/api/emitir-externo/` (misma ruta que STG, host de PROD — el del `Issue Policy` vivo). `settings.errorWorkflow` → `oTZ86TYMitK2bSur`, timezone `America/Mexico_City`. |
| 3–5 | **PARADOS** por lo de abajo. |

Fuentes: los exports `_stg` de los dos, verificados espejo del vivo de STG por hash semántico antes de traducir.

## El hallazgo

`main-candidato-prod.json` contiene **7 nodos que llaman al Django de STG**
(`hyl-wai-stg-d1085ad74dbf.herokuapp.com`) — idéntico al candidato STG, porque `entornos.js` **no
tiene fila de URL base de Django** y el test del espejo solo acredita que los candidatos no difieren
fuera de la tabla; no puede saber que las URLs deberían diferir. Medido nodo a nodo:

- **2 regresiones** de nodos que el vivo de PROD ya tiene apuntando a `seguroautoqualitas.com`:
  `Get Quotation Data` (httpRequestTool) y `Fetch Quotation Document` (httpRequest).
- **5 nodos nuevos** que nacerían llamando a staging: `Resolve Discount Offer`,
  `Fetch Discount Catalog`, `Query Discount Availability`, `Create Discount Offer`,
  `Save Quotation Selection` — el carril de descuentos entero contra datos de STG.

Importar el candidato así mezclaría datos de staging en conversaciones de producción. Es la misma
familia que el hallazgo 1 de F3 (el guard por id de instancia), pero esta vez sin columna en la tabla.

## Lo que propongo, si lo validas

1. Fila nueva en `entornos.js`: `DJANGO_BASE_URL = { stg: 'https://hyl-wai-stg-d1085ad74dbf.herokuapp.com', prod: 'https://seguroautoqualitas.com' }`, y que `aplicarEntorno()` la traduzca (con la misma disciplina de abortar si el host aparece fuera de los nodos esperados).
2. La fila `workflowRefs` que el paso 3 ya ordena: `Issue Policy` → `{ stg: 'PuogahK4qv9YOiF4', prod: 'SEKpp6E4gggaHj11' }`.
3. `ERROR_WORKFLOW.prod` = `oTZ86TYMitK2bSur` (documental, como la fila STG).
4. Regenerar, actualizar el test del espejo (la diferencia URL pasa a estar en la tabla), `--check`, y publicar sha256 nuevo del candidato PROD.

Todo por rama `feature/` → merge a `stg` (Regla 1 del #179: ese merge es mío), y entonces sigo con
los pasos 4 y 5 del orden obligatorio.

## Una lectura que te pido confirmar de paso

El paso 4 («importa el resto por delta medido») lo leo como: **PUT de settings a los 4 auxiliares
vivos** (Monitor, Atencion Humana, Retomar, Payment) para poner `errorWorkflow` →
`oTZ86TYMitK2bSur` preservando todo lo demás — que es lo que cuadra con la verificación
(«errorWorkflow en los cinco») y con el aviso de que el reemplazo arrasa settings. Si «el resto»
incluye otra cosa (¿candidatos de payment/retomar?, hoy solo existen en sabor STG), dímelo antes.

Quedo parado en el 3. Con tu respuesta ejecuto en el momento.
