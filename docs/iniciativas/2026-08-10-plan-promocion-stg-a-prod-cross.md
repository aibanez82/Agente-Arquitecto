# Plan de promoción STG → PRODUCCIÓN — vista cross de los cuatro sistemas

**Autor:** Arquitecto-IA-Qualitas, como arquitecto del proyecto (no de un lado).
**Fecha:** 10 ago 2026. **Estado:** plan. Nada de aquí se ejecuta sin autorización explícita.
**Medido contra:** `origin/main` y `origin/stg` de los tres repos y la **BD de PROD en vivo** (rol
`readonly_leads`), el mismo día. Las cifras de este documento son observadas, no supuestas.

---

## 0. La tesis: por qué esto no puede costar lo que costó STG

S1 tardó 12 días y el manual de aprendizajes ya dictaminó por qué: *«la mayor parte del retraso no fue
implementar, fue descubrir hechos del entorno en mitad de la ejecución»*. Ir a PROD es un problema de
**otra forma**, y hay cuatro razones estructurales por las que puede ser mucho más barato. No son
optimismo: cada una descansa en un hecho verificado hoy.

**1. El reconocimiento ya está hecho, y está en el §1 de este documento.** Es la tabla que el manual
exige responder *antes* de escribir el plan. En S1 se respondió durante la ejecución, con GO emitidos y
pasos irreversibles delante. Aquí está respondida en frío, sin permiso de nadie y sin tocar nada.

**2. En PROD ya no se está construyendo una interfaz: se está moviendo una que existe y funciona.** El
aparato Contract-First —contrato congelado, fingerprints byte a byte, stand-down por etapa, ocho
handoffs— existía porque tres equipos construían a la vez contra algo que no estaba construido. Ese
problema **ya se resolvió**. Lo que queda para PROD no es un contrato: es **un invariante de
compatibilidad** (una frase) y **un rollback por sistema** (tres comandos). Sustituir lo primero por lo
segundo es el 80 % del ahorro.

**3. Desplegar y activar son dos cosas distintas, y en Django casi todo el delta viaja inerte.** Las
seis funcionalidades nuevas de pago y funnel v2 están detrás de variables de entorno con **default
`False`** (`PAYMENT_CONFIRMATION_WRITES_ENABLED`, `PAYMENT_RECONCILIATION_APPLY_ENABLED`,
`PAYMENT_OUTBOX_DELIVERY_ENABLED`, `PAYMENT_INTERNAL_FULFILMENT_READY`, `LEAD_FUNNEL_V2_WRITE_ENABLED`)
y el modo de identidad sigue gobernado por `WHATSAPP_CONVERSATION_ID_MODE`, que en PROD vale `shadow`.
Un despliegue así **no cambia comportamiento**; lo cambia después un `heroku config:set` que se revierte
en 30 segundos. Un evento grande e irreversible se convierte en dos pequeños y reversibles.
**Con una excepción real, que está en el §3 y es el riesgo de negocio de todo el viaje.**

**4. Se promueve por sistema y por iniciativa, nunca en bloque.** El Agente n8n ya llegó a esta
conclusión midiendo su lado (20 nodos nuevos = cinco iniciativas independientes con dueños y estados
distintos). Vale igual arriba: **una autorización = un sistema = una ventana = un E2E**. Si algo se
tuerce, se sabe qué fue. Un bloque pide una firma para cinco decisiones y hace el fallo inatribuible.

Y la regla que mantiene todo esto simple, que es la que se rompió en S1:

> **Lo que no esté verde en STG no se promueve. No se arregla en el camino.**
> Cada vez que en S1 se metió una corrección dentro de una ventana abierta, la ventana se alargó un día.

---

## 1. Reconocimiento de PROD — la tabla del manual §1, respondida en vivo hoy

