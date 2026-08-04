# S2 — Preparación offline del Arquitecto (contrato APROBADO, no congelado)

> **Fecha:** 4 ago 2026 · **Autorización:** enmienda Contract-First `#140 c.5174994247` §9 (la
> preparación S2 puede ocurrir en paralelo con S1 porque no modifica código, datos ni ambientes)
> + publicación del contrato `#135 c.5175335674` + instrucción directa de Alberto (4 ago:
> "arranca todo lo que se pueda hacer en nuestra cancha sin dependencias").
>
> **Guardrails vigentes (esto NO es implementación):** cero cambios de código/workflows/schema/
> grants/datos en cualquiera de los tres repos; `Agente-n8n@fd8fa75` (rama `feature/s1-dual-stg`)
> permanece INMÓVIL; no se publica nada en los trackers de Juan; el freeze y el handoff de
> implementación S2 los emite el liderazgo Seguroauto al cerrar S1.

## 1. Identidad del contrato — verificada contra la fuente

- Artefacto: `aguayo-co/HYL-WAI:docs/contracts/s2-estados-control-minimos-v1.md`
  @ `af57580e298e4cc2b3206db3f9136d479e9b9a6c` (596 líneas).
- SHA-256 descargado y verificado por el Arquitecto (4 ago):
  `ff106e8904321ef9f5c2331549452b60e1db62ec8378d3f9fc7b333c6799f498` — **coincide exacto** con el
  publicado en `#135 c.5175335674`.
- Estado: `APROBADO`, no `CONGELADO`. Revisión independiente única ya consumida (4 bloqueantes,
  todos cerrados). Bloqueado por cierre de S1 (`#132`).
- Dependencia S1: contrato `S1-DUAL-STG@1.0.0` (`7ac2aa8`, sha256 `a1366175…`), nuestra
  conformidad n8n `fd8fa75` con **PASS offline** (`#132 c.5180485645`).

## 2. Qué nos asigna S2 (ownership §5.2, resumen operativo)

| Dominio nuestro | Obligación contractual | Fixtures |
|---|---|---|
| **Agente-n8n** | presentar solo hechos permitidos (§4.2) con la interfaz lógica §3.3 (`fact_id` idempotente, identidad S1 exacta, evidencia sanitizada); NO enviar `target_state`; consultar control canónico antes de IA/efectos cuando S3/S4 lo autoricen | S2-F1, S2-F2 (negativo obligatorio), S2-F6 |
| **Dashboard** | dueño de la resolución canónica `IA \| HUMANO \| METEPEC` por `session_id` exacto; exclusividad, transferencia, liberación, fencing, fail-closed | S2-F4, S2-F5 |

Django (Juan) es la única autoridad de `Lead.estado`; nosotros jamás lo escribimos.

## 3. Análisis de brecha — dominio Agente-n8n

Estado actual (a confirmar con el inventario delegado al Agente-n8n, handoff
`Agente-n8n:handoffs/2026-08-04-s2-prep-offline-inventario-hechos.md`):

1. **No existe interfaz de "hecho comercial"**: hoy n8n persiste `captured_data` en
   `whatsapp_sessions` (SQL directo) y llama endpoints Django (validación de datos, emisión) sin
   `fact_id`, sin semántica de replay (`duplicate=true`) ni resultado
   `previous_state/current_state`. **Gap principal:** adaptador de presentación de hechos
   (§3.3) — probablemente un nodo/subworkflow nuevo que empaqueta "bloque persistido y validado"
   con `fact_id` UUID estable y referencia sanitizada, contra el conducto físico que Django
   defina en su handoff.
2. **S2-F2 NO es el fix del #69** (corrección al análisis inicial, aportada por el inventario del
   ejecutor y **verificada por el Arquitecto contra los JSON el 4 ago**): en el export STG
   (`origin/stg:workflows/…Bot_stg.json`) el `[phase:completed]` de la IA ya está bloqueado con 3
   barreras (prompt del `AI Agent` + `VALID_PHASES` sin `completed` en ambos Phase Extractor +
   exclusión SQL en `Update Phase in DB`); la única escritura de `completed` es Payment
   Confirmation con `headerAuth`. **PERO en el export PROD (re-export 26 jul, `7b93365`)
   `VALID_PHASES` AÚN INCLUYE `completed` y no existe la barrera SQL** → #69 sigue abierto con
   razón: falta promover el fix a PROD (acción viva, requiere autorización/clasificación). S2-F2
   exige además algo distinto: que `PAGO_CONFIRMADO` no sea *expresable* por el adaptador de
   hechos (allowlist cerrada de `fact_type`, sin `target_state`), estilo gramática `qc:` de S1.
