# Plan de promoción STG → PROD — versión ágil

> **Premisa de Alberto (22 ago, noche):** PROD está apagado, no hay visitas en la landing. Salimos
> rápido y lo que se rompa en PROD se arregla ahí. Doble objetivo: **PROD limpio** y **STG y PROD
> espejo**.
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

## 3. Las fases

Cada fase es independiente, se verifica midiendo y tiene vuelta atrás. Con PROD apagado, **no hay
ventana de mantenimiento que respetar**: el orden es por dependencia técnica, no por horario.

### F0 · Red de seguridad (30 min, no toca nada vivo)

1. Export de los **5 workflows vivos de PROD** al repo, en rama y commiteados. Es la marcha atrás de
   n8n: sin esto, un import malo no se deshace.
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

Merge `stg` → `main` (limpio, sin trabajo divergente) y deploy a `hyl-wai-production`. El release
phase corre las **18 migraciones** `0062…0079`.

**Verificación:** `django_migrations` en 79 con `0079_first_receipt_payment_models` como última, y las
tablas de descuento presentes.
**El objetivo se mueve, y hay que clavarlo.** Juan sigue integrando en `stg`: fusionó el `#160` el
22 ago y el 23 aprobó el plan técnico del `#203`. Si no se congela nada, la E2E de **F6** acabará
validando un árbol que ya no existe.

**Regla:** en F2 se **anota el SHA de `stg` que se promueve** y ese es el árbol que recorre F4→F6.
Lo que Juan integre después entra en la promoción siguiente, no en esta. Con PROD apagado, promover
otra vez es barato; validar dos árboles a la vez, no.

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
