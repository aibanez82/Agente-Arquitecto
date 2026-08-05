# S2 — Propuestas de diseño pre-freeze del Arquitecto (DOCS-ONLY)

> **4 ago 2026, ~21:45Z.** Complementa `s2-prep-offline.md`. Objetivo: que la reconciliación y el
> freeze de S2 (que Juan hará al cerrar S1, contrato S2 §6.1) encuentren resueltos en papel los
> tres nudos que nuestras 10 ambigüedades (`#135 c.5183415931`) señalaron como duros. Cero
> código; se publica en `#135` al cierre de S1 con OK de Alberto.

## 1. Reconciliación S1 v1.1 → S2 (lo que el §2 del contrato S2 exige incorporar)

S1 v1.1 (`aef501f`, congelado) fija la identidad que S2 consume:

- `session_id` exacto + tabla de derivación `identity_mode` (legacy/shadow/v2) + formato
  `waq_<cotizacion_id>_<12hex>` + teléfono = SOLO transporte. La frase de S2 "session_id exacto
  conforme a S1" ya tiene semántica concreta y probada (35+239 tests de conformidad).
- **Evaluación de materialidad (nuestra lectura):** nada del cierre S1 contradice la semántica
  S2; los cambios son insumos a favor. S2 v1.0.0 puede congelarse sin nueva versión si la
  autoridad resuelve A5 y A2 como aclaraciones (o errata acotada), que es lo que las propuestas
  de abajo permiten.
- **Piezas S1 reutilizables en S2 (mismo dueño, mismo patrón):** `Dashboard lib/s1/resolve.js`
  (resolución exacta con cardinalidad fail-closed) es la base natural de la consulta de control
  por sesión; el patrón de errores aditivos `HTTP + code` del builder Retomar es la plantilla
  para los errores de control; el patrón "artefacto normativo por hash + suite offline con
  stubs + fail-first" es la forma de conformidad ya validada dos veces.

## 2. Propuesta — resolución canónica de control (resuelve nuestra ambigüedad #3 y la dependencia de S2-F6)

**Problema:** la interfaz `IA | HUMANO | METEPEC` no existe en ningún repo; n8n lee Postgres
directo por arquitectura; acoplar cada turno del bot a un endpoint HTTP en Vercel añade latencia
y un modo de fallo nuevo.

**Propuesta (dos capas, una sola verdad):**
1. La verdad es `dashboard_conversation_claims` (state + `control_id` + `epoch`, ya acreditada).
2. El dominio Dashboard publica como **artefacto contractual versionado por hash** una
   **consulta canónica SQL** (una sola sentencia, parametrizada por `session_id`) que devuelve
   `control ∈ {IA, HUMANO, METEPEC}` o error fail-closed (`CONTROL_AMBIGUO` si >1 activo,
   `NO_DISPONIBLE` si la consulta falla). n8n la ejecuta read-only tal cual (mismo patrón que el
   fixture por hash: el texto de la consulta ES la interfaz; cambiarla = cambio contractual).
3. El Dashboard sirve además su endpoint HTTP para UI/consumidores humanos, implementado sobre
   la MISMA consulta.

**Por qué así:** cero segunda verdad (la semántica vive en un artefacto único), n8n conserva su
vía de acceso arquitectónica sin nuevo SPOF, y la conformidad de ambos consumidores se prueba
contra el mismo texto. El fail-closed queda definido en la consulta, no en cada consumidor.

## 3. Propuesta — `fact_id` estable sin outbox (resuelve A2, la tensión §3.3 vs §1.3)

**Propuesta principal — derivación determinista, cero almacenamiento nuevo:**
`fact_id = UUIDv5(namespace_s2, session_id + fact_type + serialización canónica del bloque
persistido)`. Propiedades: un retry del MISMO hecho lógico (mismo bloque persistido) reproduce el
mismo `fact_id` sin guardar nada (no hay outbox → §1.3 intacto); un bloque corregido produce
`fact_id` nuevo — y eso es correcto: un contenido distinto ES un hecho nuevo, no un retry
(`duplicate=true` queda reservado a reintentos idénticos, que es su semántica en §3.3). La
objeción de A2 ("un cambio de contenido rompe duplicate") se disuelve: no debe haber
`duplicate=true` para contenido distinto.
**Alternativa si la autoridad prefiere almacenamiento explícito:** anotación aditiva en
`whatsapp_sessions.captured_data` (JSONB ya existente, ownership n8n, sin DDL) con los `fact_id`
emitidos por bloque. Pedimos que el freeze elija una de las dos formas.

## 4. Propuesta — mirrors `human_takeover`/`metepec_derived` (resuelve A5, la material)

**Problema:** el contrato asume mirrors derivados del canónico con fail-closed ante
contradicción; la realidad es la inversa (los escriben los workflows n8n) → con uso normal, la
contradicción sería el estado permanente y el bot quedaría mudo.

**Propuesta — acotar el fail-closed en S2, migrar la escritura en S3/S4:**
1. En S2, los mirrors se declaran **legacy no-autoritativos y NO comparados**: la resolución
   canónica decide SOLO con el dominio claims; el fail-closed por contradicción aplica DENTRO del
   dominio (dos activos, fencing roto, indisponibilidad), no contra los mirrors. (El contrato ya
   dice que los mirrors "no se consultan de forma aislada para conceder autoridad" — esta
   propuesta solo retira además su uso como fuente de contradicción.)
2. La migración de los escritores (workflows Atención Humana/Metepec → operar contra la fuente
   canónica, y el mirror pasa a derivado o se retira) se ordena en **S3/S4**, que es donde esos
   workflows están en alcance — con S5 retirándolos si se demuestra no-uso.
3. Ventaja: S2 queda congelable sin tocar el flujo operativo vivo de Alberto y sin el modo de
   fallo "bot mudo permanente"; la dirección correcta de los mirrors se corrige exactamente en la
   etapa que toca esos workflows.

## 5. Estado de preparación S2 al freeze (inventario)

Listo: brechas mapeadas por dominio (`s2-prep-offline.md`) · inventario n8n (`b104b1f`) · diseño
de suite (18 tests F1/F2/F6) · 10 ambigüedades publicadas (`#135 c.5183415931`) · estas 3
propuestas de diseño. Pendiente de Juan: cierre S1 → reconciliación → freeze → handoffs.
**PUBLICADO en `#135 c.5187242434` (5 ago 03:4xZ, orden directa de Alberto)** — antes del cierre
de S1 (aún en reauditoría r6), encuadrado como insumo DOCS-ONLY para la reconciliación §6.1, sin
pedir acción y con constancia de stand-down intacto.
