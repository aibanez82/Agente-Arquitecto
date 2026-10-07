# Informe #289 — «ya está pagada» no es «no hay liga»: rehecho sobre el STG vigente (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-289-ya-pagada-no-es-sin-liga.md`, con tu respuesta a mi duda (opción A).
**Estado:** aplicado en STG. La lógica está acreditada offline. **El caso 2 en vivo es NO COMPROBABLE**: Django STG devuelve
503 `temporarily_unavailable` para las pólizas pagadas de prueba, nunca `already_paid`. **PROD no está tocado.**

## versionId y diff

**Bot STG:** `1b55efa8` → **`4b1bf2f4`**. Respaldo: `backups/289/bot-stg-1b55efa8-20261007T234927Z.json`.

**Solo los dos consumidores. El `systemMessage` no se toca** (opción A):
- **`Ensure Payment Link`/`toolDescription`:** + la frase de `already_paid` del PR #109. Medido: el texto vivo es **exactamente**
  el del PR sin esa frase, y el nuevo es **idéntico** al `TOOL_DESCRIPTION` del PR.
- **`Payment Status Reply`/`jsCode`:** + la rama `already_paid` **exacto**: `200` y body con una sola clave
  `status: 'already_paid'` → «Tu pago ya está confirmado y no tienes nada pendiente».
  - Va **insertada en el código vivo**. No copié el del PR, porque el vivo cambió después: el comentario de la rama final
    ahora dice «pagado-desconocido: nunca inventar pagado».

**Diff contra el respaldo:**
- hojas: exactamente esas dos;
- el resto de nodos idénticos; las connections idénticas;
- los dos `systemMessage` intactos y el workflow activo.

**Código:** rama `fix/289-already-paid-stg-vigente` (`583025d9`), `scripts/289/`.

**PR `#109`: cerrado sin fusionar**, con un comentario que enlaza la rama nueva.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS 7/7 offline** | No uso el builder del #207 sobre los exports: el cambio se aplica al vivo, con su prueba. Resultados de `Payment Status Reply`: `200 already_paid` exacto → la frase. `200 already_paid` + campo extra → ruta vigente, sin afirmar pagado. `201 already_paid` → ruta vigente. `200 available` → la liga. `202 preparing` → «estoy generando». `200 not_available` y `503` → «déjame confirmarte». La `toolDescription` es idéntica a la del PR. |
| 2 | **NO COMPROBABLE en STG** (2 intentos) | Teléfono de Alberto, «Me mandas mi liga de pago por favor». **80969** (póliza 1552, sesión `waq_2382`) y **80972** (póliza 1421, sesión `waq_2302`): el modelo llamó a `Ensure Payment Link` y **Django STG devolvió `503 {"status":"temporarily_unavailable"}`**. El bot respondió el texto de error temporal: correcto ante un 503 y sin liga. Django no llegó a decir `already_paid`, probablemente porque `_accredit_local_ledger` no acredita la autoridad del ledger para estas pólizas antiguas de STG (`_LEDGER_UNAVAILABLE`). No lo forcé más ni toqué tablas de Django. |
| 3 | **No ejercido** | **80970** (póliza 1618, sesión `waq_2189` reabierta solo para la prueba): la sesión estaba en `summary_confirmation`, el modelo entendió que no había póliza emitida y **no llamó a la tool**. Sin regresión en lo que sí se ve: la rama `available` está intacta (offline) y la de error (casos 2 y 2b) se comporta igual que antes. |
| 4 | **PASS** | Diff: arriba. |

**Sesiones:** `waq_2382`, `waq_2302` y `waq_2189`, fijadas como `active` solo durante su caso; las tres **cerradas** al terminar.

## Lo que no pude comprobar

- **`already_paid` de punta a punta.** Haría falta una póliza que Django STG acredite como pagada en el ledger vigente, o
  probarlo en PROD con una pagada real cuando viaje. Tampoco pude medir si, **sin la línea del `systemMessage`**, el modelo
  dice la frase literal o la resume. Queda pendiente para cuando haya un `already_paid` real. Si la resume, la línea del
  prompt va a la firma de Alberto, como dijiste.

— Agente n8n
