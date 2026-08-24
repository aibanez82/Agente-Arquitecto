# Informe #225 — el poller está VIVO y SANO en PROD; la aceptación quedó varada en Django

> Agente n8n → Arquitecto · 24 ago 2026 · Handoff: `2026-08-24-promover-poller-descuentos-a-prod.md` (GO 14:25 CDMX)
> **Bug abierto: `HYL-WAI#226`.** Timestamps en UTC salvo indicación.

## Resumen

El poller está promovido, verificado punto por punto contra la instancia y **activo desde las
20:44:17Z**, corriendo cada minuto sin un solo fallo. Hizo exactamente lo que su diseño manda:
reclamó la aplicación de Alberto en su primera ronda y la sondeó 8 veces. **La aceptación no se
cumplió — el mensaje no llegó — y la causa está medida y NO es del poller:** el worker de Django
tardó 81 minutos en dar su primer paso, más que toda la ventana de poll (~15 min), y la aplicación
quedó `uncertain` sin que nadie produzca la reconciliación que la rescataría. Detalle y preguntas
concretas en `HYL-WAI#226`.

Contexto de sesión: la sesión que ejecutó los pasos 1–2–4 y la activación se cortó sin ver el
desenlace; esta sesión retomó por barrido de arranque, completó la verificación (paso 3), midió el
desenlace y entrega.

## Línea por punto del handoff

| Punto | Estado |
|---|---|
| 1. Candidato con el builder, no parche | **HECHO.** `scripts/156/build-discount-worker.js` pasó a dos entornos (merge `a93b237`, suites en línea base). Candidato: `workflows/s1/discount-application-worker-candidato-prod.json`, sha256 `30df6f6e67203b3f2b09dd02f701663f1a489c3e8afc2e78ad03470dc6225f79`. |
| 2. Importar DESACTIVADO | **HECHO.** `QMjcrzfVaLOW29pC`, export inactivo commiteado (`c9fcf2b` en stg, `7b2cf0b` en main) antes de activar. |
| 3. Verificar en la instancia | **HECHO** (leído del GET vivo, no del fichero — tabla abajo). |
| 4. Fila en TARGETS en el mismo movimiento | **HECHO.** `3579d18` (stg) y `46e9a7e` (main), en el mismo movimiento que el import. |
| 5. Activar y dejar una ejecución real | **HECHO.** Activo 20:44:17Z; primera ejecución `9890` (20:46:11Z, success): reclamó la app 1 e inició el sondeo. 171+ ejecuciones success desde entonces, 0 errores. |
| Conteo de cola antes de activar | **1** — con matiz honesto: el instante exacto pre-activación no quedó registrado por el corte de sesión, pero `qualitas_discountapplication` usa id identity y su máximo es 1: **nunca existió más de una aplicación**. La condición «si hay más de una, para» no pudo violarse. |
| Aceptación (mensaje en el teléfono de Alberto) | **NO CUMPLIDA — varada en Django, no en n8n.** Ver abajo. |
| No tocar bot/copy/Metepec/landing | **RESPETADO.** Nada más se tocó. |

## Verificación en la instancia (punto 3), leída del workflow vivo

| Comprobación | Resultado |
|---|---|
| Nodos | 62 ✓ |
| `errorWorkflow` | `oTZ86TYMitK2bSur` (Error Handler de PROD) ✓ — fijado al importar; el candidato no lo lleva en `settings` |
| Postgres | credencial `FbodkhT9DijVcqpB` en los 16 nodos — la misma que usan los 5 workflows de PROD ✓ |
| Django | 4 URLs, todas `https://seguroautoqualitas.com/api/v1/discount-applications/…`, con `httpHeaderAuth` «Django N8N_TOKEN PROD» ✓ |
| WhatsApp | `phoneNumberId 1028815256982638` (WA Config Worker) + credencial «WhatsApp Send Message Hylant Account» — los de PROD ✓ |
| Cadenas `stg` | **0 reales.** El escáner literal da 96 coincidencias y todas son la subcadena dentro de «po**stg**res» (tipo de nodo y nombre de credencial). Revisadas una a una. |
| Candidato ≡ vivo | 62/62 nodos, **0 nodos con parámetros distintos**, conexiones idénticas ✓ |

## La aceptación, medida (cronología UTC)

| Instante | Evento |
|---|---|
| 20:10:19 | oferta registrada (`qualitas_discountapimutation` id 1) |
| 20:12:24 | Django crea la app 1: `state=queued`, `next_action=worker` |
| 20:44:17 | poller activo en PROD |
| 20:46:11 | ejecución `9890`: claim de la app 1, primer GET |
| 20:46–21:01 | 8 intentos; Django contesta `queued` las 8 veces (mismo `response_hash`) |
| 21:01:11 | `poll_status=uncertain`, `uncertain_reason=poll_budget_exhausted` (diseño `#156`: sin retry ciego) |
| 21:33:21 | el worker de Django reclama (`worker_fence=1`) y avanza: `awaiting_conversation` / `history_inheritance`, result_lead 2052, result_quote 3504 — 32 min DESPUÉS de que el poll se rindiera |

Desde entonces: el poller corre cada minuto y no reclama nada (correcto: no hay trabajo reclamable);
`n8n_discount_conversation_handoff` y `n8n_discount_delivery` con 0 filas; la vía de rescate
diseñada — una reconciliación en `qualitas_discountreconciliation` que
`n8n_discount_poll_consume_reconciliation` consumiría — está **vacía y sin productor conocido**.

## Lo que NO hice y por qué

- **No resetié la fila de poll.** Sería el retry ciego que el propio diseño del `#156` prohíbe, y una
  escritura en datos de PROD sin autorización. Si Django emite la reconciliación de la app 1, el
  poller la consume solo, sin tocar nada.
- No abrí ningún otro frente del handoff (bot, copy, Metepec, landing).

## Cabos administrativos

- Export del poller refrescado a `active:true` en `stg` (`da4d820`) y `main` tras la activación.
- **Defecto menor encontrado:** `scripts/lib_workflow_sync.py:72` lleva el trailer
  `Co-Authored-By: Claude Sonnet 5` **clavado en el código**, así que todo commit de sync miente
  sobre el modelo si la sesión no es Sonnet (los de hoy salieron así). Contradice la regla del
  trailer como único distintivo de agente. Propongo parametrizarlo; no lo toco sin rama y orden.

**Qué desbloquea la aceptación:** la respuesta de Juan a `HYL-WAI#226` (cadencia real del worker y
productor de reconciliaciones, o la reconciliación puntual de la app 1). En cuanto exista, el poller
de PROD termina el trabajo sin intervención.
