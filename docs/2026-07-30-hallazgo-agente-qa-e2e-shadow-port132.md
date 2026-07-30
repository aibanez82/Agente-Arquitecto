# Hallazgo — E2E shadow del port #132: `Resolve Session` rompe todo clic de quick-reply

**De:** Agente QA & Testing · **Para:** Arquitecto-IA-Qualitas · **Fecha:** 30 jul 2026
**Responde a:** `Agente_QATest_Qualitas:handoffs/2026-07-30-e2e-GO-condiciones-juan.md`
(GO acotado del checkpoint de Juan) sobre `handoffs/2026-07-30-e2e-shadow-port132-fencings.md`
**Informe completo:** `/Users/AIP/claude-projects/Agente_QATest_Qualitas/docs/2026-07-30-e2e-shadow-port132-resultados.md`
**Issue abierto:** [qualitas-issues#69](https://github.com/aibanez82/qualitas-issues/issues/69) · `sistema:n8n` · `criticidad:critico`

---

## Titular

**Corrida DETENIDA en E2 por FAIL bloqueante** (condición 5 del GO). El gate `qc:` del contrato 2
funciona — E1 pasó 5/5. Pero el nodo inmediatamente posterior, `Resolve Session`, **rompe toda
ejecución con payload de quick-reply** (`qc:v1` y `qc:v2`) con `there is no parameter $3`.

Eso deja **inalcanzables por la ruta de payload** todos los fencings que el port existe para
blindar: contratos T1-T4 (writers), 5 (Metepec) y 6 (takeover) viven aguas abajo de ese nodo.

**Cero mensajes Meta, cero correos, cero destinatarios externos.** Ninguna de las 7 ejecuciones
alcanzó un nodo de envío.

---

## El fallo

Workflow `WhatsApp Insurance Quotation Bot_stg` (`dNqtM20ij6ecZYAX`), nodo **`Resolve Session`**.
Es el **binding**, no la query:

```
options.queryReplacement =
  {{ $json.lookupMode }},
  {{ lookupMode === 'payload_v2' ? conversationId : (lookupMode === 'payload_v1' ? quotationId : phoneNumber) }},
  {{ lookupMode === 'phone_open_sessions' ? $json.phoneNumberVariants : [] }}
```

El tercer valor es `phoneNumberVariants` **solo** en modo teléfono. En `payload_v1`/`payload_v2` es
un **array vacío `[]`**, que n8n resuelve a cadena vacía y descarta al construir la lista de
parámetros → se mandan **2** parámetros a una query que declara `$1`, `$2` y `$3`.

### La query está bien — verificado

Reproducida contra la Postgres real de STG (solo lectura, `$n` → parámetros nombrados de `psycopg2`):

| Parámetros | Resultado |
|---|---|
| `('payload_v1', '990002', [])` | ✅ `match_count=1`, fila correcta |
| `('payload_v1', '990002', NULL)` | ✅ `match_count=1`, fila correcta |
| `('phone_open_sessions', 'E2E-5550003', ['E2E-5550003'])` | ✅ `match_count=1`, fila correcta |

Pasar `[]` o `NULL` como `$3` funciona perfectamente. El problema es exclusivamente que el
parámetro **no llega**.

### Reproducción en vivo

| Ejecución | Payload | Estado | Último nodo |
|---|---|---|---|
| **873** | `qc:v1:c:990002` — v1 legacy, **totalmente válido** | `error` | `Resolve Session` |
| **871** | `qc:v1:l::c:990001:m:abc123abc123` | `error` | `Resolve Session` |

Traza idéntica en ambas:
`WhatsApp Message Trigger → WA Config STG → Session Context Builder → Prepare Resolution Context → QC Terminal? → Resolve Session ✗`

Los mensajes de **texto libre** no están afectados (ahí `phoneNumberVariants` no está vacío y se
mandan los 3 parámetros).

## Impacto

🔴 **Crítico.** El clic del botón de la plantilla `cotizacion_inicial_con_imagen_boton` es la vía
de entrada principal del embudo — Django emite `qc:v1:l:<lead>:c:<cotizacion>:m:<token>`. En STG,
**el 100 % de esos clics muere con error duro** y el cliente no recibe nada.

**Verificar si aplica igual a PROD** antes de promover el port. No lo comprobé: PROD está fuera de
alcance por la condición 4.

## Fix propuesto

Que `$3` se envíe siempre con un valor que n8n no descarte. La query ya tolera `[]` y `NULL`, así
que basta con no dejar que el binding lo colapse:

```
{{ $json.lookupMode === 'phone_open_sessions' ? $json.phoneNumberVariants : [''] }}
```

El `AND $1 = 'phone_open_sessions'` sigue siendo quien decide, así que la semántica no cambia.
La alternativa (reordenar la query para que `$3` no exista en modo payload) duplica SQL. Decisión
tuya / de Agente n8n; lo que hay que garantizar es que `Resolve Session` reciba **3** parámetros
en los 3 modos.

**Verificación tras el fix:** repetir con `qc:v1:c:<cotizacion>` y con
`qc:v2:cv:<conversation_id>:l:<lead>:c:<cotizacion>:m:<token>` y confirmar que la traza llega a
`Session Resolution` en vez de morir en `Resolve Session`.

---

## Lo que sí quedó validado — E1, contrato 2 · PASS

5/5 payloads inválidos terminan en `Terminal Sink` con **cero respuesta del agente, cero escritura
en `n8n_chat_histories`, cero UPDATE de sesión** (verificado por traza n8n **y** por snapshot SQL
de las 24 columnas de toda la tabla antes/después):

| # | Payload | Ejec. |
|---|---|---|
| E1.1 | `qc:garbage` | 867 |
| E1.2 | `qc:v3:cv:...:l:1:c:990001:m:...` (versión futura) | 868 |
| E1.3 | `qc:v2:...:m:abc123abc123:x:evil` (clave desconocida) | 869 |
| E1.4 | `qc:v1:l:1:c:990001:m:...:l:2` (`l:` duplicada) | 870 |
| E1.6 | `qc:v2:cv:...:c:990001:m:...` (`l:` ausente en v2) | 872 |

Los disparos salieron desde un teléfono que **sí** correspondía a una sesión abierta y resoluble:
si el gate hubiera fallado, el flujo habría degradado a búsqueda por teléfono y escrito sobre esa
fila. No ocurrió en ninguno.

`E1.5` (`l:` vacía en v1) **no se pudo evaluar contra su contrato**: la gramática lo acepta y el
claim de lead inválido debería declararse terminal en `Session Resolution`, pero la ejecución muere
antes. Pendiente de reverificar tras el fix.

---

## Escenarios no ejecutados y por qué

| Escenario | Motivo |
|---|---|
| **E2** (writers con gate) | E2.a = el FAIL. E2.b y E2.c no ejecutados por la parada de la condición 5 |
| **E3** (Metepec reserva) | E3.a/b solo son alcanzables vía el AI Agent invocando `registrar_lead_metepec`, y ese camino termina en `Send message` (Meta) y en el nodo Gmail `Send Metepec Email` (destinatario externo). Además `METEPEC - Registrar Lead (STG)` usa `executeWorkflowTrigger`: **no es invocable desde la API pública de n8n**, solo desde otro workflow o desde la UI. E3.c sí era ejecutable sin efecto externo, ver bloqueos abajo |
| **E4** (payment ledger) | Fuera de alcance por el propio GO, en dos puntos: condición 4 («Payment writes/outbox/reconciliation») y «fuera de alcance expreso» (WARN de #129) |
| **E5** (takeover/dispatch) | El camino feliz termina en `Send Human Agent Message` → `graph.facebook.com`. Los negativos (claim revocado, epoch viejo) **sí** eran ejecutables sin efecto externo, ver bloqueos |
| **E6** (humo general) | Termina siempre en `Send message` (Meta). Y su mitad de entrada, el clic del botón, está rota por el FAIL |

---

## Bloqueos para reanudar — necesito de ti

1. **Fix de #69** (Agente n8n). Sin él, E2.a, E3, E6 y la reverificación de E1.5 son inalcanzables
   por la ruta de payload.
2. **Valor de la cabecera de `Atencion Humana Header Auth STG`** (credencial `TyxFAIYtKfgHt9cv`).
   Los 3 webhooks de `Atencion Humana (STG)` y el de `Metepec Liberar (STG)` usan `headerAuth`;
   sin la cabecera devuelven `403 Authorization data is wrong!`. Con ella, **E3.c y los negativos de
   E5 se ejecutan sin ningún envío ni efecto externo** — son cierre inmediato en cuanto la tenga.
3. **Sink autorizado** para los 4 sub-escenarios que terminan en envío (E2.c, E3.a/b, E5 positivo,
   E6): número de prueba STG como destinatario de WhatsApp, y confirmación de si el Gmail de
   `Send Metepec Email` apunta a un buzón de prueba. La condición 2 prohíbe destinatarios externos
   y no hay ningún sink documentado en el handoff.

Con (1) y (2) se cierran E1.5, E2.a/b, E3.c y los negativos de E5 **sin necesidad de un solo
envío**. (3) solo hace falta para el camino feliz.

---

## Desviaciones de esquema respecto al handoff base

No son fallos, pero el handoff describe el esquema de otra forma y hay que corregirlo para la
próxima corrida:

1. **`n8n_payment_events` no tiene tabla `_archive`** (el handoff decía «+archive»). Las que sí
   existen son `n8n_chat_histories_archive` y `whatsapp_sessions_archive`.
2. **`dashboard_conversation_claims` usa la columna `state`, no `status`** — el handoff pedía
   `status='revoked'` para E5. Valores permitidos por `ck_claims_state`: `active`, `released`,
   `revoked`, `expired`.
3. **`n8n_payment_events.event_id` es `uuid`, no texto** — el «mismo `event_id` repetido» de E4 hay
   que construirlo como uuid.

### Observación para el diseño del E4 futuro

`WhatsApp Insurance Quotation Bot - Payment Confirmation_stg` **no tiene ningún nodo que escriba en
`n8n_payment_events`** (sus 6 nodos: trigger, `Format & Validate Message`, `Send message`,
`Mark Session Completed`, `Restore After Phase Update W2`, `WA Config STG`). El ledger de
idempotencia / `contradiction` tiene que estar del lado de Django. Conviene confirmarlo antes de
diseñar ese E2E.

### Nota de método

**No se usó pin data.** Pinar datos modifica la definición del workflow, y la condición 4 prohíbe
«import/edición/activación de workflows» — es más estricta que el handoff base, así que manda.
En su lugar: cuerpo del webhook de Meta construido **en local** y entregado directo al endpoint de
producción del `WhatsApp Message Trigger` en n8n STG. Es la vía de entrada real del bot, pero el
mensaje no pasa por Meta en ningún momento.

Dato útil: la URL correcta de ese trigger lleva sufijo — `{base}/webhook/{webhookId}/webhook`.
Sin el sufijo, n8n devuelve 404 «not registered», que es fácil confundir con un trigger caído. No
lo está.

---

## Cumplimiento del GO

| # | Condición | Estado |
|---|---|---|
| 1 | Solo `E2E-`, cero PII, cero teléfonos reales | ✅ 6 sesiones sintéticas, teléfonos **no numéricos** (`E2E-5550001`…) — ni un envío accidental habría podido entregarse a una persona |
| 2 | Ningún mensaje Meta real ni destinatario externo | ✅ Cero envíos. 4 sub-escenarios omitidos por esto |
| 3 | `shadow` y flags tal como están | ✅ Cero cambios de config, credenciales o workflows (`pinData` sigue vacío en los 7) |
| 4 | Nada de DDL, edición de workflows, Dashboard, `dual`, PROD, followups, Payment writes, funnel v2 | ✅ Cumplido — por eso no hubo pin data y por eso E4 quedó fuera |
| 5 | Parar en el primer FAIL, sin reintentos a ciegas | ✅ Parada en E2.a. Ni un reintento |
| 6 | Limpieza `E2E-` por IDs exactos con conteos | ✅ Cero residuo previo. 6 filas creadas y borradas por `session_id` exacto (`DELETE 6`), verificado 0 después. Las 7 sesiones reales, intactas |
| 7 | Entregable por escenario | ✅ Publicado y pusheado |
| — | Rollback real y E2E financiero fuera de alcance | ✅ No se intentaron |

> Existen en STG otras filas de prueba con prefijos **distintos** (`test-fresh-*`,
> `isolated-test-refacturado-*`, `TEST-MULTIPLATAFORMA-*`, `TEST-SANITY-*`, `TEST-MP2-*`: 34 filas
> en `n8n_chat_histories`). **No se tocaron** — la condición 6 solo autoriza el prefijo `E2E-`.
