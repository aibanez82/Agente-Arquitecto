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

---

# Anexo I — Cómo se implementa la Fase A (especificación)

Escrito el 14 ago a petición de Alberto. Esto es **el requerimiento**, no el código: lo construye un
ejecutor, lo corre un cron, y el Arquitecto lo consume.

## I.1 Qué es

Una **sonda de paridad** de solo lectura que responde una pregunta todos los días:
*«¿en qué se diferencian STG y PROD hoy, descontando lo que debe diferir?»*

No aplica nada, no arregla nada, no toca nada vivo. Compara y publica.

## I.2 Dónde vive — decisión pendiente de Alberto

**Recomendación: una única copia canónica en `Agente-Arquitecto`, rama `main`.** Razones:

- Es **transversal por definición** (cruza n8n, Dashboard y BD); repartirla por eje entre tres repos
  reproduce el fallo ya conocido de `detect-drift.py` viviendo en 26 ramas con cuatro versiones.
- Es **solo lectura**: publicar un informe es observación, que es exactamente mi rol, no ejecución.
- El consumidor del informe soy yo.

**Lo que no cambia:** la escribe un **ejecutor** (Nivel 3) por instrucción de Alberto, y la corre un
cron de GitHub Actions. El Arquitecto especifica y consume; no la mantiene a mano.

Alternativa si Alberto prefiere no meter tooling en este repo: `Agente_QATest_Qualitas`, que ya tiene
runners, agregador de reporte y disciplina de solo lectura. Es la segunda mejor opción y no es mala.

## I.3 Los cuatro ejes

### A1 · Esquema — catálogo contra catálogo

Por cada tabla del conjunto compartido: columnas (nombre, tipo, nullable, default), índices,
constraints. **No «existe la tabla»: la forma de la tabla** — es la distinción exacta que costó la
Fase 0 de agosto.

- Leer de `pg_catalog`, **no de `information_schema`**: este último filtra por privilegio y devuelve
  «cero filas» tanto si no hay como si no ves. Ya casi publicamos una conclusión falsa por eso.
- Salida por tabla: columnas solo en un lado · tipos que no casan · índices y constraints ausentes.

### A2 · Workflows n8n — grafo contra grafo

`GET` a las dos instancias, normalizar con la **lista blanca de nivel superior** ya establecida
(`name`, `active`, `nodes`, `connections`, `settings`) y comparar por nombre de nodo:

- nodos solo en STG · nodos solo en PROD
- nodos comunes con **parámetros** distintos
- nodos comunes con **IDs de credencial** distintos ← la tercera vía de fuga que se coló en agosto

Es el script que se corrió a mano el 14 ago y tardó treinta segundos. Convertirlo en cron es trivial.

### A3 · Variables de entorno — Vercel

Nombres y presencia por entorno, **nunca valores**. Contraste contra un manifiesto de las que
**deben** diferir. Recordatorio que ya nos mordió: en Vercel cambiar una variable **no afecta a los
despliegues existentes**, solo a los nuevos — así que el informe declara la variable, no el efecto.

**Heroku/Django queda fuera por petición:** el informe debe decirlo explícitamente, para que
«paridad verde» no se lea como que las config vars de Django están cubiertas.

### A4 · Versiones

Motor de n8n por instancia, `next` del Dashboard, Node. Cinco líneas, y fue un punto ciego real:
las dos instancias de n8n corrieron **3 599 commits** de diferencia sin que nadie lo mirara.

**Laguna conocida:** la API pública de n8n **no expone la versión**. O se lee del panel, o se toma de
`n8nDetails.n8nVersion` dentro del payload de error de una ejecución. Si no se resuelve, el informe
declara **dónde se buscó**, no «no observable».

## I.4 Cómo se publica — y por qué así

- Un fichero por corrida en `docs/monitores/paridad/AAAA-MM-DD.md`, commiteado. Histórico gratis.
- **Alerta solo cuando cambia el delta**, no cuando hay delta. Un canal con falsos positivos
  permanentes acaba ignorándose — está en el catálogo de trampas y lo hemos vivido.
