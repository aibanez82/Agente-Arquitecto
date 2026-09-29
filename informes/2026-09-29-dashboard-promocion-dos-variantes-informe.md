# Informe — promoción `stg → main` en dos variantes, para que Alberto elija

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas (y Alberto) · **29 sep 2026**
**Responde a:** `handoffs/2026-09-29-promocion-stg-a-main-dos-variantes.md` (`6f103cb`)

**Preparado, no disparado.** Nada a `main`, `stg` sin reescribir, el `#495` intacto en `stg`.

| | Variante A — tal cual | Variante B — sin el `#495` |
|---|---|---|
| Qué se fusiona | `stg` = `f756004` → **PR #14** | `promocion/sin-495` = `d807a66` → **PR #16** |
| Suite sobre el candidato real (`main` + merge) | **687/687**, 0 saltados | **668/668**, 0 saltados |
| `build` | ✔ | ✔ |
| Merge sobre `main` = `6f103cb` | limpio | limpio |
| Ficheros que el merge cambia · de código | 38 · 21 | 24 · 12 |
| `handoffs/` que el merge toca | **0** | **0** |

Los candidatos se construyeron de verdad —`main` actual + el merge, en worktrees aparte con `npm ci` propio y
`HYL_WAI_REPO`— y el gate completo corrió sobre ellos. No es el `stg` reutilizado.

**Se fusiona UNA de las dos.** Son excluyentes: fusionada una, la otra queda vacía o haría lo contrario.

**Mi recomendación: B.** El porqué, en el §4.

---

## 1 · Lo que viaja, commit a commit (25, sin contar merges)

### El `#487` — lo que ya llevaba el PR #14 (17 commits, 25-27 sep)

Verificados el 27 sep con suite verde sobre el candidato y, el único que toca el embudo, **medido contra PROD**.
Hoy he vuelto a pasar la suite sobre los dos candidatos nuevos; **la medición de PROD no la puedo repetir yo**.

| Commit | Qué hace | Cómo se probó | Riesgo |
|---|---|---|---|
| `2ac527c` | Los detectores de hito solo leen filas del agente | Suite + **PROD el 27 sep: 0 de 809 filas de sistema casan** | El único que toca el embudo. Medido a cero, pero hace 2 días |
| `61313dc` | Documenta la deuda y una vía barata medida | — (docs) | Ninguno |
| `8abf095` | Vigila la frontera agente/sistema (`hitosFronteraRota`) | Suite | Número nuevo, no altera cálculos |
| `88afc0c` | Documenta cuándo pasar a vigilancia independiente | — (docs) | Ninguno |
| `845e3b3` | El monitor de n8n deja de ver commits ajenos | Uso real del monitor | No se despliega |
| `a94f330` | Documenta descartar un arnés de pruebas antes de alarmarse | — (docs) | Ninguno |
| `7b88314` | Censo de pólizas y procedencia del VIN, de foto a vigilancia | Suite | Endpoint nuevo que ninguna pantalla consume |
| `7034e77` | El censo publica con qué reconciliarse | Suite | Ídem |
| `f0f5da3` | Separa las dos causas de `rechaza_sin_procedencia` | Suite | Ídem |
| `8aa7eae` | Un WMI compartido por marcas del grupo no acusa a nadie | Suite | Ídem |
| `3956985` | Mide el camino TECLEADO del VIN | Suite | Ídem |
| `1c03611` | Control positivo de intentos de serie nunca comprobados | Suite | Ídem |
| `06cb8c9` | Las filas del arnés de QA no cuentan como imágenes | Uso real del monitor | No se despliega |
| **`d3ba96b`** | **No borrar lo que el cliente escribe junto a la foto** | Suite | **Corrige una conducta viva en PROD**: hoy PROD borra palabras del cliente. Es lo único con reloj del `#487` |
| `26b666f` | `[SERIE_SOSPECHOSA]` deja de parecer escrito por el cliente | Suite | Cambia la pantalla; **no hay ningún caso en STG para verlo** |
| `038c499` | Mide cuántas imágenes de clientes hay en PROD | Suite | Endpoint de medición |
| `e0cf751` | Mide si un carril de sistema dispara algún hito | Suite | Endpoint de medición |

### El `#493` de hoy y el gate del `build` (4 commits)

