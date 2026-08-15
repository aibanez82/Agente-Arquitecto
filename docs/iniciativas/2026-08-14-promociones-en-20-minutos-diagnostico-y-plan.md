# Promociones entre entornos en 20 minutos — diagnóstico y plan

**Fecha:** 14 ago 2026 · **Autor:** Arquitecto · **Estado:** propuesta, nada aquí se ejecuta sin autorización.
**Encargo de Alberto:** *«que yo diga "pasemos todo a STG" y eso dure 20 min máximo y todo automático. Lo mismo para PROD.»*
**Alcance:** todo el ecosistema **excepto Heroku/Django** (fuera por petición explícita; ver §7).

---

## 0. El veredicto, en una frase

**El objetivo es alcanzable, pero no automatizando lo que hacemos hoy: hay que cambiar *qué* se
promueve.** Hoy promovemos **cambios** —cada uno reimplementado a mano contra un grafo distinto en
cada entorno—; para que quepa en 20 minutos hay que promover **artefactos**: un artefacto único por
sistema + una capa de configuración por entorno + un aplicador idempotente + un gate automático.

Mientras el artefacto de STG y el de PROD sean **dos cosas distintas**, ninguna herramienta puede
hacer la promoción en 20 minutos, porque el trabajo no es copiar: es traducir.

---

## 1. Lo que cuesta hoy, medido

Los números salen de leer los repos hoy, no de memoria.

### 1.1 n8n — no existe un artefacto promovible

Comparando `WhatsApp Insurance Quotation Bot_stg.json` contra `WhatsApp Insurance Quotation Bot.json`
(los dos en `Agente-n8n`, rama `stg`):

| | |
|---|---|
| Nodos en STG | **153** |
| Nodos en PROD | **113** |
| Solo en STG | **41** nodos (27 son `C1 Gate — …`, andamiaje de pruebas; el resto: afinidad, METEPEC, `WA Config STG`, terminales) |
| Solo en PROD | **1** (`Phone Number ID Guard`) |
| Nodos comunes con **parámetros** distintos | **39** |
| Nodos comunes con **credenciales** distintas | **37** |

No son «el mismo workflow con otra configuración». Son **dos grafos divergentes**. Por eso la Fase 0
del plan de agosto —clasificar los 39 nodos— era «la parte que son días, no horas»: es reconciliación
manual, y hay que rehacerla en cada viaje.

**Y el mecanismo lo confirma:** en `Agente-n8n/scripts/` hay **73 scripts de un solo uso**
(44 `deploy-*`, 29 `fix-*`), **46 apuntando a STG y 27 a PROD**. El patrón dominante es escribir el
mismo cambio **dos veces**, una por entorno (`deploy-m49-adenda9-stg.py` / `…-prod.py`,
`deploy-entrega-cotizacion-quick-reply-stg.py` / `…-prod.py`, y así). Cada script es correcto y está
bien hecho; el problema es que **su existencia es el coste**.

### 1.2 La configuración de entorno vive dentro del artefacto

IDs de credencial, `phoneNumberId`, URL de Django, nombres de nodo (`WA Config STG`). Es exactamente
la causa del defecto real que llegó a producción el 13 de agosto: tres nodos de Multicotización
viajaron con la credencial `Postgres STG` (`5wlLe3gD07CLIM7U`), que en PROD no existe, y el bot cayó
al fallback. El guard antifugas miraba nombres de nodo y referencias `$('…')`; **el ID de credencial
era una tercera vía y no estaba en la lista**.

Mientras el valor de entorno esté *dentro* del JSON, cada promoción es una oportunidad de fuga y
necesita un guard nuevo por cada forma de fuga que se descubra.

### 1.3 El esquema no es un artefacto

Toda la Fase 0/1 del plan de agosto existió porque el esquema de STG **se aplicó a mano y nunca se
versionó**:

| Qué faltaba en PROD | Origen en STG | ¿Versionado? |
|---|---|---|
| `dashboard_conversation_claims`: `control_id`, `quotation_id`, `epoch`, `state` + índices de fencing | migración de fencing del 28 jul, **a mano** | No |
| `whatsapp_sessions`: `human_takeover`, `…_control_id`, `…_epoch`, `metepec_derived` | `deploy-atencion-humana-stg.py`, `deploy-renovacion-metepec-stg.py` | No |
| `dashboard_outbound_dispatch` | n8n (el prefijo `dashboard_` engaña) | No |

Consecuencia: el delta de esquema **se descubrió al abrir la ventana**, y descubrirlo costó más que
aplicarlo. Hoy hay migraciones versionadas en `Agente-n8n/migrations/156/` (14 ficheros) y dos en
`Dashboard/migrations/`, pero **no hay runner, ni registro de aplicadas, ni prohibición de DDL a
mano**. El Agente Conciliación es el único que lo hace bien de punta a punta.

### 1.4 La verificación es artesanal

La regla «ninguna ventana se cierra sin una conversación real» es **correcta y hay que conservarla**
—es la que cazó los dos fallos del 13 ago—, pero hoy esa conversación la hace una persona a mano,
por WhatsApp, y consume el grueso del reloj de la ventana. El Agente QA ya tiene suite
(`run_all.sh`, runners de Postgres/Dashboard/Django/n8n, solo lectura) y **no está cableada como
gate de promoción ni corre en CI**.

### 1.5 La paridad se mide tarde

`detect-drift.py` compara **n8n contra git**, que es lo correcto para cazar ediciones por UI. Nadie
compara **STG contra PROD**: ni esquema, ni grafo, ni variables de entorno, ni versión del motor.
Por eso los hechos del destino aparecen dentro de la ventana, que es cuando cuestan caro. Es la
lección número 1 del acta de agosto: *una promoción se acredita contra el entorno de destino, no
contra su propio artefacto*.

### 1.6 Lo que ya está bien y no hay que tocar

- **Gitflow en todos los repos** (14 ago) — la base sobre la que se apoya todo lo de abajo.
- **`detect-drift.py` con lista blanca de nivel superior** y `main` como copia canónica.
- **Dashboard:** `stg`→`main` + Vercel es merge y segundos, con rollback instantáneo. Su parte de
  código **ya cumple el objetivo**; lo que la frenó en agosto fue el esquema, no el deploy.
- **La disciplina de ventana** (dos criterios, rollback escrito antes, nada se arregla dentro).

---

## 2. El diseño objetivo

Cuatro piezas. La tercera es la cara y es la que compra el 80 % del tiempo.

### Pieza 1 — Paridad continua (barata, inmediata, sin tocar nada vivo)

Un informe diario automático (cron de GH Actions, como ya hace Conciliación) que publica el delta
**STG ↔ PROD** en cuatro ejes:

1. **Esquema:** catálogo contra catálogo — columnas, tipos, defaults, índices, constraints. No
   «existe la tabla»: **la forma** de la tabla. Es literalmente el chequeo que faltó el 12 de agosto.
2. **Workflows n8n:** nodos solo en uno, nodos comunes con parámetros distintos, credenciales por ID.
3. **Variables de entorno:** Vercel prod vs stg contra un manifiesto de las que **deben** diferir.
4. **Versión del motor** de cada instancia n8n.

Con esto el delta deja de ser una expedición de descubrimiento: se conoce todos los días, en frío.
**Es lo primero porque es lo que más ahorra por unidad de esfuerzo, y no requiere autorización de
nadie: es solo lectura.**

### Pieza 2 — El esquema como artefacto

- **Un runner de migraciones común** (uno por repo dueño, misma librería) con tabla `schema_migrations`
  (nombre, checksum, aplicada_en, por_quién) y ejecución **idempotente**: segunda pasada = 0 cambios.
- **Prohibido el DDL a mano**, en STG también — sobre todo en STG, que es de donde salió toda la
  deuda. Un `deploy-*.py` que hace `ALTER TABLE` deja de estar permitido: emite migración.
- **Registro de dueños de tabla** (`docs/architecture/tablas-y-duenos.md`), verificable: que
  `dashboard_outbound_dispatch` fuera de n8n y no del Dashboard costó una ventana entera.