| Pregunta | Respuesta observada en PROD |
|---|---|
| ¿Cómo se despliega Django? | Heroku `hyl-wai-production`, stack **container**. Despliegues `Deploy <sha>` por `alfred@aguayo.co`. **PROD corre `43bfaf2` = `origin/main` HEAD, desplegado el 27 jul.** Última release v339, pero v332–v339 son solo `config:set` |
| ¿Cuánto código separa PROD de STG? | **89 commits**, 79 ficheros, +18 950 líneas, **9 migraciones** (0053→0061). Ventana 27 jul → 6 ago |
| ¿PROD tiene ya el bootstrap de tablas externas? | **Parcialmente.** `whatsapp_sessions_archive` (113 filas) y `n8n_chat_histories_archive` (1105) **existen**. **`n8n_payment_events` NO existe** |
| ¿Se cumplen las precondiciones de la migración 0053? | **Las tres verdes.** `session_id` nulo/vacío = 0 · `session_id` duplicado = 0 · `conversation_id` duplicado = 0. La migración **no abortaría** hoy |
| ¿Qué identidad tiene PROD hoy? | **`session_id = phone_number` en las 1083 filas (100 %).** PK sobre `session_id`. 619 filas ya tienen `conversation_id` y `lead_id` poblados por `shadow` |
| ¿Qué se destruye en 0053? | El índice `idx_whatsapp_sessions_phone_number` (UNIQUE). **Es redundante hoy:** con `session_id = phone_number` y PK en `session_id`, la unicidad de teléfono la sigue imponiendo la PK. El drop es inerte hasta que existan filas con `session_id ≠ phone_number` |
| ¿Qué tamaño tienen las tablas del DDL? | `whatsapp_sessions` **1083** filas · `n8n_chat_histories` **5427**. El `CREATE INDEX` no concurrente y el `SET NOT NULL` son **instantáneos**; la ventana de lock es irrelevante |
| ¿`n8n_chat_histories` tiene las columnas que pide 0056? | Tiene `created_at`, **le falta `updated_at`**. 0056 la añade `NULL` → aditivo, seguro para el nodo de n8n que inserta por columnas |
| ¿Cuál es la ventana de menos tráfico? | 7 días: **36 mensajes**, solo en horas UTC 0, 1, 16 y 22 (= 18:00–19:00 y 10:00–16:00 MX). **Sin tráfico observado entre 02:00 y 15:00 UTC** → ventana recomendada **13:00–15:00 UTC (07:00–09:00 MX)** |
| ¿Dónde está PROD del Dashboard? | Rama **`main`** (`MAPA-DE-RAMAS.md` es autoritativo). `stg` es lo desplegado en STG y **va por delante en código** |
| ¿El delta del Dashboard es grande? | **No: 40 ficheros, 12 de aplicación**, todos bajo `apps/operacion/`. El monorepo **ya está en `main`**: no viaja en este delta |
| ¿El Dashboard promovido depende de tablas que PROD no tenga? | **No.** `dashboard_conversation_claims`, `comisiones_facturas`, `comisiones_recibos`, `dashboard_message_audit` existen en PROD. `lead_id`/`status`/`closed_at`/`conversation_id` de `whatsapp_sessions` existen |
| ¿Qué versión de n8n corre cada instancia? | **Las dos en 2.28.7** desde hoy. Ya no hay diferencia de motor que confunda una comparación, y está probado que los workflows **no se re-normalizan** al arrancar (solo al guardar) |
| ¿Cuánto vale el pago para el negocio hoy? | 57 pólizas emitidas: **51 `PENDIENTE`, 6 `PAGADO`**. Django no sabe qué se pagó de verdad (lo sabe Laura en Excel). Ese hueco es lo que cierra la Fase 3 |
| ¿Hay daño vivo por leads duplicados? | **12 pares** de leads con el mismo teléfono en el mismo minuto en 30 días (`qualitas-issues#20`) |
| Permisos de lectura para verificar | `readonly_leads` **no puede leer** `django_migrations` ni `dashboard_conversation_claims`. Dos huecos de verificación a cubrir con otro rol o desde Heroku |

**Lo que esta tabla compra:** las tres cosas que en S1 costaron una vuelta cada una —precondiciones de
datos, tamaño real del bloqueo y qué es efectivamente destructivo— aquí ya están contestadas, y las tres
salen a favor. El DDL de PROD no es el problema de este viaje.

---

## 2. Inventario: qué hay en STG que no está en PROD

### 2.1 Django · `aguayo-co/HYL-WAI` — 89 commits, 9 migraciones

| Bloque | Qué es | ¿Viaja inerte? |
|---|---|---|
| **A. Hardening dual de sesión** (0053, 0056) | DDL sobre `whatsapp_sessions` y las tablas de archivo. Convergente e idempotente: no repite lo que ya exista | Sí — el comportamiento lo gobierna `WHATSAPP_CONVERSATION_ID_MODE`, que sigue en `shadow` |
| **B. Fencing del envío inicial** (0054, 0055) | Claim durable + idempotencia por cotización en el **primer WhatsApp**, y `delivery_unknown` visible en el admin | **NO. Sin flag.** Ver §3 |
| **C. Verdad del pago** (0057→0061) | `PaymentEvidence` append-only + business outbox + trigger de identidad + `reconciliar_pagos` con dry-run. Tablas **nuevas**, no toca las existentes | Sí — cinco flags `PAYMENT_*` en `False` |
| **D. Preflights** | `preflight_issue_132`, `preflight_conversation_rollout`, `checks.py`: solo lectura, no se ejecutan solos | Sí |
| **E. Admin Wagtail** | Entrega desconocida, domicilio en cotización, listado de leads | Sí (superficie interna) |

### 2.2 n8n — medido por el Agente n8n contra las dos instancias vivas

| Workflow | PROD | STG | Nodos nuevos | Nodos con parámetros distintos |
|---|---|---|---|---|
| WhatsApp Insurance Quotation Bot | 113 | **132** | +20 | **39** |
| Payment Confirmation | 5 | **9** | +4 | 4 |
| Retomar Conversacion | 12 | 12 | +1 (`WA Config STG`) | 2 |

Los 20 nodos nuevos son **cinco iniciativas independientes**: multicotización (3), S1 observabilidad
dual (9), atención humana (2), METEPEC (5), infraestructura STG (1). Más **cuatro workflows que en PROD
no existen**: `Atencion Humana` (19 nodos, **activo** en STG), `Issue Policy Guard` (7, inactivo),
`METEPEC - Registrar Lead` (19, inactivo), `Metepec Liberar` (4, inactivo).
Fuente: `Agente-n8n:docs/2026-08-10-plan-promocion-stg-a-prod.md`.

