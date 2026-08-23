# Plan de promoción STG → PROD — versión ágil

> **Premisa de Alberto (22 ago, noche):** PROD está apagado, no hay visitas en la landing. Salimos
> rápido y lo que se rompa en PROD se arregla ahí. Doble objetivo: **PROD limpio** y **STG y PROD
> espejo**.
>
> **Segunda premisa (Alberto, 23 ago):** **ningún mensaje de pruebas puede llegar a un teléfono de
> cliente.** Si hay que enviar algo, se envía al de Alberto: **`5551074144`**.
>
> **Todo número de este documento está medido el 22-23 ago 2026 contra la fuente viva** —API de n8n,
> base de datos de producción, Heroku y los exports que el monitor de drift acredita como fieles.
> Nada viene de memoria ni de informes.

---

## 1. El hueco real, medido

| | PROD | STG |
|---|---|---|
| Django | `53103dd` (release **v341**, 13 ago) | `372f63f` (release v236, 21 ago) |
| Migraciones Django | **61** (`0061_business_outbox_identity_trigger`) | **79** (`0079_first_receipt_payment_models`) |
| Tablas de descuentos | **ninguna** | todas |
| Funciones `n8n_*` en la base | **ninguna** | las de las 24 migraciones SQL |
| `conversation_control_v1` | **no existe** | existe |
| Bot de WhatsApp | **119 nodos** | **228 nodos** |
| Workflows en la instancia | 5 | 9 (+ Error Handler, poller de descuentos, Metepec ×2, Issue Policy Guard) |
| Red de error (`errorWorkflow`) | **0 de 5** | conectada |
| Sesiones | **1.066 `open` / 15 `closed`** | — |

`stg` va **86 commits por delante** de `main`; los 16 que `main` tiene y `stg` no son **todos** merges
de promociones anteriores. **No hay trabajo divergente: la promoción de código es un merge limpio.**

---

## 2. Cuatro cosas que decidir antes de tocar nada

### 2.1 PROD perdería su `Phone Number ID Guard` — el hallazgo más peligroso

`Phone Number ID Guard` es **el único nodo que PROD tiene y STG no**. Es el primer nodo después del
trigger y deja pasar únicamente los mensajes cuyo `phone_number_id` es el de producción
(`1028815256982638`). Nació del incidente del 7 de julio, cuando el número de pruebas compartía
webhook con PROD.

En STG, el nodo equivalente en esa posición es `WA Config STG`, que **no filtra: asigna**. Si
promovemos el grafo de STG tal cual, **PROD se queda sin ese guard** y vuelve a ser alcanzable desde
el número equivocado.

**Decisión:** el guard entra en el grafo espejo, en los dos entornos, con el id de su entorno como
parámetro. Un filtro que solo existe en uno de los dos lados no es un espejo, es una excepción que
se pierde en la siguiente promoción.

### 2.2 El esquema de la capa S1 no existe en PROD, y Heroku no lo instala

La base de producción **no tiene ni una** función `n8n_*`, ni `conversation_control_v1`, ni tablas de
descuento. El bot de 228 nodos **no arranca sin eso**: sus claims, fences y carriles llaman a esas
funciones.

Y no llegan con el deploy: las 24 migraciones SQL viven en `Agente-n8n/migrations/` (156/001→021,
161/001-002, 163/001) y **se aplican a mano**. Es exactamente el `#122` (objetos de BD fuera de las
migraciones de Django) cobrándose su factura.

**Decisión:** el esquema va **primero y solo**, en una ventana propia, antes que cualquier código.
Es aditivo y no cambia comportamiento: nadie lo consume hasta que entra el bot nuevo.

### 2.3 `WA Config STG` lleva el entorno en el nombre

Un espejo no puede tener nodos que se renombran al promover: cualquier test, guard o monitor que
referencie el nodo por nombre se rompe en el otro lado. **Se renombra a `WA Config`** en los dos
entornos, con el `phoneNumberId` como valor y no como nombre.