- El comparador de la Pieza 1 pasa a ser el **criterio de éxito**: aplicar migraciones hasta que
  catálogo destino == catálogo esperado, comprobado por catálogo y no por inferencia.

### Pieza 3 — n8n: un artefacto canónico + overlay de entorno

**El cambio estructural.** Hoy: `<workflow>_stg.json` y `<workflow>.json`, dos artefactos.
Objetivo: **un** `workflows/<workflow>.json` canónico + `env/stg.json` y `env/prod.json` con todo lo
que es del entorno:

```
env/prod.json  →  { credenciales: {postgres: "FbodkhT9…", anthropic: "aWrCOYz0…", …},
                    phoneNumberId: "1028815256982638",
                    djangoBaseUrl: "https://seguroautoqualitas.com",
                    gates: false }
env/stg.json   →  { credenciales: {postgres: "5wlLe3gD…", …},
                    phoneNumberId: "<test>",
                    djangoBaseUrl: "https://hyl-wai-stg-…herokuapp.com",
                    gates: true }
```

- **`render.py <workflow> <env>`** → JSON efectivo. Determinista, sin red, testeable offline.
- **`apply.py <workflow> <env> --go`** → GET del vivo, diff semántico, PUT, verificación posterior
  (`webhookId` inmóvil, `active` esperado, cero referencias al otro entorno **incluyendo IDs de
  credencial**), export a git. **Idempotente**: segunda pasada = 0 cambios. Reversión (`PUT` del
  estado previo) escrita **antes** de empezar, automáticamente.
- **Los 27 nodos `C1 Gate —` dejan de ser divergencia y pasan a ser overlay** (`gates: true`). Si son
  andamiaje de pruebas, ese es su sitio; si son producto, van a los dos entornos. Hoy son la mitad de
  la divergencia estructural y no son ninguna de las dos cosas.
- **`Phone Number ID Guard` es el caso inverso:** existe solo en PROD, o sea que STG **no lo está
  probando**. Al canónico, con su valor por overlay.
- Los 73 scripts de un solo uso pasan a histórico. Un cambio se escribe **una vez**, en el canónico,
  y se aplica a N entornos con el mismo aplicador.

**Cómo se llega sin romper nada:** el canónico se construye **partiendo de PROD** (el destino manda,
lección de agosto), y lo de STG se expresa como overlay + delta declarado y revisado pieza a pieza.
Se acredita con la prueba diferencial: `render(prod)` aplicado a PROD debe dar **0 cambios** contra
lo que ya corre. Hasta que ese 0 salga, no se toca nada.

### Pieza 4 — El gate: un comando, tres tramos

`promote --to stg|prod --sha <sha>`, que para al primer rojo:

| Tramo | Qué hace | Reloj |
|---|---|---|
| **Preflight** (solo lectura) | árbol limpio y SHA fijado · migraciones pendientes en destino · diff de env vars · `detect-drift` en destino = 0 · `render` para el destino + guard antifugas (nombres, `$('…')`, URLs, phoneNumberId **e IDs de credencial**) · suite offline verde sobre ese SHA | 3–5 min |
| **Apply** | migraciones idempotentes → merge/deploy Dashboard → `apply.py` n8n con reversión pre-escrita | ~5 min |
| **Post** | suite del Agente QA contra el destino · **conversación real automatizada** · re-export a git · acta generada | ~10 min |

**La conversación real, automatizada.** Es hoy el mayor consumidor de reloj humano y es automatizable
en STG: número de test propio (hasta 5 destinatarios verificados), un runner que envía por la Cloud
API y assertea contra `n8n_chat_histories` y `whatsapp_sessions` usando los hitos por LIKE que ya
están documentados. **Gotcha ya conocido:** una fila insertada por SQL **no abre la ventana de 24 h**
— el mensaje entrante tiene que ser real. En PROD el equivalente es un smoke de una conversación
contra un teléfono nuestro.

---

## 3. Lo que NO se automatiza, y es deliberado

- **La autorización de Alberto para PROD.** Automatizar no es desatender. Lo automático es todo lo
  que hay **entre** el botón y el acta; el botón sigue siendo suyo.