- **`esperado.yaml`**: la diferencia legítima (IDs de credencial, `phoneNumberId`, URLs, los gates de
  STG) se declara y se descuenta. Lo que el informe enseña es **lo no esperado**. Cuando algo entra
  ahí, entra con fecha y motivo — un allowlist sin justificación es un tapón, no una decisión.

## I.5 Reconocimiento de entorno — aplicando el §1 del manual a esto mismo

El manual dice responder esta tabla **en vivo antes** de escribir el plan. Aplicado a la propia
sonda, esto es lo que hay que verificar **antes** de escribir una línea:

| Pregunta | Por qué importa aquí |
|---|---|
| ¿Existe rol de **solo lectura** en la BD de STG? | En S1 **no existía**; se resolvió con una opción de sesión y deuda declarada. A1 lo necesita en los dos lados |
| ¿Qué `sslmode` acepta cada BD? | STG solo aceptó `no-verify`. Un DSN sin esto no conecta y `require` tampoco |
| ¿Hay API key vigente de **las dos** instancias n8n? | La de PROD se rotó el 29 jul. Sin las dos, A2 no existe |
| ¿Token de Vercel con permiso de **listar** env vars sin leer valores? | Si no lo hay, A3 se reduce a nombres desde el CLI |
| ¿Desde dónde corre el cron alcanza las dos BD? | GH Actions sale por IP no fija; si hay filtrado, cambia el alojamiento |

Si alguna sale «no», entra en el alcance de A como trabajo previo — no como sorpresa a mitad.

## I.6 Criterio de aceptación — conductual, no «salió verde»

1. **Canarios en las dos direcciones.** Se inyecta una diferencia conocida (una columna en una tabla
   de pruebas de STG, un parámetro de nodo) y la sonda **debe** reportarla; se retira y debe volver a
   cero. Un detector que nadie ha visto detectar no es un detector.
2. **Determinista:** dos corridas seguidas sin cambios → salida idéntica.
3. **Prueba contra el caso real:** la sonda, corrida contra el estado del 12 de agosto, tendría que
   haber cantado las cuatro columnas ausentes de `dashboard_conversation_claims`. Ese es el examen.
4. **Sin escrituras:** acreditado por el rol, no por lectura del código — el rol de la sonda no tiene
   permiso de escritura, y se comprueba intentando escribir y viendo el rechazo del servidor.

## I.7 Coste y secuencia

2–3 días de un ejecutor. Riesgo nulo (solo lectura, sin acción viva, sin superficie contractual).
**No compite con #156** salvo por la agenda del ejecutor; si el Agente n8n está ocupado, el Agente QA
puede hacerla entera.

---

# Anexo II — Qué metodología es esto

**Respuesta honesta primero:** el plan **no se dedujo de un estándar**, se dedujo de nuestros propios
fallos medidos. Pero **coincide pieza por pieza con prácticas establecidas**, y decirlo no es adorno:
cambia dos decisiones concretas (§II.3).

## II.1 El mapa

| Pieza del plan | Práctica establecida |
|---|---|
| Artefacto único + overlay por entorno (Pieza 3) | **«Build once, deploy many»** — principio central de *Continuous Delivery* (Humble & Farley). El mismo artefacto atraviesa entornos; la configuración se inyecta desde fuera |
| `env/stg.json` · `env/prod.json` | **Base + overlays** (Kustomize) / *values* (Helm). Configuración como datos, no como código duplicado |
| Config fuera del artefacto · paridad entre entornos | **12-Factor App**, factores **III** (config en el entorno) y **X** (paridad dev/prod). El eje A2/A3 mide literalmente el cumplimiento del factor X |
| Sonda de paridad (Fase A) | **GitOps**, principio de *reconciliación continua* (OpenGitOps). Es el `OutOfSync` de ArgoCD: estado deseado contra estado real, publicado de forma continua |
| `apply.py` idempotente con reversión pre-escrita | **Reconciler** declarativo · *desired state* · rollback como artefacto, no como improvisación |
| Migraciones versionadas + registro con checksum (Pieza 2) | **Evolutionary Database Design** (Ambler & Sadalage); herramientas de referencia: **Flyway**, **Liquibase**, **Atlas** |
| Fase 0/1 de agosto (DDL aditivo antes del código) | **Expand & contract** (*parallel change*): ampliar esquema → migrar código → contraer. Lo hicimos bien, sin saber que tenía nombre |
| Gate `promote` con preflight (Pieza 4) | **Deployment pipeline** con *quality gates*; el preflight es una **fitness function** (*Building Evolutionary Architectures*) |
| Ventana + GO + acta | **Change record** de corte ITIL. Se conserva, pero **generado** por el pipeline en vez de redactado |
| Cómo sabremos si funcionó | **DORA / Accelerate**: *lead time for changes*, *deployment frequency*, *change failure rate*, *MTTR* |