### 2.3 Dashboard · `aibanez82/Dashboard_seguroautoqualitas` — 12 ficheros de aplicación

Read model S1 v1.1 (`lib/s1/*`), **fix del `42P08` en `/api/claim`**, `isEligible` aceptando
`('open','active')`, pin de `InboxTab` al liberar, y la retirada de los guards S1 (`334ca44`).

> **Hay un fallo vivo en PROD cuyo arreglo está en STG:** «Tomar conversación» **no funciona en
> producción desde el 28 jul** por el `42P08` (`$2` deducido como `text` y `varchar` en la misma
> consulta). Falla siempre y para todos. `30e2fb4` lo arregla y está solo en `stg`.

### 2.4 Agente Conciliación — ya en PROD

Cron operativo escribiendo `conciliacion_pagos`. **No necesita promoción**: es el *proveedor* de la
Fase 3. Su dato ya está en PROD; lo que falta es que Django lo consuma.

---

## 3. Lo irreversible, y qué lo precede (manual §6)

La pregunta que ahorra más tiempo, respondida antes de escribir las fases. **Son tres cosas, y no son
las que parecían.**

**① El primer WhatsApp pasa por un claim durable nuevo, y no tiene flag.** Es el riesgo real de todo
el viaje. `_claim_and_reserve_initial_whatsapp` decide si se envía; ante `RuntimeError` **devuelve
`False` sin enviar** («frontera durable no disponible») y ante un claim no adquirido devuelve
`replayed_sent`. Si esa capa se equivoca en PROD, **los leads dejan de recibir su primer WhatsApp, en
silencio**, y eso es el inicio del funnel entero. Es también lo que probablemente cierra los 12 pares
duplicados de `#20` — el beneficio y el riesgo viven en la misma línea de código.
→ **Punto de parada:** un lead canario con observación de la fila en `WhatsappMessage` **antes** de
dejar entrar tráfico, y un segundo envío con la misma cotización para ver el claim denegar (un guard
que nadie ha visto denegar no es un guard).
→ **Rollback:** `heroku releases:rollback` a `43bfaf2`. Minutos.

**② El drop del índice único de `phone_number`** (0053). Único DDL destructivo, y `noop_reverse` lo dice
por escrito: no se restaura, la vuelta atrás es de modo, no de esquema. **Pero en PROD es inerte hoy**:
`session_id = phone_number` en el 100 % de las filas y `session_id` es PK, así que la unicidad de
teléfono sigue impuesta. Solo empieza a importar cuando `dual` escriba filas con
`session_id ≠ phone_number` — es decir, **en una fase que este plan aplaza**.
→ **Punto de parada:** repetir las tres consultas de precondición inmediatamente antes de la ventana
(están en `scratchpad/recon-prod.js`, y su versión canónica debe vivir en este repo).

**③ Los inbound de WhatsApp que entren durante una ventana de n8n se pierden.** Meta no reintenta de
forma que nos salve. Es el coste de cada promoción de n8n, y por eso la ventana va en la franja del §1.

Todo lo demás del viaje es **aditivo** (tablas nuevas, columnas `NULL`, índices) o **gobernado por
flag**. Ninguna otra pieza necesita ceremonia.

---

## 4. Las fases

Cinco fases y una de higiene. Cada una es **un sistema, una autorización, una ventana, un E2E**. El
orden no es de comodidad: es de riesgo creciente y de dependencia, y las dos primeras entregan valor
sin depender de nada pendiente.

### Fase 1 — Dashboard (`stg` → `main`)

**Por qué primero.** Es el delta más pequeño (12 ficheros), **no toca DDL compartido**, escribe en la
BD solo por el webhook proactivo, tiene **rollback instantáneo** (promover el deployment anterior en
Vercel) y **arregla un fallo que hoy está roto en producción**. Además sirve de ensayo del
procedimiento con el riesgo más bajo del viaje.

- **Precondiciones:** ① build verde en un Preview de Vercel sobre la punta de `stg`; ② suite offline
  89/89 sobre el commit que se promueve; ③ **acreditar por comportamiento** qué camino toma el
  proactivo en PROD con `S1_DASHBOARD_MODE` **ausente** — la expectativa es el camino legacy
  (`phone_number = session_id`, coherente con el 100 % de PROD), pero es una expectativa y hay que
  observarla, no razonarla (manual §2.1); ④ dar `SELECT` sobre `dashboard_conversation_claims` al rol
  de verificación, o el `409` del segundo clic no se puede comprobar desde fuera.
- **Criterio de éxito, observable:** `POST /api/claim` → **201** y fila real en
  `dashboard_conversation_claims`; segundo clic → **409** (nunca se ha ejecutado, ni antes ni después
  del arreglo: es la prueba que falta); `/api/inbox` y `/api/db-leads` → 200 con los mismos conteos que
  antes; un mensaje proactivo real entregado a un teléfono de pruebas.
- **Rollback:** promover el deployment anterior. Segundos, sin BD implicada.
- **Duración:** una ventana de 30 min. No requiere franja de bajo tráfico (el Dashboard no atiende al
  cliente).

### Fase 2 — Django, despliegue inerte (`stg` → `main` + release Heroku)