| Commit | Qué hace | Cómo se probó | Riesgo |
|---|---|---|---|
| `d23f2e5` | La bandeja pinta la antigüedad de la toma y ordena por ella | Suite + `build` | Sin captura |
| `4c36d89` | El eje pasa a ser la **espera del cliente** (`cliente_espera_desde`) | Suite + `build` | Sin captura. Límite escrito: solo mira el último mensaje |
| **`5f4f137`** | **Una conversación tomada se ve siempre**, aunque tenga póliza; filtro «Tomadas»; pastilla «Póliza emitida» | Suite + `build`; **alcance medido por ti en PROD: exactamente 2 leads más** (2208 y 2125) | **Cambia qué filas ve todo el mundo.** Sin captura |
| `89523bd` | `npm test` incluye el `build` | El propio gate, con fail-first reintroduciendo el defecto | Ninguno en PROD (no se despliega) |

### El `#495` (3 commits) y una herramienta (1)

| Commit | Qué hace | Cómo se probó | Riesgo con el reloj APAGADO |
|---|---|---|---|
| `108da9c` | Saca el protocolo de control de `claim.js` a `lib/s1/protocoloDeControl.js`, sin cambiar lógica | Suite + `build`; **ejercido en vivo en STG hoy** (la toma 199 y su liberación pasaron por él) | Bajo: no cambia conducta |
| **`8925fb1`** | Liberación por inactividad **y** apuntar el intento del operador ANTES de enviar | Suite; **Postgres efímero 19/19** con la carrera; **quinta y séptima fila en vivo en STG** | **Ver §3: una parte se enciende aunque el reloj vaya apagado** |
| `ea8ce00` | El reloj ya no se atasca con tomas huérfanas | Suite con fail-first | Ninguno sin reloj |
| `3f02e7e` | `scripts/esperar-deploy.sh` | Probado a mano en los dos sentidos | No se despliega. **Viaja en las dos variantes** |

## 2 · Variante A — el PR #14 tal cual

El PR #14 tiene como cabecera la propia rama `stg`, así que ya lleva los 49 commits de hoy; he actualizado su
descripción. **Con el `#495` dentro y el reloj apagado**: en PROD no existe `SISTEMA_LIBERACION_SECRET`, el
endpoint responde `503 liberacion_automatica_off` y no libera nada. Pero no todo el `#495` queda dormido (§3).

## 3 · Lo que el `#495` enciende aunque el reloj vaya apagado — y lo que no se ha probado nunca

Tres cambios entran en vigor con la variante A **sin secreto ni reloj**:

1. **`n8n-proactive-message` («Retomar»), carril legacy** — abre la fila de auditoría **antes** del envío, bajo
   un lock de sesión, y **si no puede abrirla, no envía** (503). Antes enviaba siempre y auditaba después.
   **⚠️ Este carril solo corre en PROD.** En STG, `getS1DashboardMode` nunca devuelve `null`, así que STG va
   siempre por el carril S1: **el carril de PROD no se puede ejercitar en STG por construcción.** Con la
   variante A, ese código se estrenaría en PROD sin haber corrido nunca en vivo. Y es un camino con tráfico.
2. **`operator-send`** — lo mismo para el envío humano. Solo importa si `N8N_OPERATOR_SEND_ENABLED` está
   encendido en PROD; **ese valor no lo puedo leer** (la variable es `sensitive`). Si está apagado, es inerte.
3. **El visor** atribuye al operador solo las filas con `webhook_ok IS TRUE`. Las filas históricas se
   escribieron todas con `true`, así que hoy no cambia nada visible.

**Y la prueba en vivo de esos escritores es cero:** STG tiene **3 filas de auditoría en toda su historia, la
última del 10 de agosto**, y ninguna desde que se desplegó el `#495`. La lógica está probada con stubs y el SQL
contra Postgres real; **el ciclo completo abrir-enviar-cerrar no ha corrido nunca contra una base viva**.

Todo eso existe para proteger al operador **de un reloj que está en pausa**.

## 4 · Variante B — sin el `#495`, y la respuesta sobre el refactor

**`promocion/sin-495`**, sacada de `stg` con tres reverts, del más nuevo al más viejo: `ea8ce00`, `8925fb1`,
`108da9c`. **Los tres entraron limpios.** `stg` no se ha tocado.

**¿Se puede revertir el refactor sin arrastrar el `#493` o el botón? Sí, y está medido, no razonado:**

- **Después del refactor, el único commit que toca sus ficheros es el propio `#495`**, y **el `#493` no ha
  tocado nunca `claim.js`**. No hay entrelazado.
- **B es exactamente `stg` tal como estaba justo antes del `#495` (`9e03d5a`) más `scripts/esperar-deploy.sh`**:
  `git diff 9e03d5a promocion/sin-495` da ese único fichero.
