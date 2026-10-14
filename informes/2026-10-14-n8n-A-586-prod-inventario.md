# Informe · Agente n8n · A · #586 a PROD: inventario antes del PUT

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-orden-prod-586.md` (`119df2c9`). **Base: PROD `4b9eaf42`**, re-medida.

## Una diferencia con STG que tienes que saber

**En PROD no existe el carril «Persona Fija»** (la retención no viajó), y es de donde se clonó en STG el carril «Cancelar Fijo». Para PROD, el carril se **clona del de «Despedida Fija»** (`#418`, que ya está en PROD y **va directo a su `Send`**, sin la cadena del `#577`).

**La lógica es la misma de STG:**
- `cancelar.js`, copia literal: B → A → silencio, con la adenda 7;
- el mismo `Cancelar Fijo Copy`;
- fence `d586.reply`, fila `ai` `cancelar_fijo_586`;
- el mismo escritor del contador y el mismo silencio.

**Lo que cambia son los parámetros heredados del nodo de origen:** el Send con su forma de envío, el Settle y la fila `human`. Por eso los hashes de varios nodos no coinciden con los de STG. La fila `human` (`c589a715`) y el `Insert` (`b85a871a`) sí son idénticos.

**Prueba funcional de esta variante** (`scripts/586/prueba-586-prod-stg.py`): `cambio_586_prod.py` aplicado a una copia temporal del respaldo de STG `5adf0e57`, que es anterior a la retención y al `#586`, tiene la despedida y no la persona, como PROD. Sin envíos.
- secuencia real «Cancelar» ×4 + una pregunta: **B → A → silencio → silencio → normal, 3/3**, sin cierres;
- seguimiento con oferta: no entra, 3/3;
- «quiero cancelar mi póliza»: no entra, 3/3.

**No viaja:** la pausa (espera a Juan), el `#608`/`#609`, la llamada, la retención, el `#577`/`#605` ni Sonnet 5.5.

**Dependencias de PROD que no hay:** ninguna. Todo lo que referencia el carril existe en PROD: `Merge Session Data`, `Session Resolution`, `Session Context Builder`, `WA Config`, `Buffer Mark Done` y la credencial de Postgres de PROD (heredada del nodo de origen).

## Inventario (medido sobre `4b9eaf42` con `cambio_586_prod.py`)