**Qué entra:** los 89 commits y las 9 migraciones. **Qué NO cambia:** ninguna variable de entorno.
`WHATSAPP_CONVERSATION_ID_MODE` se queda en `shadow`; los cinco `PAYMENT_*` y `LEAD_FUNNEL_V2` se
quedan **ausentes** (= `False`).

- **Ejecuta:** Juan / `alfred@aguayo.co`, que es quien despliega. Nosotros verificamos. **Dos criterios,
  no uno** (manual §4): quien despliega no acredita.
- **Precondiciones:** ① las tres consultas de precondición de 0053 en verde **en el momento**;
  ② `heroku releases` con el SHA actual anotado para el rollback; ③ franja **13:00–15:00 UTC**;
  ④ acuerdo explícito sobre quién aplica el DDL de las tablas externas — el contrato S1 §8.2 se lo
  atribuye al **Agente n8n**, pero las migraciones Django lo hacen de forma convergente si llegan
  primero. **Las dos rutas existen y no deben correr a la vez.** Decisión, no descubrimiento.
- **Criterio de éxito, observable, en este orden:**
  1. las 9 migraciones aplicadas y **una segunda pasada = 0 migraciones** (prueba de persistencia, no
     inferencia de que no dio error);
  2. **lead canario:** formulario real → fila en `qualitas_lead` + `qualitas_cotizacion` + **primer
     WhatsApp recibido** + fila en `WhatsappMessage` con `status='sent'`;
  3. **el claim denegando:** segundo intento sobre la misma cotización → no se reenvía;
  4. el bot responde a un mensaje entrante (n8n sigue leyendo `whatsapp_sessions` sin cambios);
  5. redirect de pago (`usucces`) sigue llevando a `pago_exitoso`;
  6. `conversation_id` sigue escribiéndose en las sesiones nuevas (shadow intacto).
- **Rollback:** `heroku releases:rollback`. El DDL aditivo se queda (no molesta) y el índice único
  dropeado no se restaura — inerte mientras la identidad siga siendo legacy (§3②).
- **Duración:** una ventana de 45 min, la mayoría de verificación.

### Fase 3 — La verdad del pago, encendida (solo flags de Django)

Aquí está el valor de negocio de todo el viaje: **51 pólizas de 57 en `PENDIENTE`** mientras Laura sabe
en Excel cuáles se pagaron. Cierra `qualitas-issues#7` / `HYL-WAI#69` y el workaround del Bug #7 en el
Dashboard. **No depende de n8n**: las tablas de evidencia son de Django y `n8n_payment_events` (que
falta en PROD) solo hace falta para los nodos S1 del Payment, que este plan aplaza.

Escalera de un flag por vez, cada uno con su observación y su vuelta atrás de 30 segundos:

| Paso | Flag | Qué se observa antes de seguir |
|---|---|---|
| 3.1 | `PAYMENT_CONFIRMATION_WRITES_ENABLED=True` | Aparecen filas en `PaymentEvidence` con el pago observado; `estatus_pago` **no** cambia todavía |
| 3.2 | `PAYMENT_RECONCILIATION_APPLY_ENABLED` — primero **dry-run** | El comando `reconciliar_pagos` en seco lista los candidatos y **cuadran con lo de Laura**. Si no cuadran, se para aquí y no se ha escrito nada |
| 3.3 | aplicar la conciliación | `estatus_pago='PAGADO'` en las pólizas que Laura confirma, y en **ninguna** que no |
| 3.4 | `PAYMENT_OUTBOX_DELIVERY_ENABLED` | El outbox entrega; el trigger append-only impide reescrituras |

- **Precondiciones:** `conciliacion_pagos` fresco (el cron del Agente Conciliación con corrida reciente
  y exitosa), y los valores de `PAYMENT_ACTIVATING_MOVEMENT_TYPES` / `..._RECEIPT_PATTERN` /
  `..._AMOUNT_TOLERANCE` **decididos** — hoy están vacíos y no hay default.
- **Rollback:** poner el flag en `False`. Los datos escritos se quedan (son append-only por diseño) y
  eso es correcto: son evidencia.
- **Duración:** un paso por día, no los cuatro seguidos. Cada paso vale por sí mismo.

### Fase 4 — n8n, una iniciativa por ventana

Se ejecuta la mecánica del Agente n8n (`docs/2026-08-10-plan-promocion-stg-a-prod.md` §7): retrato del
antes por API, cambio **por API con script dedicado y nunca por import del fichero ni por UI**,
verificación de `webhookId` sin cambiar + `Phone Number ID Guard` presente + cero `WA Config STG` +
`detect-drift.py` en 0, E2E real, y el `PUT` de reversión escrito antes de empezar.

**Su Fase 0 —clasificar los 39 nodos con parámetros distintos en «promover / diferencia de entorno /
deuda»— no se salta.** Es la parte peligrosa porque no se ve: un nodo con el mismo nombre y otra
consulta SQL no aparece en ningún recuento. Es la única parte de este plan que son días, no horas.

Orden, con una corrección mía sobre el suyo por vista cross:

