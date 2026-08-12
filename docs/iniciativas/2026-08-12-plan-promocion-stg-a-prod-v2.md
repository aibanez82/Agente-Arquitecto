# Plan de promoción STG → PRODUCCIÓN · **v2** — Dashboard y n8n primero

**Fecha:** 12 ago 2026. **Estado:** plan. Nada de aquí se ejecuta sin autorización explícita.
**Sustituye a** `2026-08-10-plan-promocion-stg-a-prod-cross.md`, que sigue siendo válido en su §0
(tesis), §3 (lo irreversible), §5 bis (issues) y §7 (reglas de ventana). Lo que cambia es el **orden**
y, sobre todo, **dos bloqueantes que aquel plan no tenía**.

**Orden pedido por Alberto (12 ago):**

> 1. A PRODUCCIÓN lo que **hoy** vive en STG, de **Dashboard** y **n8n**.
> 2. **Después**, merge de los desarrollos de descuentos (#156) a STG.

Ese orden es el correcto y además resuelve una tensión que arrastrábamos: si #156 entrara antes en
`stg`, la promoción a PROD llevaría dentro trabajo que Juan aún no ha revisado.

---

## 0. El hallazgo que cambia el plan

El plan del 10 ago daba por buena esta línea de su tabla de reconocimiento:

> *«¿El Dashboard promovido depende de tablas que PROD no tenga? **No.** `dashboard_conversation_claims`
> … existen en PROD.»*

**Comprobé que las tablas existían. No comprobé su forma.** Hoy, leyendo el catálogo de PROD:

```
dashboard_conversation_claims en PROD:
  id · lead_id · session_id · agent_id · claimed_at · released_at
índices: pkey · dashboard_claims_active_idx
```

Y el `claim.js` que vive en `stg` —el que arregla el `42P08` y que es **la razón de ser de la Fase 1**—
hace:

```sql
INSERT INTO dashboard_conversation_claims (lead_id, session_id, quotation_id, agent_id, epoch, state)
… RETURNING id, control_id, epoch, claimed_at
```

**`quotation_id`, `epoch`, `state` y `control_id` no existen en PROD.** Promover el Dashboard hoy no
arreglaría «Tomar conversación»: lo dejaría roto igual, con otro código de error (`42703`, columna
inexistente, en vez de `42P08`). El síntoma sería idéntico para el operador y el diagnóstico volvería a
empezar de cero.

**Lo mismo del lado de n8n.** En PROD, `whatsapp_sessions` **no tiene** `human_takeover`,
`human_takeover_control_id`, `human_takeover_epoch` ni `metepec_derived`. La iniciativa de **Atención
Humana** escribe en esas columnas: no puede promoverse tal cual.

### La regla que se saca de aquí

> **El delta STG→PROD no es solo de código: es de esquema. Y ese esquema se aplicó a mano en STG y
> nunca se versionó, así que no existe como artefacto que se pueda promover.**

Las dos piezas que faltan tienen origen conocido y ninguna dejó migración:

| Qué falta en PROD | Quién lo creó en STG | ¿Versionado? |
|---|---|---|
| `claims`: `control_id`, `quotation_id`, `epoch`, `state`, índices de fencing | migración de fencing del **28 jul**, aplicada **a mano** | **No** |
| `whatsapp_sessions`: `human_takeover`, `…_control_id`, `…_epoch`, `metepec_derived` | `deploy-atencion-humana-stg.py` y `deploy-renovacion-metepec-stg.py` | **No** (scripts de deploy, solo STG) |

Y ojo: **las migraciones de #156 no cubren este hueco.** La del Dashboard añade `conversation_id`,
`lease_expires_at` y constraints **sobre columnas que da por existentes**; la de n8n da `human_takeover`
por presente. Las dos se escribieron contra STG, donde ya estaban. Contra PROD abortarían.

---

## 1. Reconocimiento de PROD — hecho hoy, en vivo, solo lectura

| | |
|---|---|
| `whatsapp_sessions` | **1084** filas · `session_id = phone_number` en **1084 (100 %)** · **620** con `conversation_id` (shadow) |
| `whatsapp_sessions` tiene | `status` varchar(30) · `closed_at` tz · `conversation_id` varchar(80) · `lead_id` int · `quotation_id` int · `is_banned` bool · `conversation_phase` varchar(50) |
| `whatsapp_sessions` **NO** tiene | `human_takeover` · `human_takeover_control_id` · `human_takeover_epoch` · `metepec_derived` |
| `dashboard_conversation_claims` | existe, **16 filas**, forma antigua de 6 columnas (arriba) |
| Existen | `whatsapp_sessions_archive` (113) · `n8n_chat_histories` (5435) · `n8n_chat_histories_archive` (1105) · `dashboard_message_audit` (18) · `conciliacion_pagos` (297) · `leads_metepec` (10) · `qualitas_whatsappmessage` (1912) · `comisiones_facturas` (0) · `comisiones_recibos` (0) · `dashboard_users` (4) |
| **No** existen | `n8n_payment_events` · `dashboard_outbound_dispatch` |

**Lo que esto despeja:** todas las tablas que consulta el código del Dashboard de `stg` existen en PROD
—incluidas `leads_metepec` y `qualitas_whatsappmessage`, que eran las dudosas— y `dashboard_outbound_dispatch`
**no la usa** el código de aplicación, así que su ausencia no bloquea. **El único bloqueo del Dashboard
es la forma de la tabla de claims.**

**Lo que confirma:** `n8n_payment_events` sigue sin existir, así que Payment Confirmation (S1) sigue
aplazada, como ya decía el plan del 10.

---

## 2. Delta a promover

| Sistema | Delta | Notas |
|---|---|---|
| **Dashboard** | **15 commits, 19 ficheros de aplicación** (`stg` → `main`) | Incluye los tres arreglos del 10 ago: `42P08` en `/api/claim`, `isEligible` con `active`, y el pin de la UI al liberar |
| **n8n** | 5 iniciativas independientes (medición del Agente n8n, `docs/2026-08-10-plan-promocion-stg-a-prod.md`) | **Su Fase 0 —clasificar los 39 nodos con parámetros distintos— no se salta.** Es la parte que son días, no horas |
| **Django** | 89 commits, 9 migraciones | **Fuera de este plan por decisión de Alberto.** Ver §5 |

---

## 3. Fases

Cada fase: **un sistema, una autorización, una ventana, un E2E.** Y la regla que se rompió en S1:
**lo que no esté verde en STG no se promueve; no se arregla en el camino.**

### Fase 0 — Escribir el esquema que falta (**nueva, y es la que desbloquea todo**)

No se promueve nada hasta que existan **dos migraciones versionadas, idempotentes y aditivas**, cada
una en el repo de su dueño, **escritas y probadas en PostgreSQL efímero, sin aplicar**:

- **Dashboard** — lleva `dashboard_conversation_claims` de la forma de PROD a la de STG:
  `control_id uuid`, `quotation_id`, `epoch`, `state` y sus índices de fencing. Es reconstruir lo que el
  28 de julio se hizo a mano. **Debe partir de la forma de PROD**, no de la de STG.
- **n8n** — añade a `whatsapp_sessions` (y paridad en `archive`) `human_takeover`,
  `human_takeover_control_id`, `human_takeover_epoch` y `metepec_derived`. Es reconstruir lo que
  hicieron los dos scripts de deploy.

**No se mezclan con las de #156**, que son de otro alcance y otra autorización. Y las de #156 se
benefician: aplicada la Fase 0, su premisa («esas columnas ya están») pasa a ser cierta también en PROD.

- **Criterio de éxito:** cada migración corre dos veces seguidas contra una copia de la **forma de
  PROD** y la segunda pasada no cambia nada; y tras aplicarla, el esquema de PROD es igual al de STG en
  esas tablas, comprobado por catálogo y no por inferencia.
- **Duración:** horas, no días. Las dos son pequeñas.

### Fase 1 — Aplicar la Fase 0 en PROD

Ventana propia, **antes** de tocar código. DDL aditivo puro: no cambia comportamiento porque nadie lee
todavía esas columnas en PROD.

- **Precondiciones:** `heroku pg:backups:capture` reciente · las dos migraciones revisadas · rollback
  escrito (los `DROP COLUMN` correspondientes, aunque no se espera usarlos).
- **Criterio de éxito:** catálogo de PROD == catálogo de STG en las dos tablas. El bot sigue
  respondiendo y el Dashboard sigue leyendo, los dos verificados **después** del DDL.
- **Rollback:** las columnas son aditivas y nadie las lee; en el peor caso se quedan y no molestan.

### Fase 2 — Dashboard (`stg` → `main`)

Es la Fase 1 del plan del 10, **con su bloqueante ya retirado**. Sigue siendo la primera de código: el
delta más pequeño, no toca DDL compartido, rollback instantáneo por Vercel, y **arregla un fallo que hoy
está roto en producción**.

- **Precondiciones:** ① Fase 1 aplicada y verificada; ② build verde en Preview sobre la punta de `stg`;
  ③ suite offline verde sobre el commit exacto que se promueve; ④ **acreditar por comportamiento** qué
  camino toma el proactivo en PROD con `S1_DASHBOARD_MODE` **ausente** — la expectativa es el camino
  legacy, coherente con el 100 % de PROD, pero es expectativa y hay que observarla; ⑤ `SELECT` sobre
  `dashboard_conversation_claims` para el rol de verificación, o el `409` no se puede comprobar.
- **Criterio de éxito, observable:** `POST /api/claim` → **201** y fila real con `control_id`, `epoch=1`
  y `state='active'`; **segundo clic → 409** (esta prueba **no se ha ejecutado nunca**, ni antes ni
  después del arreglo); `/api/inbox` y `/api/db-leads` → 200 con los mismos conteos que antes; un
  mensaje proactivo real entregado a un teléfono de pruebas.
- **Rollback:** promover el deployment anterior en Vercel. Segundos.
- **Duración:** 30 min. No necesita franja de bajo tráfico.

### Fase 3 — n8n, una iniciativa por ventana

Mecánica del Agente n8n: retrato del antes por API · cambio **por API con script dedicado, nunca por
import de fichero ni por UI** · verificación de `webhookId` sin cambiar, `Phone Number ID Guard`
presente, cero `WA Config STG`, `detect-drift.py` en 0 · E2E real · y el `PUT` de reversión **escrito
antes de empezar**.

| # | Iniciativa | Estado |
|---|---|---|
| 3.1 | **Retomar Conversacion** | Delta mínimo (2 nodos + credencial). Ensayo del procedimiento |
| 3.2 | **Atención Humana** | **Desbloqueada por la Fase 1.** Cierra `qualitas-issues#57`: hoy el bot **puede responder encima de un humano en PROD** |
| 3.3 | **Multicotización** | Cinco entregas acreditadas en vivo en STG, ninguna en PROD. Aquí solo hay promoción |
| 3.4 | **Payment Confirmation (S1)** | **Aplazada:** `n8n_payment_events` no existe en PROD |
| 3.5 | **S1 en el bot principal** | **Aplazada:** va con `shadow`→`dual`, que no entra en este viaje |
| 3.6 | **METEPEC** | **Aplazada:** inactiva en STG y necesita contraparte en Django PROD |

Es decir: **tres iniciativas viajan, tres no.** Y la Fase 0 de clasificación de los 39 nodos precede a
todas — es la única parte que son días.

### Fase 4 — Higiene, en el momento y no al final

Retirar **uno de los dos índices redundantes** sobre `whatsapp_sessions.quotation_id` (hallazgo del
Agente n8n). Cerrar en el tracker lo que estas fases resuelvan de verdad, verificándolo en vivo antes.

---

## 4. Después: el merge de #156 a STG

Solo cuando las fases anteriores estén cerradas y verificadas.

1. **Juan responde** a la devolución del 12 ago: las 10 excepciones nominales, la divergencia de wire y
   la revisión integrada.
2. **El checkpoint de #156 autoriza el merge a `stg`** — hoy está expresamente en su lista de acciones
   no autorizadas, así que **no es nuestro**. Se pide en el mismo movimiento.
3. Merge de las dos ramas a `stg`, con el módulo **apagado**.
4. Camino que el propio contrato fija: `deploy módulo OFF → preflight/read-only smoke → fixture Fase 1
   allowlisted → activación separada`.

---

## 5. Lo que NO viaja en este plan

- **Django.** Sus 89 commits y 9 migraciones quedan fuera por decisión de Alberto (12 ago). **Hay que
  decirlo en voz alta:** eso deja sin entregar la **Fase 3 del plan del 10**, que es donde está el valor
  de negocio del viaje — hoy **51 pólizas de 57 están en `PENDIENTE`** mientras Laura sabe en un Excel
  cuáles se pagaron. No es una objeción al orden pedido: es que ese valor sigue esperando y conviene que
  la espera sea una decisión y no un olvido.
- **`shadow` → `dual`.** Aplazada a propósito, como en el plan del 10.
- **Payment S1, S1 en el bot principal y METEPEC**, por las razones de la tabla de la Fase 3.

---

## 6. Lo que hay que decidir antes de arrancar

1. **¿Quién escribe las dos migraciones de la Fase 0?** Lo natural: cada ejecutor la suya, con handoff
   corto y separado de #156.
2. **¿Cuándo?** Los dos ejecutores están hoy en #156 y a la espera de Juan. La ventana de espera es
   buen momento — no compiten.
3. **¿Se aprovecha para versionar el resto del esquema aplicado a mano?** Hay más DDL de STG sin
   artefacto. Mi recomendación: **no ahora**; cerrar solo lo que estas fases necesitan y anotar el resto.
4. **Django:** confirmar que queda fuera sabiendo que la Fase 3 del pago se aplaza con él.

---

## 7. Reglas de ventana

Se heredan tal cual del §7 del plan del 10 ago. Las tres que más se rompen:

- **Quien despliega no acredita.** Dos criterios, no uno.
- **Nada se arregla dentro de una ventana abierta.** Si algo no está verde, la ventana se cierra y se
  reabre otro día.
- **El rollback se escribe antes de empezar**, no se improvisa.
