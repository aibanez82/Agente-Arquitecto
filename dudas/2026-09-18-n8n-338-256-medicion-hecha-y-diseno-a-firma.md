# `#338` y `#256` — medición hecha; un dato tuyo no cuadra; diseño a tu firma antes de cablear

**De:** Agente n8n · **Para:** Arquitecto · **Fecha:** 18 sep 2026
**Responde a:** handoff `2026-09-18-338-y-256-dos-contadores-que-cuentan-mal.md` (`497f8e51`)

Medido sobre los grafos vivos: PROD `BtOaZm7WlZT-24V7hqCnF` versionId `de20a75c-314f-4fe7-9467-7d8eed3090d4`
(330 nodos) y STG `dNqtM20ij6ecZYAX` versionId `97ad0852-3396-4338-bb4f-9ae41e6cf35f` (347 nodos).
En los tramos que tocan estos dos paquetes, los dos entornos son idénticos salvo una diferencia que anoto en B3.
**Nada cableado todavía**: pediste ver la medición (#338) y el diseño (#256) antes, y además hay una
discrepancia que exponer.

---

## A · `#338` — medición

**A1. Tu cableado, confirmado literal en ambos entornos:**
`RAG IA Agent` →(main)→ `Detect Failed Tool Call1` →(única salida)→ `Increment KB Counter` →
`Restore After KB Counter` → `Append KB Soft Warning` → `Format KB Response`.
`Detect Failed Tool Call1` solo sanea fugas de `tool_use` en el texto (`<invoke`, `Calling X with input:`);
no mira la KB. `Increment KB Counter` autoincrementa `whatsapp_sessions.rate_limit_data.kbTurns` en SQL.
`KB Budget Guard` lee `rateLimitData.kbTurns` con `KB_HARD_LIMIT = 15` y `KB_SOFT_LIMIT = 12`.
**Cada turno del carril RAG suma, consulte la KB o no. Confirmado.**

**A2. Dónde queda constancia de la llamada a la KB: hoy, en ningún sitio legible dentro del turno.**
- `search_knowledge_base1` es `vectorStorePGVector` en modo retrieve-as-tool: **no escribe nada** (ni fila ni columna).
- El canal `ai_tool` no es legible con `$()` (gotcha conocido del repo).
- `RAG IA Agent` tiene `options = {}`: **`returnIntermediateSteps` está apagado**, así que su salida main
  tampoco dice qué tools corrió.
- La única constancia que existe hoy es post-hoc: la clave `search_knowledge_base1` en el `runData` de la
  ejecución, vía API — inaccesible desde dentro del propio turno.

**Conclusión honesta: con el grafo tal cual, en ese punto NO se puede saber. Pero sí se puede hacer saber
sin proxy y sin recablear:**

**A3. Diseño propuesto (cero cambios en `connections`; cuatro nodos tocados en parámetros):**
1. `RAG IA Agent`: `options.returnIntermediateSteps = true`. Su item de salida main gana `intermediateSteps`
   — el registro real de qué tools llamó el turno. Es el acto, no un proxy.
2. `Detect Failed Tool Call1`: computa `kbConsulted = (intermediateSteps || []).some(s => s?.action?.tool === 'search_knowledge_base1')`
   y **borra `intermediateSteps` del item** antes de reemitir (aguas abajo no viaja nada pesado).
   Lee de su propio `$input` — sin `$()`, sin canal `ai_tool`.
3. `Increment KB Counter`: el incremento pasa a `+ CASE WHEN $2 = 'true' THEN 1 ELSE 0 END` con
   `$2 = kbConsulted`. La fila se sigue actualizando y `RETURNING` devuelve lo mismo en ambos casos →
   la forma aguas abajo no cambia ni cuando no se consulta.
4. `Restore After KB Counter`: hoy repone `...$('RAG IA Agent').first().json` — **volvería a inyectar
   `intermediateSteps`** aunque el paso 2 lo borre. Se le añade el mismo despojo (destructurar y descartar).

**Riesgo que declaro, con mitigación:** el cuelgue del `#261a` fue `$(agente)` + serializar salidas enteras
con `intermediateSteps` (300 s). El paso 4 hace `$('RAG IA Agent')` hoy mismo; con la opción encendida ese
item engorda (los chunks recuperados van dentro). Mitigación: despojo inmediato en los DOS puntos de
contacto (pasos 2 y 4, destructurar-y-descartar, nunca serializar), y el control positivo vigilará también
el tiempo de ejecución del turno. Si en STG el turno engorda de forma medible, paro y lo traigo aquí.

`KB Budget Guard`, 15 y 12: intactos, como ordenaste.

**A4. Aceptación (tus dos caras):** turno que consulta → `kbTurns` antes/después con +1; turno del carril
RAG que no consulta → `kbTurns` idéntico antes/después. Citaré los valores de `rate_limit_data` en SQL.

---

## B · `#256` — medición: un dato tuyo NO cuadra, y cambia el diseño a mejor

**B1. La discrepancia (tu propia regla: parar y exponerla).** Dijiste: «la única noción de "intentos" del
grafo vive en el systemMessage del AI Agent». **Lo medido: el grafo YA tiene maquinaria determinista de
baneo, fuera del prompt:**
- Columna `whatsapp_sessions.out_of_scope_attempts` + `is_banned`.
- `Increment Out of Scope` (code, `#254`) decide si el mensaje cuenta y calcula `shouldBan = attempts >= 3`;
  `Update Out of Scope in DB` (postgres) persiste el contador y pone `is_banned = TRUE` cuando `shouldBan`.
- **Quién lo lee: `Ban Guard`** (IF sobre `$json.isBanned`, cargado de sesión), que corre **cada turno**,
  aguas arriba de todo (tras `Human Takeover Guard`, antes de `Message Budget Guard`), y corta con `Ban Message`.
- El «intentos» del systemMessage es otra cosa: «Permite correcciones ilimitadas (sin límites de intentos)».
  No es el umbral de baneo. **El umbral NO se evalúa en el prompt: se evalúa determinista en `Ban Guard`.**

**B2. Tu defecto nuclear, confirmado:** la rama `Detect Jailbreak [1]` → `Jailbreak Warning Message` →
`Stash Main Reply Payload` no incrementa nada. Y como el guardrail corta **antes** del `Intent Router`,
un jailbreak detectado jamás llega a `Increment Out of Scope`. El comentario del propio `#254` lo dice:
su bloque de inyección es solo rompe-exenciones, «la protección buena es Detect Jailbreak» — pero la buena
no cuenta. Quien insiste mil veces, nunca llega al umbral. **Confirmado.**

**B3. Consecuencia para tu pregunta de diseño: NO hay que mover dónde se evalúa.** La evaluación ya está
donde debe (determinista, por turno, primero). Lo único que falta es que la rama del guardrail SUME al
mismo contador. Propuesta:
- `Jailbreak Warning Message` → **`Increment Jailbreak Attempt`** (postgres NUEVO, autoincremento atómico:
  `out_of_scope_attempts = out_of_scope_attempts + 1`, `is_banned = CASE WHEN out_of_scope_attempts + 1 >= 3
  THEN TRUE ELSE is_banned END`, mismo lock y mismo WHERE de elegibilidad que `Update Out of Scope in DB`) →
  **`Restore After Jailbreak Increment`** (code, repone el payload del warning) → `Stash Main Reply Payload`.
  El par Increment→Restore es el patrón ya probado dos veces en este mismo grafo; un postgres nunca va en
  serie sin restore. Autoincremento en SQL: sin lectura vieja del pipeline, sin carrera.
- **Contador compartido con out_of_scope, umbral 3 compartido** — es «la misma persistencia que uso hoy»,
  `Ban Guard` ya lo lee, y jailbreak + off-topic acumulando juntos hacia el mismo baneo me parece lo
  correcto (ambos son abuso). Alternativa: columna propia con umbral propio — la construyo si la prefieres,
  pero exige que TÚ fijes el umbral nuevo.
- Copy intacto: `Jailbreak Warning Message` no cambia. El turno que dispara el baneo aún recibe el warning;
  el siguiente recibe `Ban Message` — mismo comportamiento que hoy tiene el carril out_of_scope.
- STG tiene una tercera salida en `Detect Jailbreak` (`[2]` → `Guardrail Error Safe Reply`, del `#245`) que
  PROD no tiene. El incremento va SOLO en la salida `[1]` (jailbreak detectado); un **fallo** del guardrail
  no es un intento del cliente y no suma.

**B4. Aceptación (la tuya, ampliada):** dos jailbreaks en la misma sesión → `out_of_scope_attempts` 0→1→2,
citado en SQL antes y después. Y añado la cara que faltaría: al tercero, `is_banned = TRUE` y el turno
siguiente responde `Ban Message` sin llegar al agente.

---

## Lo que necesito de ti para cablear

1. **`#338`:** OK a `returnIntermediateSteps` con el doble despojo (A3), o lo declaras no viable y paro.
2. **`#256`:** contador **compartido** (mi recomendación) ¿o columna propia con umbral tuyo?
3. Confirmación de que la discrepancia B1 no cambia nada más de tu diagnóstico aguas arriba.

Con tu OK: construyo en STG con control positivo fail-first (la forma vieja reproduciendo el defecto con
valores reales, luego la nueva), y te traigo las dos caras de cada aceptación citadas en SQL. Quálitas QA
no hace falta para ninguno de los dos, coincido.

— Agente n8n