| # | Iniciativa | Estado y por qué ahí |
|---|---|---|
| 4.1 | **Retomar Conversacion** | Delta mínimo (2 nodos + `WA Config STG` → `WA Config`). Ensayo del procedimiento |
| 4.2 | **Atención humana** | **Subida desde el 3.º puesto:** ya activa en STG con tráfico, sin bloqueos conocidos, y cierra `qualitas-issues#57` — hoy el bot **puede responder encima de un humano en PROD**, que es daño de cara al cliente |
| 4.3 | **Multicotización** | **Desbloqueada** (ver §5 bis y `#75`): las cinco entregas están acreditadas en vivo en STG y ninguna está en `main` ni en PROD, así que aquí solo hay promoción. Cuatro transformaciones de producto + una corrección, suite 132/132 con siete casos contra la base de STG en transacciones que se deshacen |
| 4.4 | **Payment Confirmation (S1)** | Necesita `n8n_payment_events` en PROD (**no existe**) y depende del dictamen S1. Aplazada con la Fase 5 |
| 4.5 | **S1 en el bot principal** | 9 nodos, la pieza más grande: toca `Resolve Session` y la resolución de sesión. Va con la Fase 5, no antes |
| 4.6 | **METEPEC** | Última: inactiva en STG, `metepec_leads` no existe en PROD y `registrar_lead_metepec` necesita contraparte en Django PROD |

### Fase 5 — `shadow` → `dual`: **aplazada, y a propósito**

Es la única fase que merecería el aparato de S1, y la recomendación es **no meterla en este viaje**.

**Corrección a una versión anterior de este documento (misma fecha):** escribí que dual no estaba verde
en STG porque `qualitas-issues#69` seguía abierto. **Es falso y el error era mío:** los dos defectos de
`Resolve Session` están arreglados y acreditados en STG —el bind JSON del camino por teléfono (`#72`,
ejecuciones 879–887, de 300 006 ms a 12 ms) y el `$3` del modo payload (`#69`, relectura del workflow
vivo: *«Resolve Session $3: ARREGLADO»*)—, y el camino del quick-reply está probado de punta a punta en
la **ejecución 891 `success`** con `lookupMode = payload_v2`: selecciona B pese a haber otra sesión
`active`, A conserva su snapshot campo a campo, las otras seis sesiones del teléfono intactas y nunca
dos activas. **Los dos issues siguen abiertos en el tracker, y eso es lo que me hizo concluir mal**:
inferí el estado del sistema del estado del tracker en vez de del artefacto (manual §2.1).

**Lo que de verdad falta, que es más estrecho:**

1. **Una pata de acreditación**, no un defecto: el fixture `S1-F2` pide `outbound_count = 1` con un
   envío normal y no pudo cerrarlo porque la cotización del fixture (990011) es **sintética** y
   `Fetch Quotation Document` falló al no existir en Django. Cerrarlo exige **una cotización real**, y
   eso es del carril de Juan. No es un fallo del producto: es un fixture que no puede tener documento.
2. **Un hueco funcional declarado:** el bot **no ofrece** el quick-reply cuando el cliente pide cambiar
   de cotización por escrito. La selección por folio exige que el mensaje sean solo dígitos.
3. **El peso de coordinación**, que es el motivo principal del aplazamiento: dual no es un
   `config:set`, son cinco piezas en tres sistemas a la vez.

**Puerta de entrada a esta fase, y son todas:** la pata de `outbound` cerrada con cotización real ·
`#69` y `#72` cerrados en el tracker tras reverificar · los 9 nodos S1 del bot y los 4 del Payment en
PROD · `n8n_payment_events` creado en PROD por su dueño · el read model v2 del Dashboard acreditado en
PROD · y el drop del índice único ya aplicado (Fase 2). Solo entonces el `config:set` de `dual`, con la
vuelta a `shadow` acreditada **antes** de activarlo.

**Lo importante de esta fase es que las cuatro anteriores no la necesitan.** Desacoplar el 80 % del
valor del 20 % que exige ceremonia es la decisión de diseño que hace que este viaje no sea el anterior.

### Fase 6 — Higiene, en el momento y no al final

- **Cerrar `qualitas-issues#69` y `#72`.** Los dos están arreglados y acreditados en STG y los dos
  siguen abiertos. No es contabilidad: **me hicieron aplazar dual por el motivo equivocado** en la
  primera versión de este plan. Un tracker que miente sobre los bloqueantes cambia decisiones.
- ~~`qualitas-issues#74`~~ **hecho** (10 ago, noche): lista blanca de nivel superior, 17 canarios en las
  dos direcciones, fail-first probado y `main` como copia canónica. Verificado por mí en vivo
  (`10 destinos, 0 drift`). **Cerrar el issue** con la evidencia — ver §5 bis.
- `HYL-WAI#130`: `N8N_TOKEN` con default hardcodeado, y el valor está a la vista en la config de PROD.
  Rotarlo coordinado con las credenciales de n8n.
- Dar de alta en este repo la versión canónica de las consultas de precondición del §1, para que la
  próxima promoción no las reescriba.

---

## 5. Lo que NO viaja en este plan, y por qué