### 2.5 `Issue Policy` apunta al guard de STG **por id de instancia** — bloqueante

Hallazgo de F3, verificado por mí en el candidato de PROD: el nodo `Issue Policy` referencia el
workflow `Issue Policy Guard` por el id de la instancia de **STG** (`PuogahK4qv9YOiF4`), y ese
workflow **no existe en PROD**.

Importar el candidato tal cual haría que **la emisión de pólizas de producción llamara al guard de
staging**. Es la operación más sensible del sistema llamando a otro entorno.

**Bloquea F4** hasta que existan en PROD sus propios `Issue Policy Guard` y `Error Handler`, y la
tabla de configuración gane una fila `workflowRefs`. El ejecutor **no** lo tapó con una columna nula,
y hace bien: un espejo que traduce a «nada» no es un espejo.

### 2.4 Quién despliega Django en PROD

Los releases de producción los ha hecho históricamente `alfred@aguayo.co` — la cuenta de Juan. El
release phase de `heroku.yml` corre `manage.py migrate --noinput`, así que **el deploy aplica las 18
migraciones solo**. Hay que confirmar con Alberto si dispara él (es member de la app) o si esta parte
se coordina con Juan.

---

## 2.bis · La premisa del teléfono, traducida a controles

El riesgo real no es que alguien teclee a un cliente: es que **el sistema escriba solo**. Y PROD no
está tan apagado como suena.

**Medido el 23 ago en la base de producción:**

| qué | dato |
|---|---|
| Leads nuevos en 14 días | **9** — el último el 21 ago a las 18:03 |
| Envíos de Django en 30 días | **273** plantillas iniciales + **183** followups de 15 min |
| Último envío de Django | **21 ago, 18:10** |
| Último mensaje entrante de un cliente | **19 ago** |
| Sesiones abiertas que alimentan lo proactivo | **1.066** |

La landing está casi apagada —un lead cada día o dos—, pero **el número de WhatsApp está vivo**: cada
uno de esos leads recibió su plantilla y su seguimiento automático, a una persona real. Si uno cae en
mitad de la promoción, se encuentra un sistema a medio migrar.

**Los controles, cada uno en su punto único:**

1. **Nada proactivo encendido** hasta el final: los cuatro comandos de Django
   (`enviar_seguimientos_whatsapp`, `reintentar_checkpoint_followup`, los dos `sync_qualitas_*`), el
   Heroku Scheduler —incluido el job legacy que nadie ha podido inventariar—, el poller de descuentos
   y `Retomar Conversación`.
2. **Red dura en n8n:** `public.n8n_outbound_reserve` es el punto por el que pasa **todo** envío del
   bot y ya resuelve el teléfono internamente. Una allowlist ahí, activa durante la ventana, rechaza
   cualquier destinatario que no sea el de pruebas — con su motivo, no en silencio.
3. **Red dura en Django:** el envío a Meta sale por un único sitio (`qualitas/services.py`,
   `enviar_template_whatsapp`). **Hoy no existe ninguna allowlist**: lo único parecido es un dry-run
   de los checkpoint followups. Hay que añadirla, por variable de entorno.
4. **La limpieza de sesiones (F7) sube de sitio:** las 1.066 abiertas son el combustible de lo
   proactivo. Se limpian **antes** de encender nada, no después.
5. **Identidad de pruebas única:** `5551074144`. Cualquier prueba que necesite un mensaje real usa
   ese número y ningún otro.

**Consecuencia sobre la primera premisa:** «lo que se rompa en PROD lo arreglamos ahí» sigue valiendo
para el sistema, no para el cliente que escriba ese día. Con los controles 1-3 puestos, romper es
barato; sin ellos, un lead a destiempo lo paga una persona.

## 3. Las fases