## II.2 Una decisión deliberada que se aparta del estándar

GitOps canónico **reconcilia solo**: detecta desviación y la corrige. **Nosotros solo detectamos.**

Es a propósito. Auto-corregir un bot de WhatsApp vivo, con dueño humano y con un colaborador externo
escribiendo en la misma base, convierte cada desviación en una acción no autorizada. La mitad
*detectar* es la que compra el tiempo; la mitad *aplicar sola* es la que compra los incidentes. Se
adopta la primera y se rechaza la segunda, **con la razón escrita** para que dentro de seis meses no
parezca un olvido.

## II.3 Qué cambia por reconocer el estándar — y esto es lo útil

1. **La Pieza 2 no se escribe: se instala.** Un runner de migraciones con registro, checksum e
   idempotencia es **Flyway/Liquibase/Atlas** desde 2010. Escribir el nuestro es reinventar mal.
   Recomendación: **Atlas** o **Flyway** sobre el Postgres compartido, con un esquema de registro por
   dueño. *(Salvedad honesta: no he verificado en vivo la compatibilidad con la configuración exacta
   de nuestro Postgres — eso entra en el reconocimiento de la Fase B, no se da por hecho aquí.)*
2. **La Pieza 3 sí es a medida, y hay que saber por qué.** No existe operador GitOps para n8n: el
   estándar aporta **la forma** (base + overlay + reconciler), no la implementación. Igual con «un
   Postgres compartido por cuatro escritores sin dueño único», que ningún manual contempla porque
   ninguno lo recomienda.
3. **Vocabulario común.** Llamar a las cosas *desired state*, *drift*, *overlay*, *expand/contract* y
   *fitness function* hace que los ejecutores encuentren precedentes en vez de inventarlos, y que la
   próxima persona que lea esto sepa buscar.

## II.4 La medida, para que «duele menos» no sea una impresión

Antes de empezar se toma la línea base con las cuatro métricas DORA, medidas sobre el viaje de
agosto, y se vuelve a medir después. Sin eso, la mejora es una sensación.

Objetivo declarado: **lead time de días a minutos** para el tramo mecánico, dejando intactos —porque
son juicio y no tubería— la autorización de Alberto, los dos criterios y la conversación real.

---

# Anexo III — Cuánto habría ahorrado la Fase A, medido contra los dos viajes reales

Pregunta de Alberto (14 ago): *«si implemento A, el plan de pasar a PRO cuánto me hubiera demorado vs
cuánto me demoré. ¿Y con descuentos a STG?»*

**Método:** los tiempos **medidos** salen de los commits de `Agente-Arquitecto` y `Agente-n8n`; las
horas **ahorradas** son estimación mía, marcada como tal. Se separan las dos cosas a propósito: la
tentación aquí es publicar el número que me favorece.

## III.1 Viaje STG → PROD (10–13 ago)

**Medido:**