3. **Gate de control (S2-F6) — DOS puntos, no uno:** el inventario del ejecutor demostró que
   colocarlo solo ante el agente deja dos bypasses con efecto externo real: (A) `Phase Guard`
   →`Completed Session Response`→`Send message` (sesión completed recibe respuesta fija con
   humano al mando) y (B) toda la rama de entrega de PDF por quick-reply, aguas arriba de
   `Merge Session Data`. Propuesta G1 (ante `quoteDocumentAction?`) + G2 (`Fallback Flag`→
   `Merge Session Data`), ambas aristas `main` puras — cadena LangChain (`ai_*`) intacta. Cubre
   también `qualitas-issues#57`.
3b. **El único conducto n8n→Django de escritura va SIN credencial** (verificado por el Arquitecto
   en `Issue Policy Guard_stg.json`: `Call Issue Policy Real` a `POST /api/emitir-externo/` sin
   `authentication`/`credentials`, mientras los dos GET sí usan `httpHeaderAuth`; la emisión E2E
   del 28 jul funcionó así). Choca de frente con §3.3 ("Django infiere el productor de la
   autenticación") y §5.4.6. Implicación de seguridad lado Django pendiente de decisión de
   Alberto (borrador en `s2-borradores-para-decision.md`).
4. **Vocabulario conservado:** `greeting…completed` no se renombra; cero migración de fases.
5. La suite de conformidad S2 puede ser espejo estructural de `scripts/s1/` (sandbox offline,
   134/134 como precedente) con F1/F2/F6.

## 4. Análisis de brecha — dominio Dashboard

Base acreditada (entrega del Agente Dashboard, 28 jul, STG): `dashboard_conversation_claims` ya
tiene `control_id` UUID + `epoch` monotónico por sesión + `state`
(`active/released/revoked/expired`) + índices únicos parciales
(`uq_claims_active_session/lead WHERE state='active'`) + claim/release con fencing
(`DELETE exige control_id+epoch`). El propio contrato lo reconoce: "la implementación humana
actual ya acredita `control_id + epoch`" (§4.3.4). Gaps:

1. **METEPEC no existe** en el dominio: hay que elegir la representación aditiva (p. ej. columna
   `control_type` en claims, o tabla hermana) — decisión del dueño (§3.2), sin segunda verdad.
2. **Resolución canónica como interfaz consultable:** hoy la semántica vive en joins internos de
   `inbox.js`/`claim.js`; falta el punto único (endpoint o consulta versionada) que devuelva
   exactamente `IA | HUMANO | METEPEC | error fail-closed` por `session_id`.
3. **Transferencia HUMANO↔METEPEC** (§4.3.5): operación serializable nueva, fencing nuevo al
   destino, sin estado observable con ambos activos. Hoy no existe.
4. **Mirrors:** hallazgo del 28 jul — el Dashboard NO escribe `human_takeover` (no hay doble
   escritura que mantener); los mirrors (`human_takeover`, `metepec_derived`) viven del lado n8n.
   La contradicción mirror↔canónico debe fallar cerrada (§4.3.1) — definir la comparación en la
   resolución canónica.
5. **Estado de ramas:** la evolución claims está en la rama/Preview `stg` del Dashboard, no en
   `main`; el contrato inspeccionó `Dashboard stg@e50e3ad`. Al handoff habrá que declarar SHA
   base exacto.

## 5. Borrador de ambigüedades para presentar al freeze (formato §8: cláusula + ejemplo + impacto)

1. **§3.3/§4.2 — hechos para sesiones legacy:** la presentación exige `session_id` "identidad
   exacta conforme a S1" y `lead_id` requerido; una sesión legacy sin `schema_version=1` (frontera
   resuelta en S1 §12.3) puede carecer de lead verificable. ¿Los hechos comerciales aplican SOLO a
   identidad v1, o hay camino legacy? Impacto: cobertura de S2-F1 en conversaciones reales viejas.
2. **§3.3 — autenticación de productor:** "Django lo infiere de la autenticación". Hoy n8n→Django
   usa `N8N_TOKEN` compartido (y su rotación es autoridad exclusiva de `#130`). ¿Basta la
   credencial actual como identidad de productor o se exige credencial por productor? Impacto:
   dependencia cruzada con #130 que conviene declarar antes del freeze.
3. **§4.3.1 — transporte de la consulta de control para n8n:** n8n lee Postgres directo por
   arquitectura. ¿Una consulta SQL versionada sobre las tablas del dominio Dashboard cuenta como
   "resolución canónica" si implementa exactamente la semántica (incl. fail-closed), o debe pasar
   por una interfaz servida por el Dashboard (HTTP)? Impacto: latencia/disponibilidad del gate en
   cada turno del bot y el modo de fallo de S2-F6.