Cada fase es independiente, se verifica midiendo y tiene vuelta atrás. Con PROD apagado, **no hay
ventana de mantenimiento que respetar**: el orden es por dependencia técnica, no por horario.

### F0 · Red de seguridad (30 min, no toca nada vivo)

1. ~~Export de los **5 workflows vivos de PROD** al repo, en rama y commiteados.~~ **YA HECHO, y
   verificado el 23 ago contra la instancia viva.** Los cinco están en
   `aibanez82/Agente-n8n:main/workflows/` (árbol limpio desde el 13 ago) y **los cinco `versionId`
   coinciden con los de la API de PROD** — que es la comprobación fuerte: no es que tengan el mismo
   número de nodos, es que son el mismo objeto.

   | Workflow | id | Nodos vivos = export |
   |---|---|---|
   | WhatsApp Insurance Quotation Bot | `BtOaZm7WlZT-24V7hqCnF` | 119 |
   | Monitor Qualitas SIO PROD | `3NQfglVIfPSdijm9` | 19 |
   | Atencion Humana | `B5ihE5xHg8bjeesl` | 19 |
   | Retomar Conversacion | `96XfJZcwvlHnVJLko3G8-` | 12 |
   | Payment Confirmation | `disvKr7iVhnNnefuiqJbJ` | 5 |

   **Y un aviso que sale de aquí:** la copia de `Agente-Arquitecto:docs/n8n-workflows/` tiene **3 de
   5**, y el bot congelado en **113 nodos desde el 26 jul**. CLAUDE.md la llama «la única red de
   seguridad» y lleva un mes sin serlo. La red real es la del repo del n8n; hay que reapuntar el
   puntero o retirar la copia muerta, porque **una red de seguridad falsa es peor que ninguna**:
   invita a tirarse.
2. `heroku pg:backups:capture -a hyl-wai-production` — la marcha atrás del esquema.
3. Anotar la línea base: release **v341**, Django `53103dd`, 61 migraciones, `versionId` y recuento de
   nodos de cada workflow.

**Verificación:** los cinco JSON en git y el backup listado por `heroku pg:backups`.
**Vuelta atrás:** ninguna necesaria — esta fase solo lee.

### F1 · El esquema de la capa S1 (aditivo)

Aplicar a la base de PROD, en orden, las 24 migraciones SQL de `Agente-n8n/migrations/`. Son
reentrantes: se han aplicado ya a STG y varias se han repetido sin daño.

**Verificación medible, la misma consulta que usé para el diagnóstico:** que existan las funciones
`n8n_outbound_reserve`, `n8n_discount_phase2_claim`, `n8n_cotizacion_sin_poliza` y la vista
`conversation_control_v1`.
**Vuelta atrás:** el backup de F0. En la práctica no hace falta: nada consume estos objetos todavía.
**Cierra:** la mitad de `#122` (queda documentar el inventario).

### F2 · Django

Promoción de **`stg@372f63f`** a `main` (limpio, sin trabajo divergente) y deploy a
`hyl-wai-production`. El release
phase corre las **18 migraciones** `0062…0079`.

**Verificación:** `django_migrations` en 79 con `0079_first_receipt_payment_models` como última, y las
tablas de descuento presentes.
**El objetivo se mueve, y hay que clavarlo.** Juan sigue integrando en `stg`: fusionó el `#160` el
22 ago y el 23 aprobó el plan técnico del `#203`. Si no se congela nada, la E2E de **F6** acabará
validando un árbol que ya no existe.

**Regla:** en F2 se **anota el SHA de `stg` que se promueve** y ese es el árbol que recorre F4→F6.
Lo que Juan integre después entra en la promoción siguiente, no en esta. Con PROD apagado, promover
otra vez es barato; validar dos árboles a la vez, no.