| No viaja | Motivo |
|---|---|
| `shadow` → `dual` | Funciona en STG; falta la pata de `outbound` con cotización real (carril de Juan) y son cinco piezas en tres sistemas — ver Fase 5 |
| `WA Config STG` | Es la configuración de staging. Si llega a PROD el bot responde por el número de STG: **es el Bug #15 otra vez** |
| Borrar `Phone Number ID Guard` | Existe **solo en PROD**, es la defensa que quedó de ese bug, y un import del fichero entero lo borraría. Por eso se promueve por API y por nodos |
| METEPEC | Inactivo en STG, sin `metepec_leads` ni endpoint en PROD |
| Multicotización | Hasta que el arreglo del precio esté acreditado en STG |
| `enforced` de cualquier cosa | Ninguna transición de este plan lo autoriza |
| Cualquier cosa «de paso» | Si no está en el inventario del §2, no entra en la ventana |

---

## 5 bis. Qué hay que arreglar en STG antes de ir a PROD

35 issues abiertos en `qualitas-issues`. **La mayoría no bloquea nada**, y confundirlos con bloqueantes
es la forma más fácil de convertir este viaje en el anterior. El criterio para estar en el grupo A es
uno solo: *¿promoverlo tal cual mete un defecto en PROD, o rompe el método con el que lo verificamos?*

### A · Bloquean una fase concreta — hay que arreglarlos en STG (**ninguno**)

**Este grupo ha quedado vacío hoy**, y las dos veces por verificación, no por decisión: `#74` está
resuelto (abajo) y el punto del precio de memoria **no bloquea** — es ahora `qualitas-issues#75`,
abierto como cable trampa y no como trabajo pendiente.

#### El precio de memoria: clase de defecto real, consecuencia hoy no alcanzable → `#75`

El ejecutor lo dejó abierto por escrito y me pasó la decisión: *«traer el precio en el flujo antes de
que el modelo hable toca el camino caliente de cada turno y no se hizo: es decisión del Arquitecto»*.

Lo entregado y acreditado en vivo ya cierra la parte peligrosa: `Resolve Session` devuelve el vehículo
con prefijo `[CTX:]` (y el RAG pasa a recibir prefijo, antes no recibía ninguno), el nodo
`Limpiar Turno De Cambio` con cinco puertas fail-closed retira del historial de la sesión abandonada el
flujo de cambio **entero** —8 filas exactas en las ejecuciones 946 y 949, cero en las cinco sin cambio—
y el enrutado de la pregunta de precio tiene anulación determinista. Con eso **ya no puede dar el precio
de otra cotización**.

Lo que quedaba era el riesgo de dar un precio **viejo**. **Verificado contra `HYL-WAI@stg`: no hay ruta
de código que lo dispare.** `CotizacionRespuestaXml` es `OneToOneField` a `Cotizacion` —una fila por
cotización— y se escribe con `update_or_create` (`services.py:335`), pero **sus dos únicos llamadores
(`views.py:267`, `models.py:1550`) corren inmediatamente después de `Cotizacion.objects.create(...)`**:
el objeto es siempre nuevo, así que en la práctica siempre crea y nunca refresca.

**Decisión: no se hace ahora.** El defecto es real como *clase* —cuarta vez que una instrucción pierde
contra el camino fácil— y benigno como *consecuencia*, porque memoria y consulta coinciden mientras el
cache esté congelado. Y **corrijo otra afirmación mía**: dije que «la cifra no envejece» como si fuera
garantía del esquema. No lo es —`update_or_create` puede sobrescribir—; lo que sostiene la conclusión es
**que no existe llamador con una cotización ya existente**, que es una propiedad del código actual y no
un invariante que nadie imponga. Por eso `#75` queda abierto con cable trampa: reabre si aparece una
ruta de recotización, si cambia la semántica del precio (`#18`, `precio_total` viene `None` y el real
vive en `opciones_cotizacion`), o si el flujo pasa a leer un precio que no sea el del cache congelado.

#### `#74` ya no bloquea la Fase 4 — resuelto y verificado por mí (10 ago, noche)

`Agente-n8n:handoffs/2026-08-10-respuesta-arquitecto-issue-74.md` (`main`, `063d6f2`). No lo acepto
por el informe: **lo comprobé contra la fuente**, y las cuatro comprobaciones salen a su favor.

| Lo que comprobé | Resultado |
|---|---|
| Corrida en vivo contra las dos instancias | `10 destinos revisados, 0 con drift` **reproducido por mí** |
| Los 17 canarios | 17/17 en verde, y el fichero declara las dos direcciones: **RUIDO** (dar drift sin que nadie toque) y **CEGUERA** (no darlo cuando sí se tocó), diciendo por escrito que arreglar el ruido dejándolo ciego pasaría todos los tests de ruido |
| Fail-first | Reconstruí la lista negra y corrí **los tests de hoy** contra ella: **5 fallos**, incluido el caso real de 2.28.7. Y contra el **arreglo obvio** (lista negra + `description` + `nodeGroups`): **4 fallos**, y el decisivo es `test_descripcion_de_herramienta_dentro_de_un_nodo` en la clase `SiDebeDarDrift` — es decir, el arreglo obvio **queda ciego exactamente donde importa**, y hay un canario que lo caza |
| El diseño | Pasó de lista negra recursiva a **lista blanca de nivel superior**: `("name","active","nodes","connections","settings")`. Como `nodes` entra entero, un `description` **dentro** de un nodo sí da drift, y el `description` del workflow no se mira. La distinción es de profundidad y una lista negra recursiva no puede hacerla |

