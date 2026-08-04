# Enmienda Contract-First — S1–S5 sustituye C2–C5 (4 ago 2026)

**Fuente autoritativa:** `aguayo-co/HYL-WAI#140` c.5174994247 (2026-08-04T05:27:42Z, oilycoyote). Acuse nuestro: `#132` c.5175006814.

## Qué cambió

- **C0/C1 cerradas, no se reabren.** **S1 sustituye C2–C5**: se elimina la matriz extensa, los clones especiales, los canarios, las 3 matrices consecutivas y la observación prolongada.
- **Método Contract-First obligatorio** para S1–S5: contrato (funcional/datos/transición/integración) → revisión independiente → freeze con versión+commit+fingerprint → handoff → implementación por dueño sin redefinir → conformidad → prueba integrada básica → PASS/FAIL contra el contrato.
- **Secuencia y trackers:** S1 Dual STG (#132) → S2 estados/control mínimos (#135) → S3 Atención Humana básica (#128) → S4 Metepec básico (#143) → S5 limpieza comprobable (#146). C6 amplia diferida en #147; secretos siguen en #130.
- **Estimaciones orientativas** (primera vez que el plan del lado Juan las incluye): 1–3 días por etapa, 5–11 días total tras los freezes.

## Implicaciones para este lado (efectivas ya)

1. **Stand-down en S1**: Alberto/Arquitecto/ejecutor NO desarrollan, corrigen, despliegan ni ejecutan nada de S1 hasta el **freeze del contrato S1/C2 + handoff explícito** en #132. La responsabilidad inicial es del liderazgo (redactar el contrato).
2. **`1161dcf` congelado como insumo**: ni aceptado ni rechazado; sin auditoría bajo la matriz anterior; reutilizable solo si cumple el contrato congelado. La rama `feature/c2-matriz-nucleo-dual` no se mueve.
3. **Las 4 pruebas de S1**: conversación normal · dos cotizaciones mismo teléfono sin cruce · Payment modifica máx. 1 conversación · replay sin duplicar. Si pasan, **Dual permanece habilitado en STG** (ya no hay "volver a shadow" obligatorio salvo fallo).
4. **Docs de este repo parcialmente superseded** por la enmienda: `c3-c4-prep-offline.md` (la parte C4/canario; el inventario de schema sigue siendo insumo válido para el contrato S1), `c2-checkpoint-ventana-DRAFT.md` (la ventana de matriz ya no existe; la precondición de esquema verificada sigue siendo insumo). No se borran: se conservan como insumos ofrecidos en el acuse.
5. **Qué esperar a continuación:** comentario de freeze del contrato S1/C2 en #132 + handoff con nuestro trabajo exacto (probable: DDL/bootstrap de tablas propiedad n8n, acreditaciones del lado n8n, artefactos de `1161dcf` que el contrato reutilice).

## Nota de registro (4 ago 23:11Z) — movimiento de `feature/c2-matriz-nucleo-dual`

El ejecutor n8n empujó `ca015e0`+`6a0f93f` ("port-132: versionar exports STG del build") sobre esa rama, bajo autorización de Alberto registrada en el propio commit ("commit y push de todo, 2026-08-04"). Contradice literalmente el punto 2 ("la rama no se mueve"), pero: los commits son solo aditivos (`scripts/port-132/build/` + `.gitignore`), no tocan los artefactos de la matriz C2; el insumo `1161dcf` sigue íntegro como SHA; y la rama candidata r2 `feature/s1-dual-stg@fb98f24` permanece inmóvil. Riesgo técnico: nulo. Riesgo narrativo: el monitor de Juan puede observar movimiento durante la revisión r2 — clasificación preventiva en #132 pendiente de OK de Alberto. NO resetear la rama (un force-push sería más ruidoso que el movimiento mismo).

## Contexto temporal (para el registro, sin inferir causalidad)

La enmienda llegó horas después de que este repo publicara las auditorías forenses SRC-ALBERTO-C1-002 (`docs/auditorias/C1-auditoria-primaria.md`) y SRC-ALBERTO-C1-003 (`docs/auditorias/C1-genesis-economia.md`) y de que el ejecutor publicara su testimonio (`Agente-n8n@ea30bad`). La entrega C2 `1161dcf` (23:02Z) y el ping (01:20Z aprox.) quedaron sin acuse bajo la matriz anterior; la enmienda los resuelve por sustitución.