- **Dos criterios, no uno.** Quien despliega no acredita. Con el gate esto es barato: la máquina
  ejecuta, un segundo par de ojos lee el informe post.
- **La validación del Arquitecto sobre `systemMessage`.** Cambiar copy del bot rompe los hitos por
  LIKE. Eso es juicio, no tubería.
- **Nada se arregla dentro de una ventana abierta.** Si el gate sale rojo, se cierra y se reabre otro
  día. Un gate que se puede saltar no es un gate.

---

## 4. Plan de ejecución propuesto

Ordenado por **desbloqueo**, no por tamaño. Cada fase entrega valor sola.

| Fase | Qué | Quién | Coste | Riesgo |
|---|---|---|---|---|
| **A** | Paridad continua STG↔PROD (esquema, workflows, env vars, versión) + informe diario | Arquitecto especifica · n8n y Dashboard implementan su eje | 2–3 días | **Nulo**: solo lectura |
| **B** | Runner de migraciones + registro + prohibición de DDL a mano + dueños de tabla | cada ejecutor en su repo | 3–5 días | Bajo: aditivo |
| **C** | **Canónico + overlay de n8n** (la cara, y la que compra los 20 min) | Agente n8n, con revisión del Arquitecto nodo a nodo | 1–2 semanas | Medio: acaba tocando PROD → ventana propia |
| **D** | Gate `promote` + conversación E2E automatizada en STG | Agente QA + Arquitecto | 3 días | Bajo |

Al terminar D: **«pasemos todo a STG» = un comando y ~20 min.** «A PROD» = el mismo comando con otra
overlay, más tu autorización explícita delante.

**Si solo se hace una cosa, que sea la A.** El coste real de agosto no fue aplicar los cambios: fue
descubrir los hechos del destino con la ventana ya abierta. La paridad continua elimina esa clase
entera de sorpresa por unos días de trabajo y cero riesgo.

---

## 5. Lo que esto NO arregla, y hay que decirlo

- **Mientras el esquema compartido lo escriban dos manos** (nosotros y Django/Juan), la paridad es un
  **chequeo**, no una garantía. El informe diario detecta que Juan añadió una columna; no la coordina.
- **La divergencia funcional legítima seguirá existiendo.** Habrá cosas en STG que no deban viajar
  (hoy: `Issue Policy Guard` sin cablear, `Metepec Liberar`). El overlay resuelve la configuración,
  no la decisión de alcance: eso sigue siendo tuyo y mío. Lo que sí se acaba es tener que
  **re-implementar** lo que sí viaja.
- **«Todo a STG» solo puede significar «todo lo mergeado a `stg`».** El gitflow del 14 ago es lo que
  hace que esa frase tenga un referente exacto; sin él, «todo» no es medible.

---

## 6. Interacción con la gobernanza vigente (aviso obligado)

Las fases **A, B y D son trabajo offline en nuestros repos**: no tocan superficie contractual de
S1–S5 ni producen acciones vivas observables por el monitor de Juan. Riesgo narrativo bajo.

La **fase C sí acaba tocando los workflows de PROD**, y aunque su primer entregable acreditado es
precisamente *«0 cambios contra lo que ya corre»*, el `PUT` existe. Eso pide ventana propia,
autorización registrada y clasificación preventiva en el tracker — el mismo tratamiento que
Multicotización.

Además compite por el mismo ejecutor que **#156** (Agente n8n). Recomendación: A y B durante la
espera de #156; C se planifica pero **no arranca** hasta que #156 esté mergeado a `stg`, para no
canonicalizar un grafo que está a punto de cambiar.

---

## 7. Django/Heroku, fuera por petición

Queda fuera por indicación de Alberto, y se anota lo que eso implica para este objetivo:

- El **esquema compartido** es de todos; las piezas A y B lo cubren como **observación**, no como
  control. Si Juan aplica DDL, lo veremos al día siguiente en vez de dentro de una ventana — que ya
  es la mejora.
- La cadena de promoción de Django (Heroku, `stg`→`main`) no entra en el comando `promote`. El gate
  debe **declarar explícitamente** que no lo cubre, para que «todo a PROD» no se lea como que
  Django viajó.