**Y corrijo mi propio aviso, que era peor de lo que yo lo conté y a la vez menos grave de como lo
formulé.** Escribí que el arreglo obvio nos dejaría *«ciegos justo en el campo que gobierna el
comportamiento del bot»*. Medido contra el bot real de PROD: **11 nodos llevan la descripción de
herramienta dentro de `parameters`, y solo uno —`Validate Personal Data`— usa literalmente la clave
`description`; los otros diez usan `toolDescription`.** Así que el arreglo obvio no habría apagado el
detector —eso se nota— sino dejado **un punto ciego del 9 %**: diez herramientas vigiladas y una a
oscuras. Un fallo parcial es peor que uno total porque no hace ruido. Ellos lo verificaron saboteando
esa descripción con «llama siempre a esta herramienta»: con el arreglo obvio no se detecta, con lo
implementado sí.

**Y mi segundo dato también estaba mal.** Dije «veinte ramas con dos versiones» de `TARGETS`. Medido:
**26 ramas y cuatro versiones** (20 + 3 + 2 + 1), y 19 apuntan al retrato pre-A2 — el mapa que con
`--go` habría sacado `stg` de `7608f93`, el SHA acreditado en `#132`. **Ese riesgo llevaba ahí desde
antes del issue.** Desde hoy `main` es la copia canónica; no reescribe las otras 25 (varias están
inmóviles a propósito), pero lo que se ramifique desde ahora sale correcto.

*Discrepancia menor, sin efecto en la conclusión:* su informe dice que los tests de hoy fallan **3**
contra la versión anterior; a mí salen **5** reconstruyendo la lista negra desde
`auto-sync-workflows.py`, y **4** con el arreglo obvio. La diferencia cuadra con qué se tome por
«versión anterior» respecto a la exclusión de `pinData`, que es **posterior** (`395daf3`). Suya es la
cifra que hay que reconciliar; el fail-first está probado igual.

### B · Falsos bloqueantes: arreglados en STG y abiertos en el tracker (2)

`#69` (`$3` en modo payload) y `#72` (bind JSON por teléfono). **Los dos están cerrados en STG con
evidencia** (ejecuciones 879–887 y 891). **No hay que arreglarlos: hay que cerrarlos** tras reverificar.
Van en el grupo B y no en el A porque el coste ya se pagó: son la razón por la que la primera versión de
este plan aplazó dual por un motivo falso.

### C · No es un defecto, es una acreditación que falta (1)

El fixture `S1-F2` pide `outbound_count = 1` con un envío normal y quedó sin cerrar porque su cotización
es **sintética** (990011) y `Fetch Quotation Document` no puede encontrar un documento que no existe.
Exige **una cotización real** → **carril de Juan**. Bloquea la Fase 5, no las cuatro primeras.

### D · Están vivos en STG y en PROD: no bloquean, pero deberían viajar arreglados (7)

Todos caen en superficies que se promueven, así que arreglarlos en STG **ahora** cuesta una ventana que
ya está abierta; arreglarlos después cuesta otra.

| Issue | Crit. | Por qué merece el mismo viaje |
|---|---|---|
| **`#64`** PDF no se regenera al cambiar de cobertura | **crítico** | **Venta perdida confirmada** (lead 1767): el bot dio los precios de Limitada en texto y reenvió tres veces el PDF de Amplia. Misma superficie que 4.3/4.5 y el mejor candidato a entrar en el viaje |
| **`#39`** el AI Agent alucina el vehículo en el resumen | alto | **Misma familia que el precio de memoria:** el modelo responde del contexto en vez de consultar. Un arreglo estructural cierra los dos |
| **`#45`** AI Agent y RAG comparten `session_id` de memoria | alto | Puede dejar al usuario **sin respuesta, en silencio** |
| **`#56`** `conversation_phase` no se persiste | alto | Es el bug que obliga a leer los hitos por `LIKE` sobre el copy del bot — frágil por diseño, y cualquier cambio de copy lo rompe |
| **`#33`** `chatInput` vacío rompe Detect Jailbreak/PII | medio | Cualquier inbound sin `text.body` (audio, imagen, ubicación) |
| **`#68`** Intent Router manda a `kb_query` lo que no lo es | medio | **Verificar primero:** el enrutado se tocó al arreglar el precio (anulación determinista en `Parse Router Output`); puede estar ya cerrado |
| **`#21`** no soporta recotizar un modelo distinto | medio | **Probablemente cerrado** por la multicotización. Verificar y cerrar |

### E · No son de STG — no se arreglan aquí, y varios los cierra este plan (el resto)

