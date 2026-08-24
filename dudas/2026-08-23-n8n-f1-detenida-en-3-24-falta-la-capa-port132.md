# F1 DETENIDA en la 3/24: las 24 no bastan — falta la capa port-132 (2 funciones + 1 trigger)

> Agente n8n · 23 ago 2026 · **F1 parada con 2/24 aplicadas, nada a medias.** Bloqueante para continuar.

## Estado exacto de PROD ahora mismo

- **Hora UTC de arranque (ancla PITR, reloj del servidor): 2026-08-24 00:00:01 UTC.**
- `156/001` — **APLICADA y commiteada** (íntegra): ensanchados `lead_id`/`quotation_id` a bigint en
  `whatsapp_sessions` y `whatsapp_sessions_archive`, `human_takeover`/`metepec_derived` ya estaban,
  `paridad_final=OK`. Aditiva pura, sin nada que revertir.
- `156/002` — **APLICADA y commiteada**: `CREATE VIEW conversation_control_v1` + COMMENT.
- `156/003` — **ABORTADA POR SU PROPIA GUARDA, rollback completo, nada escrito**:
  `STOP/PRE: falta public.n8n_port132_canonical_phone(text)`.
- `004`–`163/001` — **sin tocar**. No seguí aplicando, como ordena el handoff.

## El hueco, medido

- Las 24 crean **43** nombres de función `n8n_*`. STG tiene **45** nombres (48 filas con 3 overloads).
- Los 2 que faltan y que las 24 SOLO consumen: **`n8n_port132_canonical_phone`** (10 de las 24 la
  usan; la guarda de la 003 la exige) y **`n8n_chat_histories_advisory_lock`** (la función de trigger).
- Su DDL no está en `migrations/`: vive en
  `feature/issue-132-port-dual-safe:scripts/port-132/db/schema/objetivo/07_n8n_chat_histories_lock_trigger.sql`,
  que además **instala `trg_n8n_chat_histories_advisory_lock` sobre `n8n_chat_histories`** — y ese
  trigger está **activo en STG** (verificado: `tgenabled=O`).
- O sea: el objetivo de 48 con el que se midió STG incluye la capa port-132, y el handoff F1 solo
  ordena las 24.

## La decisión que no me corresponde

El trigger **cambia comportamiento vivo**: es fail-closed — puede OMITIR inserts de historial
(sesión inexistente, generación cambiada) del `Postgres Chat Memory` del bot **actual** de 119 nodos,
no solo del candidato de F4. Opciones que veo, sin recomendación de ejecutor:

1. **Aplicar el 07 completo** (2 funciones + trigger): deja PROD en paridad real con STG; toca el
   comportamiento del bot vivo hoy.
2. **Solo las 2 funciones, sin trigger**: desbloquea las 22 restantes y llega a 48/45 en el
   recuento; `canonical_phone` es IMMUTABLE pura y una función de trigger sin trigger es inerte.
   Pero el 48 dejaría de significar «paridad de comportamiento con STG», y habría que decidir si el
   trigger entra en F4 o nunca.
3. Otra cosa que tú veas.

Punto de gobernanza: el `#210` («Tú las haces») autorizó *las migraciones de la capa S1*; el 07 no
está en esa lista y el *schema stewardship* de Juan (`#157`) probablemente alcanza a un trigger
sobre una tabla que Django también escribe. Si hay que re-preguntar a Juan, es antes de tocar.

Quedo parado. Con tu respuesta ejecuto en el momento — la conexión y el mecanismo ya están
verificados (001 y 002 pasaron limpias).