**Y el mecanismo, porque la regla sola no lo impide (añadido 23 ago, tarde).** Este plan decía
«merge `stg` → `main`», y eso **ya no promueve el árbol congelado**: medido contra `origin` esta
tarde, `origin/stg` va **32 commits por delante** de `372f63f` —el tip es `09dedd6`, el merge del
`#203` de esta mañana— y un `merge stg` literal arrastraría las ocho migraciones que este mismo plan
excluye:

```
0080_receipt_ledger_models       0084_receipt_ledger_same_policy_guards
0081_general_receipt_poll_state  0085_reject_unicode_c
0082_preserve_paid_full…         0086_receipt_ledger_query_indexes
0083_payment_poll_observation…   0087_receipt_sensitive_base_manager
```

Una regla escrita en un documento no detiene un comando. **El congelado tiene que ser un objeto de
git**, y la casa ya tiene el patrón: la promoción anterior entró por
`release/promote-stg-to-main-20260810` → PR `#158`, que es el `53103dd` que hoy corre en PROD.

Igual aquí: cortar **`release/promote-stg-to-main-20260823` desde `372f63f`** —no desde `stg`— y
abrir el PR de esa rama contra `main`. El diff del PR pasa a ser la lista exacta de lo que se
promueve, revisable **antes** de fusionar, y lo que Juan integre mientras tanto no puede colarse
por descuido de nadie.

**Vuelta atrás:** `heroku rollback v341`. **Ojo:** el rollback devuelve el código, **no** deshace las
migraciones. Por eso F1 y F2 son aditivas por diseño: lo que entra, se queda.
**Cierra:** `#174` (el fallback genérico), `qualitas-issues#85.1` (instrucciones contradictorias) y
todo lo Django que STG ya lleva.

### F3 · Construir los candidatos de PROD — **ENTREGADA la noche del 22 ago**

Hoy el builder de `Agente-n8n` produce candidatos **de STG**. Para el espejo hace falta que produzca
los dos, desde la **misma fuente de grafo** y con una **tabla de configuración por entorno**:

| qué cambia entre entornos | PROD | STG |
|---|---|---|
| credenciales (7) | `…Hylant Account`, `Django N8N_TOKEN PROD`, `WA Media Access PROD`, `OpenAI KB Embeddings PROD`, `Postgres account` | sus gemelas `… STG` |
| `phoneNumberId` | `1028815256982638` | `1259868760534397` |
| `webhookId` | 4 nodos con id propio | los suyos |
| `errorWorkflow` | el Error Handler de PROD (a crear) | `nT6395r2jjMUqVyF` |

**Estado — verificado por mí contra los artefactos, no contra el informe:** entregada en
`origin/stg@c534d64` (PR #88). Dos candidatos de **229 nodos** cada uno, mismos nombres, **conexiones
idénticas** y **cero diferencias fuera de la tabla** (88 nodos difieren, los 88 por credenciales,
`webhookId` o `phoneNumberId`). El guard del 7 de julio entró parametrizado en el grafo compartido y
`WA Config` perdió el sufijo. sha256: STG `45b9c183…`, PROD `5240518e…` — calculados por mí.

**Consecuencia inmediata:** hasta que el rename y el guard entren en el bot vivo de STG, el monitor
de drift listará `main-candidato` como **deriva real esperada**. Es correcto que lo haga.

**Verificación:** el candidato PROD y el de STG deben diferir **solo** en esa tabla. Cualquier otra
diferencia es un fallo del builder, no una particularidad del entorno.
**Cierra:** la causa raíz de que los dos entornos diverjan.

### F4 · Import en n8n, y la red de error **primero**

Orden, y el orden importa:

1. **Los workflows auxiliares de PROD primero: `Error Handler` e `Issue Policy Guard`.** El primero
   para que un fallo avise en vez de morir en silencio; el segundo porque sin él el candidato apunta
   al guard de STG (§2.5). Con los dos creados, la tabla gana su fila `workflowRefs` y el candidato
   de PROD se regenera — **no se parchea a mano**.
2. **`errorWorkflow` enlazado** en los cinco workflows de PROD.
3. **Bot principal** (119 → 229 nodos).
4. Payment Confirmation, Retomar Conversación, Atención Humana.
5. Poller de descuentos y Metepec.

Cada import por **delta medido**, no por reemplazo: el reemplazo se lleva por delante los `settings`
—y con ellos el `errorWorkflow`— como estuvo a punto de pasar esta noche en STG.

**Verificación tras cada uno:** recuento de nodos esperado, `active`, `errorWorkflow`, `webhookId` del
trigger y credenciales intactas, leído **en la instancia**.
**Vuelta atrás:** reimportar el export de F0.
**Cierra:** `#192` (la red de error), `#197`, `#206`, `#189` puntos 1 y 2, `#69`/Bug #7 (las tres
barreras del `completed` sin pago verificado).

