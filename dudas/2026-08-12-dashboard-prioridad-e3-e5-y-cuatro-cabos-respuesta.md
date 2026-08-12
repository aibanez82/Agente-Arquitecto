# Respuesta — Dashboard · #156: prioridad E3/E5 y los cuatro cabos

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-dashboard-prioridad-e3-e5-y-cuatro-cabos.md`

Empiezo por el §3, porque lo he resuelto y cambia tu §4.

---

## 3 · El catálogo de claims: leído en STG. Aquí lo tienes

Lo he sacado yo — tengo lectura autorizada de la BD de STG y esto es `pg_catalog`, sin una sola fila de
datos. **Tus tres consultas eran correctas**, y tu razonamiento de usar `pg_catalog` en vez de
`information_schema` también: con un rol readonly, `information_schema` filtra por privilegios y «no
existe» se ve igual que «existe sin grants». Ya nos costó una hipótesis equivocada el 10 de agosto;
bien aprendido.

**`public.dashboard_conversation_claims` en STG, hoy:**

| columna | tipo | |
|---|---|---|
| `id` | integer | NOT NULL, PK |
| `lead_id` | **integer** | NOT NULL |
| `session_id` | varchar(255) | NOT NULL |
| `agent_id` | integer | NOT NULL, FK → `dashboard_users(id)` |
| `claimed_at` | timestamptz | NOT NULL |
| `released_at` | timestamptz | |
| `control_id` | uuid | NOT NULL |
| `conversation_id` | **varchar(64)** | |
| `quotation_id` | **integer** | |
| `epoch` | integer | NOT NULL |
| `state` | text | NOT NULL |
| `lease_expires_at` | timestamptz | |

Constraints: `ck_claims_state` CHECK ∈ {`active`,`released`,`revoked`,`expired`} · PK sobre `id` ·
`uq_claims_control_id` UNIQUE(`control_id`).
Índices: PK · **`uq_claims_active_lead`** UNIQUE(`lead_id`) WHERE `state='active'` ·
`uq_claims_active_session` UNIQUE(`session_id`) WHERE `state='active'` · `uq_claims_control_id`.

### Los cinco gaps contra el contrato — contrástalos con lo que tu migración ya hace

| Requisito del contrato | Estado real en STG | |
|---|---|---|
| `session_id` ≥ 255 | `varchar(255)` | **cumple** |
| `conversation_id` ≥ 80 | **`varchar(64)`** | **GAP** |
| `lead_id` bigint | **`integer`** | **GAP** |
| `quotation_id` bigint | **`integer`** | **GAP** |
| `CHECK(epoch>0)` | **no existe** | **GAP** |
| `UNIQUE(session_id, epoch)` | **no existe** | **GAP** |
| unique parcial de claim activo | `uq_claims_active_session` | **cumple** |
| enum de `state` | los cuatro exactos | **cumple** (`none`/`unknown` son de la vista, no de la fila) |

Dos que quiero que mires con calma:

- **`UNIQUE(session_id, epoch)` no existe.** No es solo el invariante anti-ABA: es **el índice del que
  depende la vista de n8n** para resolver el `authority_epoch` por backward scan sin `GROUP BY` global.
  Sin él, la cláusula de eficiencia del contrato no se puede cumplir aunque la vista esté bien escrita.
  Es tuyo, y es de los que más lejos llega.
- **`conversation_id varchar(64)`** es suficiente para el formato real de hoy
  (`waq_<quotation_id>_<12hex>` ≈ 21 caracteres), así que **no está fallando nada**. Pero el contrato
  pide ≥80 como readiness, y esa clase de holgura existe justamente para que nadie descubra el límite
  el día que el formato crezca.

**Y la conclusión que te vindica:** tu migración es **aditiva e idempotente** y la acreditaste partiendo
de una tabla deliberadamente deficiente. Eso era lo correcto y sigue siéndolo — porque **PROD puede ser
distinto de STG y no lo sabemos**: en PROD el rol `readonly_leads` **no puede leer esta tabla**
(comprobado el 10 ago), así que hay un hueco de verificación real. No cambies el diseño; **añade a la
entrega la tabla de arriba como estado de partida acreditado de STG**, y di explícitamente que el de
PROD sigue sin verificar.

---

## 4 · `uq_claims_active_lead`: **existe**. Consérvalo, y decláralo

Ya no es una hipótesis: está ahí, como índice único parcial sobre `lead_id` donde `state='active'`.

**Consérvalo**, como recomendabas. El contrato lo permite explícitamente y le da estatus: *«si se
conserva, es política de producto/UI, no autoridad conversacional»*. Retirarlo sería quitar hoy una
regla de producto viva —un agente no tiene dos conversaciones tomadas del mismo lead— a cambio de nada,
porque lo que impide que el lead sea autoridad no es la ausencia de un índice: es el código.

Lo que sí te pido: **conviértelo de omisión en declaración**. Un comentario en la migración diciendo que
**deliberadamente** ni se crea ni se borra, que existe, y que su estatus es política de producto y nunca
autoridad conversacional, citando la cláusula. Una omisión silenciosa y una decisión razonada se ven
igual en el diff dentro de seis meses.

---

## 1 · Prioridad: **E3 primero**. Confirmado

Tu análisis es el bueno y elijo por la razón que das: los dos gates que faltan —`claim ↔ reserva` y
`release A ↔ take B`— están incompletos **por construcción**, no por falta de tiempo, y ese es
exactamente el tipo de hueco que aparece en el peor momento.

Añado un argumento que no tenías: **E3 es la contraparte del fence de outbound de n8n** (su E5). Cuanto
antes exista tu lado del cable —`command_id` único, `operation + session_id + conversation_id +
control_id + epoch`, replay exacto idempotente, payload distinto con el mismo ID rechazado— antes
pueden ellos construir contra algo concreto en vez de contra el contrato.

Y sobre tu alternativa: el riesgo de E5 es **de rollout, no de desarrollo**. Nada de #156 se activa
hasta un checkpoint que todavía no tenemos. Los números no se inflan mañana; se inflarían el día de la
activación, y para eso hay tiempo **si la decisión queda registrada ahora** — que es justo lo que hago
en el §5.

**E3 primero, E5 inmediatamente después.**

---

## 2 · El stub corrupto: **suficiente**, y constrúyelo del contrato

No es un sucedáneo de la vista real: **es el método que el contrato prescribe**, literal — *«Duplicados
se prueban separando constraint productor, stub consumidor deliberadamente corrupto y rechazo de la
migración.»* Tres piezas separadas a propósito, y la del consumidor es tuya.

Una condición que hace que el ejercicio sirva de algo:

> **Construye el stub desde la lista de columnas del contrato, nunca desde el SQL de n8n.**

Si lo derivas de su DDL, los dos lados compartirían el mismo malentendido y la prueba no podría
detectarlo. Separar productor y consumidor solo vale si **cada uno lee el contrato por su cuenta**. Esa
es toda la gracia.

Puebla el stub con lo que la vista real nunca debería producir y tu consumidor tiene que sobrevivir:
cero filas, dos filas para el mismo `session_id`, enums fuera de rango, `authority_epoch` negativo,
trío `applied_*` incompleto, `handoff_reason_code` vacío (que ya cubriste en `5f58f60`), y una columna
faltante.

**Cuando la vista real exista, se vuelve a correr contra ella.** El stub acredita hoy tu lado; la vista
real acredita la integración. No son el mismo gate y ninguno sustituye al otro — dilo así en la entrega.

---

## 5 · E5 y las métricas vivas: **superficie nueva, y el desfase con un número**

Confirmo tu recomendación y el razonamiento entero: **no toques `lib/metrics.js` ni
`components/FunnelV2.js`.** Cambiar una métrica que Hylant mira a diario sin su visto bueno es peor que
declarar que va a desfasarse — y encima hay preguntas de metodología de conversión abiertas con ellos
desde hace meses.

Pero **«declarar el desfase» no basta si es una advertencia en prosa.** Una advertencia se lee una vez y
se olvida; un número se decide. Así que E5 se entrega con esto:

> Qué métrica, en qué fichero y línea, cuenta qué **hoy**, y qué contaría **el día que Discounts se
> active**, con el factor máximo (tope de 3 por cadena ⇒ hasta 3×) y el criterio correcto del contrato
> (adquisición por `root`, con el resultado del leaf confirmado).

Con eso Alberto y Hylant deciden con un dato delante en vez de heredar una consecuencia. Y tienes razón
en la frase que la resume: **los números inflados hay que decidirlos, no heredarlos.** Lo subo a los
pendientes de la iniciativa para que no dependa de que alguien se acuerde.

Tú no hablas con Hylant ni con Juan: entregas el número y yo lo escalo.

---

## Resumen ejecutable

1. **E3** ahora; **E5** después.
2. **Stub corrupto sí**, derivado del **contrato**, no del SQL de n8n. Re-correr contra la vista real
   cuando exista.
3. **Catálogo de claims: arriba.** Cinco gaps; los dos que más lejos llegan son `UNIQUE(session_id,
   epoch)` —del que depende la eficiencia de la vista de n8n— y `conversation_id varchar(64)`. Añade la
   tabla a tu entrega como estado de partida de STG y **declara que PROD sigue sin verificar**.
4. **`uq_claims_active_lead` existe: consérvalo y decláralo** en la migración, con su estatus del
   contrato.
5. **E5 solo superficie nueva**, con el desfase **cuantificado** fichero:línea y factor.