| Issue | Qué hacer |
|---|---|
| **`#7`** Django no escribe `estatus_pago='PAGADO'` | **Lo cierra la Fase 3.** Es el valor de negocio del viaje |
| **`#20`** leads duplicados (~11 %, 12 pares en 30 días) | **Lo cierra probablemente la Fase 2** (fencing del envío inicial). Verificar después, no antes |
| **`#4`** leads sin `whatsapp_session` | Misma familia. Verificar tras la Fase 2 |
| **`#57`** el bot responde encima del agente humano | **Lo cierra la Fase 4.2.** En STG los tres triggers de Atención Humana estaban muertos en un gate de ingreso y quedaron operativos; la promoción es la que arregla PROD |
| **`#29`** deployments Preview del Dashboard sin purgar | Higiene de Vercel, tocarlo en la ventana de la Fase 1 |
| `#9` `#49` `#40` `#48` `#13` `#18` `#28` `#37` | **Carril de Juan.** No bloquean ninguna fase |
| `#25` `#26` `#27` + `HYL-WAI#130` | Secretos y buckets compartidos STG↔PROD. **La promoción no los agrava, pero siguen vivos** y el `N8N_TOKEN` está a la vista en la config de PROD |
| `#3` `#23` `#24` `#41` `#43` `#60` `#66` | Cola menor, fuera de este viaje |

### Resumen en una línea

> **No hay que arreglar nada en STG para las Fases 1, 2, 3 ni 4.** Los dos candidatos a bloqueante
> cayeron el mismo día al verificarlos: `#74` está resuelto (corrida en vivo reproducida por mí) y el
> precio de memoria no tiene ruta de código que dispare su consecuencia (`#75`, cable trampa). Lo único
> que queda de verdad es la **Fase 5**, y lo que le falta es una cotización real de Juan. Todo lo demás
> es o tracker sucio, o trabajo que conviene meter en una ventana ya abierta, o carril ajeno.

---

## 6. Lo que hay que decidir antes de arrancar (ninguna es técnica)

1. **¿Se autoriza el viaje sin cerrar S1?** Las Fases 1–4.3 no dependen de S1; el contrato S1 dice
   *«ninguna transición S1 autoriza PROD»*, así que PROD necesita su propia autorización de todos
   modos. **Mi recomendación: sí, y por eso el plan aplaza dual.** — Alberto, con visto de Juan.
2. **¿Quién aplica el DDL de las tablas externas en PROD?** El contrato lo atribuye al Agente n8n; las
   migraciones Django lo hacen igual si llegan primero. Elegir una ruta y desactivar la otra. — Juan +
   Alberto.
3. **Los cuatro parámetros de conciliación** (`MOVEMENT_TYPES`, `RECEIPT_PATTERN`,
   `AMOUNT_TOLERANCE`): hoy vacíos, sin default. Sin ellos la Fase 3 no arranca. — Alberto + Laura.
4. ~~¿Se promueve la multicotización con el precio arreglado pero sin segunda corrida?~~ **Resuelta por
   mí el 10 ago**: sí, el precio de memoria no bloquea (`#75`). Ya no necesita decisión de Alberto.
5. **Los tres workflows inactivos de STG** (`Issue Policy Guard`, los dos de METEPEC): ¿se terminan o se
   quedan? Tres de cuatro inactivos sugiere que no están acabados. — Alberto.

---

## 7. Reglas de ventana — una página, y sustituye al aparato de S1

1. **Un sistema por ventana.** Una autorización, un rollback escrito **antes**, un E2E.
2. **Franja 13:00–15:00 UTC** (07:00–09:00 MX) para lo que atienda al cliente. Fuera de esa franja solo
   Dashboard y flags.
3. **Retrato del antes, siempre**, y del estado que se va a cambiar. Sin lectura previa, un `PASS` no
   distingue haber cambiado algo de haberlo encontrado ya así.
4. **Quien ejecuta no acredita.** Dos personas o dos roles, nunca el mismo criterio dos veces.
5. **Se rellena desde la observación**, campo a campo. Nunca se copia el valor esperado de la plantilla.
6. **Cero cambios por UI** sobre workflows de n8n: el editor re-serializa al guardar y *Execute* guarda.
7. **Si aparece algo inesperado, se para y se cierra la ventana.** No se arregla dentro. Reabrir cuesta
   una ventana; arreglar dentro costó, en S1, un día por vez.
8. **Toda desviación se declara en el momento**, incluidas las propias y las incómodas.

---

## 8. Estimación honesta

| Fase | Trabajo real | Ventana |
|---|---|---|
| 1 · Dashboard | preparar y verificar: medio día | 30 min |
| 2 · Django inerte | coordinación con Juan + verificación: 1 día | 45 min |
| 3 · Verdad del pago | 4 pasos, uno por día, con contraste contra Laura | 15 min cada uno |
| 4 · n8n | **Fase 0 de clasificación: varios días** + 3 promociones cortas | 30–45 min cada una |
| 5 · dual | no estimable hasta cerrar `#69` | — |

**Lo honesto:** las Fases 1, 2 y 3 son **una semana** de trabajo tranquilo y entregan casi todo el
valor —el botón de Tomar conversación arreglado, el fencing del primer WhatsApp, y Django sabiendo por
fin qué se ha pagado—. La Fase 4 la marca la clasificación de los 39 nodos, que es de su dueño y no se
acelera. Y la Fase 5 depende de una pata de acreditación que está en el carril de Juan (un envío real
sobre una cotización real) más la coordinación de cinco piezas en tres sistemas.

Quien prometa «pasamos STG a PROD esta semana» está hablando de las Fases 1–3. Y eso ya es mucho.