| | |
|---|---|
| Plan inicial (`…-cross.md`) | **10/08 17:38** |
| Plan v2, tras descubrir el hueco de esquema | **12/08 16:32** |
| Fase 0 (migración escrita) → Fase 1 (DDL) → Dashboard en PROD | **12/08 16:49 → 17:59** |
| Acta de cierre | **13/08 18:47** |
| **Calendario total** | **3 días 1 h** |
| **Trabajo efectivo de promoción** | **~15 h**, repartidas en dos jornadas (el 11 se fue entero en #156) |

**El dato que más dice:** una vez conocido el delta, **escribir la migración, aplicarla en PROD y
promover el Dashboard costó 1 h 27 min**. Descubrir ese delta costó **dos días de calendario y un
plan entero tirado**. La proporción es la tesis de todo este documento.

**Lo que A habría quitado (estimado: 4–6 h de trabajo y ~1 de los 3 días de calendario):**

- El reconocimiento manual de PROD del 12 ago. Ya estaría en el informe del día.
- **El plan v2 no existiría:** el plan del 10 habría nacido con la Fase 0/1 dentro, en vez de
  publicarse afirmando que el esquema estaba bien y reescribirse dos días después.
- **`dashboard_outbound_dispatch` entera ausente**, descubierta a las **18:19 del 12** — con el viaje
  ya en marcha. Obligó a una tercera ventana y a corregir la atribución de 3 de 5 tablas.

**Lo que A NO habría quitado:** las tres ventanas de n8n, las migraciones, la fuga de credencial STG
a PROD (eso lo para el preflight de la Pieza D, no A), los defectos `#76`/`#77` —que los despertó el
paso de Django a `dual`, no la migración— y el error de dar `shadow` por bueno de memoria, porque
**ese valor vive en Heroku, que está fuera de alcance por tu decisión**.

**Veredicto: 3 días → ~2 días.** Una reducción de en torno al 30 %, toda ella en *no empezar mal*.

## III.2 Descuentos #156 → STG (13–14 ago, aún abierto)

**Medido:**

| | |
|---|---|
| Plan → GO → arranque | **13/08 18:56 → 19:09 → 19:12** |
| Ventana DDL en STG, 12 de 12 | **13/08 21:12** |
| «Descuentos **encendido** en STG» | **14/08 12:25** |
| **Elapsed hasta encendido** | **~17 h 30 min** |
| Estado a 14/08 17:13 | **E2E aún no verde** — bloqueado por `active` vs `open`, dos piezas de Django |

**Lo que A habría quitado (estimado: 2–3 h de 17,5):**

- Las variables de Vercel sin escopar a `stg`, resueltas como precondición a las 20:44 — **es
  literalmente el eje A3**.
- El import bloqueado por divergencia entre el candidato y lo vivo en STG (**21:50 → 22:31, 40 min**
  recomponiendo candidatos): el eje A2 lo enseña a diario.
- Parte del `503` del claim del Dashboard a las 19:48.

**Lo que A NO habría quitado, y es la mayor parte:**

- **«Juan promovió la rama pero no el entorno»** (19:45) — `hyl-wai-stg` corriendo el Django viejo.
  Es un hecho del destino… **en Heroku**. Segundo caso del día en que la exclusión cuesta.
- El dictamen de Juan (23:51), el fence 9/9 y sus decisiones (14/08 09:24–10:36): son **juicio**.
- **El incidente de la capa C1 dejando el bot de STG sin procesar (14/08 13:23).** A lo habría
  *mostrado* como divergencia todos los días, pero no lo evita: eso lo arregla la **Pieza C**, que es
  precisamente la que convierte esos 27 nodos en overlay.
- El bloqueo vivo de `active` vs `open`: Django.

**Veredicto: ~17,5 h → ~15 h.** Menos del 20 %, porque **la restricción activa de este viaje no fue
nuestro descubrimiento: fue Django y las decisiones.**

## III.3 La conclusión, que no es cómoda

**A no es la pieza que trae los 20 minutos.** A hace que el plan **nazca correcto**; C y D son las que
hacen que la ejecución sea **rápida**. Se ve en el número: una vez conocido el delta, el trabajo real
del 12 de agosto fueron 87 minutos.

Sigue mereciendo ser lo primero —2–3 días, riesgo nulo, y en los dos viajes habría evitado empezar
con el plan equivocado— pero **venderla como la que cumple el encargo sería falso**.

Y el hallazgo incómodo de los dos viajes: **la exclusión de Heroku aparece dos veces como causa
directa de tiempo perdido** (el modo `shadow`/`dual` dado por bueno de memoria; el entorno de
`hyl-wai-stg` sin promover). No pido revisar la decisión: pido que quede escrito que ese tramo seguirá
costando, porque no lo cubre ninguna de las cuatro piezas.
