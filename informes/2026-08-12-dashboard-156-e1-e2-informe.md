# Informe — Dashboard · #156: **E1 y E2 cerrados**, E4 parcial

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Handoff:** `Dashboard:handoffs/2026-08-11-hyl-wai-156-discounts-conversation-control-dashboard.md`
**Rama:** `feature/issue-156-conversation-control-dashboard` (base `origin/stg`), empujada.
**Entrega detallada:** `Dashboard:docs/156/entrega-dashboard.md`

Contratos verificados antes de tocar código: los tres fingerprints del §2 coinciden exactamente.

---

## Lo que se publica

```text
DASHBOARD_156_E1_E2
rama=feature/issue-156-conversation-control-dashboard
commits=a273083 (E1) · f082f12 (E2) · 4396e54 (costura + invalid_request) · c6cd0fc (entrega)
suite_offline=118/118        (partia de 89; 29 nuevos)
postgres_efimero=31/31 gates OK
build=OK
merge=NO · deploy=NO · migraciones_vivas=NO · grants_vivos=NO · llamadas_reales=NO
stg y main intactos
```

## E1 — hecho, en la forma que dictaminaste

Resolver live-only en `lib/s1/conversationControl.js`: `public.conversation_control_v1` por igualdad
exacta de `session_id`, las 26 columnas explícitas, `LIMIT 2` como `fetchmany(2)`, y los tres códigos.
Sin fallback por teléfono, archive, `LIMIT 1` ni orden. La ausencia de la vista cae en
`dependency_unavailable`, así que el módulo es seguro antes del rollout.

**Aplicadas tus cuatro respuestas:**

- **Cableado (A + costura única):** `lib/s1/controlResolver.js`. Un solo punto de indirección, **no** un
  modo de runtime — no lee `process.env` y hay un test que lo afirma leyendo su propio fuente, para que
  convertirlo en configuración se ponga rojo. Los dos call-sites ya pasan por ella y hoy delega **byte a
  byte** en el legacy, con tests que comparan ambas salidas para acreditar cero cambio de comportamiento.
  Sustituir será cambiar una línea.
- **Call-sites listados** en la entrega §3 con fichero:línea y su respuesta actual. Y una corrección mía:
  `inbox.js` y `db-leads.js` **no** son call-sites —solo leen columnas de identidad y las anotan—, así que
  la sustitución afecta a dos sitios, no a cuatro. Lo que yo mismo te dije en la duda era incorrecto.
- **HTTP:** tabla aplicada solo a superficie nueva. Divergencia declarada en la entrega §4:
  `conversation_not_found` devuelve **400** en `retomarBuilder.js:14` y `conversation.js:14`, alineado
  serían 404. **No lo he tocado.**
- **`invalid_request`:** el selector ausente ya no fabrica `conversation_not_found`; se rechaza sin
  consultar, con 400, y hay un test que vigila que no contamine la lista cerrada de tres.

## E2 — hecho, y acreditado en PostgreSQL efímero de verdad

`migrations/2026-08-11-claims-epoch-anti-aba.sql`, **escrita y no aplicada**. Aditiva e idempotente,
porque la migración de fencing del 28 jul se aplicó a mano y nunca se versionó: esta salda esa deuda y
deja el mismo estado final se parta de donde se parta.

`CHECK(epoch>0)`, `UNIQUE(session_id,epoch)`, estados cerrados, `active` exige `quotation_id`, único
`active` por sesión, readiness físico (bigint / 255 / 80), y la columna de lease **sin `DEFAULT`** — no se
crean leases no nulas.

**La inmutabilidad va en trigger, no en la aplicación:** prohíbe DELETE, cambiar `session_id`/`control_id`/
`epoch`, retargetear identidad ya fijada y resucitar un terminal a `active`. Un camino de código puede
olvidar la regla; la base no.

`scripts/156/verificar-migracion-claims.sh` levanta un cluster propio (socket unix, sin TCP), aplica,
ejerce **31 gates** y lo destruye. Incluye el gate estrella del §6: **dos `take` concurrentes reales**
—dos procesos `psql`, mismo advisory lock— con **exactamente un ganador** y sin fila del perdedor.

## Lo que NO está, dicho sin maquillar

- **E3 (cable) y E5 (read models): no empezados.** Por tiempo, no por bloqueo: E3 es construible offline
  con stubs y E5 solo necesita los overlays del §9, ya congelados.
- **E4 parcial:** `canHumanSend` y `isAutomationEligible` hechas y probadas, cada estado con su
  `reason_code`. **La UI no se ha tocado** — sigue pintando `json.error`. La pieza que faltaba para poder
  arreglar esa deuda ya existe.
- **Gates del §6 sin cubrir:** `claim ↔ reserva` y `release A ↔ take B` dependen de E3. «Vista malformada»
  solo parcialmente: `schema_version` no soportado y `session_id` que no es el pedido, pero no una vista
  real corrupta, porque la vista no existe.
- **Brecha de roles declarada** (entrega §5): mono-rol, ownership no impuesto técnicamente, GRANTs
  escritos y comentados sin ejecutar.

## Nota de proceso

Porté los dos monitores desde el Agente n8n (`scripts/monitor-handoffs.sh`, `scripts/monitor-dudas.sh`);
este repo no tenía ninguno. Se acreditaron solos durante el trabajo: el de dudas cazó tu respuesta y la
etiquetó como mía, y el de handoffs avisó de tu corrección `c46c9cf` retirando E0.

Alberto decide qué se comenta en #156; yo no publico en el tracker.
