# Informe #552 — «mándame la liga» sin póliza: lo contesta el grafo con el texto de Alberto (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-552-mandame-la-liga-antes-de-emitir.md`, con tu respuesta a mi duda (opción A).
**Estado:** aplicado en STG y aceptado **4/4 + turno siguiente con memoria**. **PROD no está tocado.**

## versionId y diff

**Bot STG:** `4b1bf2f4` → **`3ca60723`** (424 → 437 nodos). Respaldo: `backups/552/bot-stg-4b1bf2f4-20261008T000142Z.json`.

**`Parse Router Output`/jsCode:** añade el flag `ligaSinPoliza` = petición explícita de liga && sin
`sessionData.policyData.numero_poliza`. **`routedIntent` no cambia.**

**Una desviación que declaro.** Te dije «`esPeticionExplicitaDeLiga` sin cambios», pero la medición la desmiente: **la frase
literal del incidente, «Ok mándeme la liga para pagar», no la reconoce** esa función. Su lista de verbos no tiene la forma de
usted. Para el flag del #552, y **solo para él**, añadí `mandeme|envieme|paseme|compartame|deme`, con las mismas condiciones de
liga y pago. El override y el enrutado del #207 no cambian.

**IF `IF Liga Sin Póliza?`** (entre `Parse Router Output` e `IF Identity Intent?`). Con el flag a true, entra en un **carril
calcado del guard del descuento**: copias de sus nodos, con los mismos tipos, versiones, credenciales y `onError`.
- **Copy y reserva:** `Liga Sin Poliza Copy` (texto literal) → `Claim Liga Sin Poliza Outbound`. Es la consulta de
  `Claim Main Reply Outbound` verbatim, con `dispatch_id` `s1.d552.reply.<sha del wamid>` y la identidad de `Session Resolution`.
- **Envío:** `IF Send Liga Sin Poliza?` → `Persist Human Row (Liga Sin Poliza)`, la fuente única del #342 verbatim (12.º
  consumidor) → `Send Liga Sin Poliza Reply` → `Settle … Sent`/`Uncertain`.
- **Memoria:** `Build … AI Row` → `Insert … Turn History`. La fila `ai` **solo tras `Sent`**.
- **Fallos:** `Mark … AI Suppressed`, `Mark … Persist Failed` y `… Fence Denied` → `Buffer Mark Done`, el nodo existente.

**Diff contra el respaldo:**
- hojas: solo `Parse Router Output/jsCode` y las de los 13 nodos nuevos;
- connections: solo `Parse Router Output` y el carril;
- los dos `systemMessage` intactos; el workflow activo.

**El caso (b), con póliza, no cambia.** **Código:** rama `fix/552-liga-sin-poliza`, `scripts/552/`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **PASS** | Teléfono de Alberto, sesión `waq_2387_1d683b2274f5` (`greeting`, sin póliza): «Ok mándeme la liga para pagar». **80987**: `ligaSinPoliza=true` → carril → «Aún me faltan algunos datos tuyos para poder emitir, y después te genero el link de pago.», enviado (`Settle Liga Sin Poliza Sent`). En `n8n_chat_histories`: fila **human** «Ok mándeme la liga para pagar» (`client_message_342`) y fila **ai** con el texto (`liga_sin_poliza_552`). |
| 1-sig | **PASS** | Turno siguiente, «ok, la amplia» (**80989**): no entra al carril; el agente (`RAG IA Agent`) retoma la selección con la memoria del turno anterior: «¡Perfecto! Tu Amplia anual queda en $10,117.62 MXN con cobertura completa…». |
| 2 | **PASS** (como hoy) | Sesión `waq_2300_ca72522f2cb9` con póliza `7620101917`: «mándame la liga de pago». **80991**: `ligaSinPoliza=false` → `AI Agent` → `Ensure Payment Link`. Django STG devolvió el mismo 503 que en el #289 y el bot dio el texto de error temporal. El carril no intercepta. |
| 3 | **PASS offline** | `Parse Router Output` nuevo: con póliza, `ligaSinPoliza=false`, también en `payment_pending`. Sin petición de liga («¿cómo puedo pagar?», «hola») → false. «mi link de pago», «Me envía el link de pago» y «envíeme la liga para pagar por favor» → true (sin póliza). 7/7 en `scripts/552/probar-parse-router.js`. |
| 4 | **PASS** | Diff: arriba. |

**Sesiones:** `waq_2387` y `waq_2300`, fijadas como `active` solo durante su caso; las dos **cerradas** al terminar.

— Agente n8n