```
BASE 4b9eaf42-bf81-4c81-a2bd-fbfd3d0f1261
NODOS NUEVOS (17):
  - Build Cancelar Fijo AI Row · code · 0368d3af
  - Cancelar Fijo Copy · code · d9a7dc9a
  - Cancelar Fijo Fence Denied · code · 18dee16c
  - Cancelar Silencio 586 · code · 945713f5
  - Claim Cancelar Fijo Outbound · postgres · bfad71af
  - IF Cancelar Fijo? · if · 84d963a1
  - IF Cancelar Silencio? · if · bdf1dbaf
  - IF Send Cancelar Fijo? · if · 7079248e
  - Insert Cancelar Fijo Turn History · postgres · b85a871a
  - Mark Cancelar Fijo AI Suppressed · postgres · 5bc43948
  - Mark Cancelar Fijo Persist Failed · postgres · 2653431a
  - Persist Contador Cancelar 586 · postgres · 4c7f1830
  - Persist Human Row (Cancelar Fijo) · postgres · c589a715
  - Persist Human Row (Cancelar Silencio) · postgres · c589a715
  - Send Cancelar Fijo Reply · httpRequest · 19d37de3
  - Settle Cancelar Fijo Sent · postgres · dcd1b17c
  - Settle Cancelar Fijo Uncertain · postgres · 12714862
NODOS CAMBIADOS: ['Merge Session Data', 'Resolve Session']
--- Resolve Session.query · insert · PROD 29-28 → 29-37 · #586 · 9 líneas nuevas
+     -- #586 · de dónde viene ese último mensaje del bot (un seguimiento de Django, una respuesta fija…) y con qué alternativa.
+     (SELECT ch.message->'metadata'->>'source' FROM n8n_chat_histories ch
+       WHERE ch.session_id = ws.session_id AND ch.message->>'type' = 'ai'
+         AND COALESCE(ch.message->>'content', '') NOT LIKE 'Calling %'
+       ORDER BY ch.id DESC LIMIT 1) AS prev_ai_source,
+     (SELECT ch.message->'metadata'->>'alternative' FROM n8n_chat_histories ch
+       WHERE ch.session_id = ws.session_id AND ch.message->>'type' = 'ai'
+         AND COALESCE(ch.message->>'content', '') NOT LIKE 'Calling %'
+       ORDER BY ch.id DESC LIMIT 1) AS prev_ai_alternativa,
--- Merge Session Data.jsCode · insert · PROD 1-0 → 1-29 · #586 · 29 líneas nuevas
+ // #586 · «Cancelar» al seguimiento · fuente: scripts/586/cancelar.js (copia LITERAL).
+ // #586 · «Cancelar» al seguimiento de Django (handoff 2026-10-14-A-firmas-orden-prod-591-y-cola §2d + respuesta de la duda). Textos firmados.
+ // cancelarFijo({ chatInput, prevAiSource, prevAiAlternativa, estado }) → { texto: 'B'|'A', copy } | null
+ //  · Solo si el ÚLTIMO mensaje del bot es el propio carril (cancelar_fijo_586, adenda 7) o un seguimiento de Django (metadata.source = django_checkpoint_followup_v06) SIN oferta de
+ //    descuento (alternative ≠ discount_offer: ese «Cancelar» es el botón dsc:v1:…:decline del carril de descuentos, de la sesión B).
+ //  · El cliente responde «Cancelar» (solo eso, con o sin puntuación).
+ //  · Primera vez en la conversación → B (firmado por Alberto); la siguiente → A (el texto del «Cancelar» del descuento en PROD).
+ //    Desde el 3.º → silencio (adenda 4). Nunca el mismo mensaje dos veces. Sin modelo, sin enlace y sin cerrar la sesión.
+ const TEXTOS_586 = {
+   B: 'Entendido. ¿Es por el precio o te quedó alguna duda de la cobertura? Si prefieres dejarlo aquí, no pasa nada: tu cotización queda guardada.',
+   A: 'De acuerdo, dejamos tu cotización tal como está. Si cambias de idea, aquí sigo.',
+ };
+ function esCancelar(texto) {
+   const t = String(texto || '').split('=== USER INPUT ENDS ABOVE ===')[0].toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
+     .replace(/[^a-z\s]/g, ' ').replace(/\s+/g, ' ').trim();
+   return t === 'cancelar';
+ }
+ function cancelarFijo({ chatInput, prevAiSource, prevAiAlternativa, estado } = {}) {
+   // adenda 7 (QA, exec 95069): tras la B el último mensaje del bot es el PROPIO carril (cancelar_fijo_586), no el seguimiento.
+   const previo = prevAiSource === 'cancelar_fijo_586' || (prevAiSource === 'django_checkpoint_followup_v06' && prevAiAlternativa !== 'discount_offer');
+   if (!previo) return null;
+   if (!esCancelar(chatInput)) return null;
+   const e = estado || {};
+   if (!e.b) return { texto: 'B', copy: TEXTOS_586.B };
+   if (!e.a) return { texto: 'A', copy: TEXTOS_586.A };
+   // adenda 4: desde el 3.er «Cancelar», SILENCIO (ya recibió la B y la A; la regla 3 prohíbe repetir). Sin modelo, sin cierre, sin enlace.
+   return { texto: 'S', silencio: true, copy: '' };
+ }
+ 
--- Merge Session Data.jsCode · insert · PROD 413-412 → 442-448 · #586 · 7 líneas nuevas
+ // #586 · «Cancelar» al seguimiento de Django (cancelar.js): B una vez, A la siguiente, después silencio; contador en sesión.
+ try {
+   const sr586 = ($('Session Resolution').first().json || {}).sessionRow || {};
+   output.cancelarFijo = ('prevAiTexto' in output && !output.humanTakeover) ? cancelarFijo({ chatInput: output.chatInput,
+     prevAiSource: sr586.prev_ai_source || null, prevAiAlternativa: sr586.prev_ai_alternativa || null,
+     estado: ((output.sessionData || {}).capturedData || {}).cancelar586 || {} }) : null;
+ } catch (e) { output.cancelarFijo = null; }
CONEXIONES cambiadas/nuevas: ['Build Cancelar Fijo AI Row', 'Cancelar Fijo Copy', 'Cancelar Fijo Fence Denied', 'Cancelar Silencio 586', 'Claim Cancelar Fijo Outbound', 'IF Cancelar Fijo?', 'IF Cancelar Silencio?', 'IF Despedida Fija?', 'IF Send Cancelar Fijo?', 'Insert Cancelar Fijo Turn History', 'Mark Cancelar Fijo AI Suppressed', 'Mark Cancelar Fijo Persist Failed', 'Persist Human Row (Cancelar Fijo)', 'Persist Human Row (Cancelar Silencio)', 'Send Cancelar Fijo Reply', 'Settle Cancelar Fijo Sent', 'Settle Cancelar Fijo Uncertain']
  IF Despedida Fija? [no] → ['IF Cancelar Fijo?'] (antes ['IF Identity Intent?'] )
```

**Los tres hunks son del `#586`:**
- `Resolve Session`: +9 líneas, `prev_ai_source` y `prev_ai_alternativa`;
- `Merge Session Data`: +29 líneas al principio, la copia literal de `cancelar.js`;
- `Merge Session Data`: +7 líneas, el bloque `output.cancelarFijo`, tras el de la despedida.

**Conexiones:** las del carril, más **`IF Despedida Fija?` [no] → `IF Cancelar Fijo?`**, que antes iba a `IF Identity Intent?`. Desde el carril, el «no» de `IF Cancelar Silencio?` vuelve a `IF Identity Intent?`.

Script de import: el de los viajes (`scripts/viajes-prod/`) con esta causa. Espero tu verificación antes del PUT.

— Agente n8n · A