4. **§4.3.6/S2-F6 — alcance del fail-closed en S2:** "consultar control antes de IA/efectos cuando
   S3/S4 lo autoricen". ¿La conformidad S2 del gate se acredita solo offline (suite) quedando el
   bot en producción/STG sin consultar hasta S3, o S2 ya exige el gate activo en STG? Impacto: si
   la fuente cae con gate activo, el bot deja de responder a todos — hay que decidir ese trade-off
   explícitamente, no heredarlo.
5. **§4.3.4 — fencing en transferencia:** ¿el `epoch` del destino continúa la secuencia monotónica
   de la sesión (implementación actual: `MAX(epoch)+1` por sesión) o reinicia por control? La
   propiedad exigida se cumple con la primera; pedimos confirmación de que es aceptable como
   "garantía equivalente" también para METEPEC.

**+5 del ejecutor Agente-n8n** (inventario `Agente-n8n@b104b1f:docs/s2/prep-inventario-hechos.md`,
sin solaparse con las anteriores):

6. **A1 (§4.2/§4.1):** ¿"persistido y validado" exige validación en n8n ANTES de persistir, o
   basta la fila y Django revalida? Hoy los 4 writers (`Save Group1/2/3 Progress`,
   `Save Policy Data`) toman valores de `$fromAI(...) || 'N/A'` sin validación — una fila con
   `nombre='N/A'` es indistinguible de una real.
7. **A2 (§3.3 vs §1.3) — tensión interna del contrato:** el `fact_id` estable entre retries exige
   persistirlo (= un outbox mínimo, excluido por §1.3) o derivarlo del contenido (y un cambio de
   contenido rompe `duplicate=true`). Tal como está redactado, no hay opción limpia.
8. **A3 (§4.3/§4.4):** ¿"antes de IA/efectos" incluye los efectos deterministas que NO pasan por
   el agente (PDF quick-reply, respuesta fija de sesión completed)? Decide si el gate va en uno o
   en dos puntos (ver §3.3).
9. **A4 (§4.1/§7.2):** ¿qué bloque nuestro es el "primer bloque de emisión" de S2-F1
   (`grupo1/2/3`, `policy_data`)? Sin ese mapeo el fixture no es comprobable desde n8n.
10. **A5 (§4.3.1/§5.3) — LA MATERIAL:** el contrato asume que los mirrors (`human_takeover`,
    `metepec_derived`) son derivados del canónico del Dashboard; en la realidad la dirección está
    invertida — los escriben los workflows `Atención Humana`/`Metepec` de n8n y el Dashboard no
    se entera. En cuanto Alberto use la atención humana actual, la contradicción mirror↔canónico
    es el estado NORMAL, y el fail-closed literal deja al bot mudo permanente. Exige decisión
    pre-freeze: (a) n8n deja de escribir mirrors (rompe el flujo operativo vivo) o (b) el
    canónico se deriva de ellos (invierte el contrato).

## 6. Diseño borrador — suite de conformidad n8n S2 (sin código todavía)

Espejo de `scripts/s1/` (sandbox, sin red, sin BD viva): `scripts/s2/test/*.test.js` con
(a) F1: presentación de hecho con `fact_id` estable → retry idéntico ⇒ mismo resultado,
`duplicate=true`, cero mutación; (b) F2: construcción de `target_state`/promoción por
`completed` ⇒ el adaptador la rechaza ANTES de salir (el fixture debe fallar si pasa);
(c) F6: stub de resolución canónica devolviendo indisponible ⇒ gate bloquea IA/efectos y no
degrada a mirrors ni a teléfono. Los comandos exactos se registran en el handoff (§7.3).

## 7. Estado y siguiente paso

- ✅ Contrato verificado por hash; brechas mapeadas; **10 ambigüedades** consolidadas (5 Arquitecto
  + 5 ejecutor, verificadas las afirmaciones de base contra los JSON).
- ✅ Inventario n8n entregado (`Agente-n8n@b104b1f`): diseño de suite S2 completo (6 tests F1 +
  5 F2 + 7 F6, espejo de `scripts/s1/`), mapa de gate en dos puntos, conducto de escritura sin
  auth. Dependencia declarada: la resolución canónica de control no existe aún en ningún repo —
  la conformidad F6 se hará contra stub hasta que el dominio Dashboard la sirva.
- ⏳ **Decisiones de Alberto pendientes** (borradores en
  `docs/iniciativas/s2-borradores-para-decision.md`): publicar las 10 ambigüedades en `#135`
  (ahora, para des-riesgar el freeze) o esperar al handoff; y qué hacer con el hallazgo de
  `emitir-externo` sin credencial.
- ⏳ El freeze S2 + handoffs los emite Juan al cerrar S1.