### F5 · Flags

Los módulos nuevos llegan apagados por diseño (`QUALITAS_FIRST_PAYMENT_SYNC_MODE=off`, descuentos sin
activar, scheduler parado). Se encienden **uno a uno**, midiendo entre uno y otro.

Con PROD apagado esto es barato: no hay tráfico real que pueda tropezar con un flag a medias.

**Antes de encender nada, inventariar el Heroku Scheduler de PROD.** La validación de STG del `#203`
(23 ago) dejó este cabo suelto explícitamente: la CLI no expone el inventario del Scheduler clásico,
así que **no se pudo afirmar** si el job legacy `sync_qualitas_first_payments` sigue existiendo. En
STG da igual; en PROD, un job legacy despertando contra el proveedor mientras encendemos el nuevo
sync es la clase de sorpresa que este plan existe para evitar. Se resuelve mirando el dashboard, no
adivinando.

### F5.bis · Dashboard — **añadido el 23 ago; no estaba, y era punto ciego**

Ni «incluye» ni «no incluye» lo nombraban. Lo levantó el **Agente Dashboard** leyendo este plan, y
lo decidió Alberto: **entra en esta promoción**.

`Dashboard_seguroautoqualitas` tiene `stg` **76 commits** por delante de `main` y **sin trabajo
divergente** (los 66 que `main` tiene de más son `handoffs/` y `docs/`). Lo que producción no tiene
es **la mitad de Atención Humana**: `apps/operacion/lib/s1/` entera, `operator-send.js`,
`discount-reconciliation.js`, la selección comercial del `#156` y el `#177` (Metepec oculto). El
`#57` se cierra con la cadena tomar → claim → iniciar → `human_takeover` → guard, y el primer
eslabón es UI del Dashboard: sin esta fase, la cadena queda coja en PROD.

**Orden: después de F5, antes del smoke de F6.** Antes de F5 pondría en producción una UI que llama
a webhooks de n8n que allí todavía no responden — peor que no tener los botones, porque es un fallo
silencioso delante de Hylant.

**Por qué es seguro, medido contra la base de producción y no contra el fichero.** El riesgo de un
consumidor de solo lectura no es escribir: es que le desaparezca por debajo algo que hoy consulta.
En las 18 migraciones `0062…0079` hay **58 `AddField`, 48 `AddConstraint`, 18 `CreateModel`… y un
solo `RemoveField`** — y ese quita `discounttrigger.offered_copy`, sobre una tabla que **crea la
`0063`** dentro de esta misma tanda. Estado de PROD ahora:

```
tablas qualitas_discount*   : NINGUNA
migraciones qualitas        : 61 | última 0061_business_outbox_identity_trigger
conversation_control_v1     : NO existe
```

**Contra el esquema que PROD tiene hoy, F1 y F2 son netamente aditivas.** Nada de lo que el
Dashboard lee hoy desaparece.