- **Los nueve ficheros que solo tocó el `#495` quedan en B idénticos byte a byte a `main`**, es decir, a lo que
  corre hoy en PROD: `claim.js`, `operator-send.js`, `n8n-proactive-message.js`, `claimDecision.js`,
  `reasonCopy.js`, `middleware.js` y sus tres tests. Los dos ficheros compartidos (`conversation.js`,
  `ConversationWorkspace.js`) solo difieren de `main` por commits del `#487` y del `#493`.

**Así que revertir el refactor no es más arriesgado que dejarlo apagado: es menos.** Deja en `main` el mismo
`claim.js` que PROD usa desde hace semanas.

### ⚠️ Lo que B cuesta, y hay que saberlo antes de elegirla

**Los reverts se quedan en la historia de `main`.** Si el `#495` se reactiva algún día, **fusionar `stg` no lo
traerá de vuelta**: sus commits ya serán antepasados de `main`, y los reverts ganan en silencio. Reactivarlo
exigirá **revertir los reverts**, a propósito.

**Y mientras tanto `stg` y `main` difieren en esos nueve ficheros.** STG seguirá ejecutando el código del `#495`
—incluido el intento antes de enviar— que PROD no tendrá. Una prueba en STG sobre envío humano o Retomar no
representará a PROD hasta que se decida el `#495`, en un sentido u otro. Lo declaro para que no se descubra
dentro de un mes.

### Por qué recomiendo B pese a eso

1. El `#495` está en pausa. Lo que se enciende sin reloj existe **para proteger de ese reloj**.
2. En Retomar se estrenaría en PROD **sin haber corrido nunca en vivo**, y no hay forma de probarlo antes en STG.
3. En B, los ficheros de toma y envío son **los que PROD ya ejecuta**.

**El argumento a favor de A, que es real:** A mantiene `stg` igual a `main`, sin la trampa de los reverts ni la
divergencia; y el cambio de auditoría es correcto por sí mismo y su SQL está probado contra Postgres. **Si
Alberto prefiere que STG y PROD no difieran en nada, A es defendible**, pero entonces conviene saber antes si el
envío humano está encendido en PROD y aceptar que el carril de Retomar cambia sin prueba en vivo.

## 5 · Lo que Alberto tiene que ver con sus ojos antes de fusionar

En el **Preview de STG**, con su login:
`https://dashboard-seguroautoqualitas-git-stg-albers-projects-52295059.vercel.app` → pestaña **Chats**.

Vale para las dos variantes: la bandeja del `#493` va en ambas.

1. **La barra de filtros** tiene **«Tomadas»** entre «Contestan» y «Mis conversaciones».
2. **Bajo el buscador**, a la derecha del recuento de pendientes: **«Recientes | Quien más espera»**.
3. **Tomar una conversación de prueba** —por ejemplo el lead **1190** (`waq_2543`, teléfono de pruebas; la uso
   hoy para la quinta fila y no la usa nadie)—. En la lista, su insignia debe decir
   **«👤 Tú · tomada hace menos de 1 min»**, en neutro. Con «Tomadas» activo, debe aparecer. Después,
   **«Liberar conversación»** y volver a verla como «Libre».
   ⚠️ **En la variante A, si la deja tomada más de 5 minutos, NO se libera sola**: el reloj de STG está desactivado.
4. **Lo que NO se puede ver en STG** con los datos que hay: el ámbar (4 h) y el rojo (24 h) de la espera del
   cliente, y la pastilla **«Póliza emitida»**. Exigen una toma con el cliente esperando horas, o con póliza, y en
   STG no hay ninguna. **El primer sitio donde se verán es PROD**, justo después del merge.

**Para el `#487`, en el visor de conversación** (misma pestaña, abriendo la conversación):

5. **Lead 1387** (`waq_2740`) o **lead 1359** (`waq_2683`): hay un `[FOTO_VIN]` con texto del cliente detrás. **El
   texto del cliente tiene que verse**, no solo la burbuja de la foto. Es la corrección de conducta viva en PROD.
6. **`[SERIE_SOSPECHOSA]`**: **no hay ningún caso en STG**. No se puede ver antes del merge.

**Y en PROD, justo después de fusionar**, la comprobación que cierra el `#493`: filtro **«Tomadas»** → tienen que
salir **las 9 tomas activas** que mediste (o las que queden), y entre ellas los leads **2208 y 2125** con
**«Póliza emitida»**: hoy están ocultos.

## 6 · Lo que no he hecho

No he fusionado nada en `main`. No he tocado `stg` ni el `#495`. La rama B es nueva y aparte. El reloj de STG
sigue desactivado, sin borrar, como lo dejaste. Los worktrees de los candidatos los borro al publicar esto;
las ramas se quedan.

— Agente Dashboard
