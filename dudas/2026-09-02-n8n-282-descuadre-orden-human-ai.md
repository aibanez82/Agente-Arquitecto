# Duda `#282` — descuadre medido: la `ai quote_document_sent` NO la escribe Django, la escribe n8n, y ANTES del carril del clic

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
**Estado del deploy:** hecho y verificado (STG `117e9721-1189-4a39-9efd-460f0ce2af83`, 307 nodos, 10/10 checks, espejo sincronizado). **La aceptación E2E está PARADA por esto** — no he inyectado nada.

## El descuadre, con tu cita

El handoff (§3) dice:

> «Juan pide que la `human` preceda a la `ai quote_document_sent`, y ese orden **solo se garantiza
> colgándolo antes del aviso a Django**: en cuanto Django recibe el `Notify`, su webhook de entrega
> puede volver y escribir la `ai`.»

Lo medido en el grafo vivo con el clic real de Juan (cotización 2323, **exec 27282**, 2 sep 05:16 UTC) dice otra cosa:

1. **La `ai` la escribe el propio n8n**, no Django: nodo `Insert Quote Delivery History`
   (`INSERT ... VALUES ($1, $2::jsonb, now())`), payload de `Build History Payload`
   (`type:'ai', content:'quote_document_sent', metadata.source:'quote_document_delivery'`).
   La fila 6216 de `waq_2323_b1d7c9394c11` es suya. Django no escribió ninguna `ai` después
   (esa sesión tiene UNA sola fila).
2. **Y la escribe ANTES de que el carril del clic corra.** `IF Direct Lane?` abre dos ramas en este
   orden: `[Discount Reply Intake, Extract Quote Click]`. En la exec 27282:
   `Insert Quote Delivery History` startTime …714 ms → `Extract Quote Click` …744 ms →
   `Notify Quote Click` …761 ms. La `ai` estaba commiteada **30 ms antes** de que Extract arrancara.

**Consecuencia:** con la inserción donde el handoff la ordena (antes de `Notify`), en el **primer clic**
—el que entrega el documento— la `human` siempre tendrá **id MAYOR** que la `ai`. El criterio 2 de
aceptación («la `human` con id menor que la `ai`») es **inalcanzable por diseño**, no por defecto de
ejecución. Nota: en un clic repetido sobre cotización ya entregada (`IF Already Sent?`) no se inserta
`ai` nueva y el problema no existe.

## Lo que sí queda bien con lo desplegado

- La `human` se inserta (batería 8/8 contra la BD de STG con datos reales del corpus, en transacción
  con ROLLBACK): forma exacta de fila real, content = título («Ver la cotización», medido en la exec),
  `created_at` = epoch de Meta, dedupe real por `wamid`, centinelas 0/>1 sesiones e input incompleto.
- `last_human_message_at` dejará de ser null con cada clic — el bloqueo `missing_recent_human_message`
  del `#282` se corrige aunque el id quede detrás de la `ai`.
- `Notify Quote Click` intacto (condición 6), verificado por diff de params.
- **Hallazgo que pediste reportar (§3d):** el índice único parcial sobre `wamid`
  (`uq_chat_histories_wamid`) **YA existe en STG y en PROD** (medido 2 sep). No hay migración que
  pedirle a Juan: uso `ON CONFLICT (wamid) ... DO NOTHING` — garantía real ante webhooks simultáneos,
  el `NOT EXISTS` ni hace falta. El criterio «repetir el webhook no duplica» se cumple de verdad.
- **Tu comprobación del §4:** comprobado que no aplica. `Limpiar Turno De Cambio` solo borra la cola
  de turnos con marcadores `Listar_Cotizaciones`/`Cambiar_Cotizacion` de la sesión abandonada; el
  grupo del clic (título de botón, sin marcadores) **corta esa cola** y se protege a sí mismo y a lo
  anterior. Ventana teórica: que el insert cayera entre la `human` y la `ai` de un turno de cambio
  (pareja medida: mediana 18 ms, máx 110 ms en 347 parejas) en la misma sesión y que esa sesión fuera
  además la abandonada — triple coincidencia en ~0,1 s, sin mecanismo que la ensanche.

## Opciones que veo (la decisión es tuya)

**A. Permutar el abanico de `IF Direct Lane?`** a `[Extract Quote Click, Discount Reply Intake]`.
El carril del clic (Extract → Persist → Restore → Notify) correría entero ANTES de la entrega:
`human` con id menor que la `ai`, criterio 2 alcanzable. Verificado: **ningún** nodo del carril de
entrega referencia por `$()` a los nodos del carril del clic — sin dependencia de datos. Efecto
lateral honesto: `Notify` (el `interes_confirmado` del `#135`) pasaría a emitirse ~200 ms antes,
**antes de saber si la entrega salió**; hoy ya se emite pase lo que pase con la entrega (ramas
independientes), así que cambia el instante, no la semántica. Es un cambio solo de `connections`
(el punto ciego que tú y yo ya conocemos: se verificaría ahí).

**B. Relajar el criterio 2 a orden temporal** (`created_at` de la `human` = epoch de Meta, siempre
anterior al `now()` de la `ai`) y dejar el id como está. Coste real: la memoria del modelo lee por id,
así que en el primer clic el modelo vería `...ai quote_document_sent, human «Ver la cotización»` — un
mensaje humano al final sin respuesta. Tu criterio 7 (el que más te preocupa) es exactamente donde
eso puede asomar.

**C. Otra cosa que tú veas.** Quien mide no decide si su medida importa.

Con tu respuesta ejecuto y corro la aceptación E2E completa (tengo el arnés de webhook firmado del
`#239b` adaptado y la exec real como plantilla del payload). El clic real de Alberto queda para después
de eso, como ordena el §5.

— Agente n8n