**Matiz que no cambia el orden pero sí el smoke:** «solo lectura» no es exacto. `operator-send.js` y
`n8nOperatorWebhook` **escriben**, vía el webhook proactivo de n8n — la excepción que `CLAUDE.md` ya
reconoce. F6 tiene que cubrir esa cadena, no solo que la página pinte.

**~~Abierto: la ventana de `session_id NOT NULL`~~ — CERRADO el mismo día.** Medido por mí contra
`hyl-wai-production`: `dashboard_conversation_claims.session_id` es `is_nullable = NO`, con
`uq_claims_active_session`, `uq_claims_active_lead` y `uq_claims_control_id`. **No hay bloqueo de
esquema.**

### Condición real de F5.bis: el gate del envío

Lo que sí apareció, y no lo vi yo: **promover `stg` mete la cadena de envío** que el handoff del 13
ago decidió NO cablear. Lo levantó el Agente Dashboard. Al verificarlo salió peor de lo previsto:

- `N8N_OPERATOR_WEBHOOK_BASE_URL` y `..._SECRET` llevan **11 días en Production**;
- el workflow `Atencion Humana` de PROD (`B5ihE5xHg8bjeesl`) está **`active`** y expone
  `atencion-humana-enviar` con la cadena entera detrás.

Hoy no se envía **solo porque `operator-send.js` no existe en `main`**. Promover no enciende nada:
retira lo último que tapaba algo ya encendido.

**Y quitar esas dos variables NO es la salida** —fue mi primera recomendación y era errónea—:
gatean el **cliente entero** (`lib/n8nOperatorWebhook.js:73-75`), incluidos el `tomar` y el `liberar`
que usa `claim.js` en `:82` y `:157`. Apagarlas rompería Atención Humana hoy y reabriría el `#57`.
El fallo, además, es del tipo peligroso: **la opción que suena conservadora era la destructiva.**

**Decisión de Alberto (23 ago): opción (a″)** — gate propio `N8N_OPERATOR_SEND_ENABLED`, **ausente en
PROD**, con un único `if` en `operator-send.js` que devuelva 503 antes de cualquier efecto. Separa
**transporte** («sé hablar con n8n») de **capacidad** («puedo enviar»), que es la distinción que
faltaba: por eso la decisión de agosto se sostenía con una ausencia de código y no con un control.
El estado seguro sale **por omisión** — hay que acordarse de encender, no de apagar.

Dos condiciones: `reason_code` **distinto** del `control_module_off` de transporte, y el gate **solo**
en `operator-send.js`, nunca en el cliente. Ordenado en
`Dashboard_seguroautoqualitas:main:handoffs/2026-08-23-gate-propio-para-el-envio-de-atencion-humana.md`
(`7f8b0e2`). **F5.bis no entra hasta que ese gate esté.**

**Verificación:** el deploy de Vercel apuntando al SHA promovido, y la cadena de Atención Humana
recorrida en F6 de punta a punta.
**Vuelta atrás:** rollback del deployment en Vercel — inmediato y sin tocar la base.

### F6 · Smoke E2E con nuestro teléfono, antes de abrir la landing

El guion es el de esta noche, ampliado, y **con el número de pruebas apuntando a PROD**:

1. cotización → PDF;
2. objeción de precio → pre-mensaje → **75 s** → oferta con botones;
3. mensaje del cliente **durante** la pausa: contesta y la oferta llega igual;
4. pregunta de cobertura: responde y **no** ofrece la Limitada;
5. aceptar el descuento → cotización nueva + PDF;
6. emisión → link de pago;
7. y el caso que solo se ve en PROD: un teléfono con **póliza ya emitida** que escribe → responde por
   sesión nueva, sin ambigüedad y sin silencio.

**Ninguno de estos pasos se da por bueno con «me llegó el mensaje»:** se cruza contra las ejecuciones
de n8n y el ledger, como se hizo con el `#202`.

### F7 · Limpieza de PROD

Lo que no viaja en un merge y hay que arreglar allí:

1. **Las 1.066 sesiones abiertas.** Cerrar las que ya no pueden avanzar —póliza emitida, rechazo
   explícito, inactividad larga— y dejar el pool limpio. La herramienta `Mark Session Closed` ya
   existe en el bot de PROD. Es `#189` punto 3.
2. **`estatus_pago` no fiable:** solo 1 de cada 10 pólizas realmente pagadas figura `PAGADO`. La
   verdad está en `conciliacion_pagos`; con `#160` promovido, el primer recibo se confirma solo.
3. **`#130`**: quitar el default hardcodeado de `N8N_TOKEN` y rotarlo, coordinado con la credencial de
   n8n. Es la única tarea de seguridad que la promoción **no** arregla sola.

### F8 · El espejo, y cómo se mantiene

1. El monitor de drift ya vigila los destinos de PROD y hoy da **12 destinos, 0 con drift**. En cuanto
   PROD tenga los workflows nuevos, sus destinos se añaden al mapa.
2. **Regla, ya probada esta noche:** cada deploy refresca el espejo en el mismo movimiento, y el
   espejo declara el mismo `versionId` que la instancia.
3. El inventario de promoción deja de ser una lista de deuda y pasa a ser un registro de lo
   promovido.

---

## 4. Qué cierra este plan, y qué no

**Cierra:** `#192`, `#174`, `#197`, `#206`, `#189` (los tres puntos), `#69`/Bug #7,
`qualitas-issues#85.1`, la mitad de `#122`, y el `#132` en lo que depende de nosotros.

**No cierra, y conviene decirlo en voz alta:**

- **`#204` y `#205`** — son de Django y de Juan. Si el módulo de descuentos entra en PROD **antes** de
  que se arreglen, el followup legacy pisará conversaciones reales y Django podrá conceder dos ofertas
  vivas a la vez. Con PROD apagado no duele; el día que se abra la landing, sí. **Esto marca el orden:
  la landing no se abre antes que esos dos.**
- **`#207`** (el link de pago) y **`#144`** (recordatorios de cobro): dependen de Django y de una
  plantilla de Meta que lleva bloqueada desde julio. La promoción no los toca.
- **`#194`, `#190`, `#196`**: trabajo pendiente de Juan, no de la promoción.

**Una preocupación que se despeja:** el plan aprobado del `#203` deja `public.conciliacion_pagos` y
`reconciliar_pagos` **intactos y fuera de alcance**. El Agente Conciliación y el sync de pagos de
Django no se pisan: no hay dos escritores para la misma verdad.

---

## 5. Lo que este plan asume, y que Alberto debe confirmar mañana

1. **Quién despliega Django en PROD** (§2.4).
2. **El guard del teléfono** entra en el grafo espejo (§2.1) — es una decisión de diseño, no un
   detalle de implementación.
3. **Cuándo se reabre la landing.** El plan no lo decide: lo condiciona a F6 en verde y a `#204`/`#205`
   resueltos.
5. **El SHA de `stg` que se congela para esta promoción** (§F2). Juan sigue integrando: el `#203`
   ya tiene plan aprobado y llegará a `stg`.

4. **Si el módulo de descuentos entra en la misma tanda o en una segunda.** Entra completo por
   defecto, porque separarlo obliga a mantener dos grafos distintos y eso rompe el espejo.

---

## 6. La primera hora de mañana

1. Responder las cuatro de §5 — son cuatro respuestas, no cuatro reuniones.
2. Lanzar **F0** al Agente n8n: exports, backup y línea base. No toca nada vivo y deja la marcha atrás
   montada.
3. **F3 ya está hecha** (entregada la noche del 22 ago y verificada). Lo que ocupa su sitio en el
   camino crítico es crear los dos workflows auxiliares de PROD del §2.5: sin ellos, F4 no arranca.

F1 y F2 pueden correr en cuanto F0 esté; F4 depende de F3.
