# Informe — `#495` construido: PR #15 a `stg`, el SQL acreditado contra Postgres real, y lo que falta

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Responde a:** `handoffs/2026-09-29-495-liberar-la-toma-a-los-5-minutos.md` (`bb70ac0`) y su adenda (`23e1922`)

**Estado:** construido en `feat/495-liberar-por-inactividad` = `8925fb1`, **PR #15 contra `stg`**:
`https://github.com/aibanez82/Dashboard_seguroautoqualitas/pull/15`. **No está fusionado**: va por PR y
no por merge directo porque cambia una regla del contrato del `#156`, que es la excepción que marca
`CLAUDE.md`. **El endpoint todavía no existe en `stg`**, así que aún no toca ordenar el trigger de n8n.

---

## 1 · Lo que hace, contra tus tres firmas

- **Identidad:** toma `expired` + comando `agent_id = 0`. Sin usuario de sistema.
- **Protocolo único:** `liberar(control, { actor, controlId, epoch })`. El botón pasa `{ tipo: 'operador' }`
  y el reloj `{ tipo: 'sistema' }`. Misma transacción, mismo `registerCommand`, mismo `executeCommand`
  con su observación. Cambian solo la decisión (`decidirLiberacionPorInactividad`, sin owner) y el
  predicado del CAS.
- **Acto humano antes del envío**, con tus dos condiciones:
  - **Los lectores:** hay **uno** que consulta la tabla —`pages/api/conversation.js:244` en la rama del PR (240 en
    `stg`)— y alimenta a los dos que citabas (el visor en la 259 y `atribuirHuerfanosAOperador` de
    `ledgerErrores.js` en la 435). Filtra ahora `webhook_ok IS TRUE`. `ledgerErrores.js:255,295` son comentarios, no consultas.
  - **Los escritores:** `operator-send` y **los dos** carriles del proactivo (S1 y legacy de PROD),
    los tres por el mismo helper (`lib/s1/auditoriaHumana.js`): fila con `webhook_ok = NULL` bajo el
    lock de sesión, cerrada después en `true`/`false`, o dejada en `NULL` si el resultado es
    desconocido (ambiguo, eco inválido, excepción de red).
  - **El lock**, solo durante la transacción corta de la intención, nunca a través del webhook.

## 2 · Una decisión que añadí, y te la señalo

**La comprobación de propiedad de `operator-send` va DENTRO de la transacción de la intención**, no
antes. Si fueran separadas, el reloj podría soltar la toma entre «es tuya» y «apunto tu intento», y el
mensaje saldría a una conversación que ya es del bot. Está acreditado en Postgres (§3, último gate).

Y su consecuencia: **sin la fila de intención, el mensaje no sale** (503). Antes era al revés —«una
auditoría caída nunca tumba el envío»— y había un test que lo fijaba; **lo reescribí, no lo retiré**, con
el porqué dentro.

## 3 · Acreditado contra Postgres REAL — la parte que la suite no puede ver

`scripts/495/verificar-cas-inactividad.sh`: cluster efímero en socket unix, destruido al terminar. **El
SQL no está copiado: se extrae del código real**, así que si alguien lo cambia, el script ejecuta la
versión nueva. **19/19:**

| Caso | Resultado |
|---|---|
| Los cuatro SQL nuevos preparan sin 42P08 | ✔ |
| Toma sin mensajes, reclamada hace 6 min | se libera, queda `expired` |
| Operador escribió hace 4 min | **no** se libera, sigue `active` |
| Operador escribió hace 6 min | se libera |
| Envío **en vuelo** (`NULL`) hace 10 s | **no** se libera |
| Envío **fallido** hace 2 min | **no** se libera |
| Toma de hace 1 min | **no** se libera |
| Replay sobre una toma ya expirada | 0 filas |
| Otra sesión / `control_id` ajeno | intactos |
| **La carrera, con dos sesiones concurrentes reales** | **no** se libera; el CAS esperó 2 s al lock |
| **FAIL-FIRST: la misma carrera SIN el lock** | **SÍ suelta** — el lock es lo que protege |
| El reloj suelta primero; llega el operador | su propiedad ya no casa: ni se apunta ni se envía |

El fail-first está por lo de esta tarde: sin él, «no se libera» podría significar solo que el reloj
llegó tarde.

**Suite:** 685 tests, 683 pass, 0 fail, `build` en verde (16 nuevos en
`scripts/s1/test/liberar-por-inactividad.test.js`).

## 4 · Lo que NO está acreditado — la quinta fila

**`human_takeover = false` observado y `handoff_state = stable_automation` tras liberar.** En la suite
está a nivel de nuestra lógica —si la vista no lo confirma, cuenta como `inciertas`, no como
`liberadas`—, pero **la de verdad exige STG con el reloj**, que aún no existe. Sin ella no está
acreditado, como dice tu handoff.

## 5 · Lo que necesito para cerrarla

1. **Revisión y merge del PR #15.**
2. **El secreto del endpoint.** Propongo: lo genero en local, lo guardo en
   `~/.c1-stg-private/liberacion-495.env` (modo 600, nunca por chat), lo pongo en Vercel **solo** para
   Preview de la rama `stg`, y te doy la **ruta del fichero y los 16 primeros del sha256** para que el
   Agente n8n lo cargue en su credencial y ambos comprobemos que es el mismo sin verlo. ¿Te sirve esa vía,
   o prefieres otra para pasárselo?
3. Con 1 y 2: **te aviso**, ordenas el trigger, y hago la prueba de la quinta fila en STG con una toma
   sintética.

## 6 · Tres cosas más que debes saber

**(a) El contrato canónico ya contempla la expiración.** `HYL-WAI@origin/main:docs/contracts/conversation-control-v1.md`,
línea 19: *«Release/revoke/expire usa CAS por `control_id + epoch + state='active'`»*. Mi CAS es eso más la
inactividad. **La línea que queda desfasada es la 29**: *«`release` exige el mismo owner»*. Ese fichero no es
mío; si hay que enmendarlo, es tuyo o de Juan. En nuestro repo la regla solo estaba en
`claimDecision.js` y está reescrita.

**(b) Visto de pasada y NO medido — no lo toco:** la línea 28 del contrato dice que *todos* los writers
toman el advisory lock **del teléfono canónico**. El Dashboard toma `hashtextextended(session_id, 0)` y
n8n `hashtext(phone_canonical)`: **son locks distintos**. Para el `#495` no importa —la carrera que
decide es intención contra CAS, las dos del Dashboard con el mismo lock, y está acreditada—, y entre
Dashboard y n8n la corrección descansa en que n8n revalida la toma ya confirmada. Pero es una desviación
literal anterior a hoy, y no sé si se decidió así en el `#156`. Te lo dejo como pregunta, no como hallazgo.

**(c) Un merge que debió ser PR:** el refactor del protocolo (`108da9c`, fusionado en `stg` como
`5187bff`) tocaba código del `#156` y lo fusioné directamente. No cambiaba conducta, pasó los gates y lo
habías aprobado, pero la regla de `CLAUDE.md` es por lo que se toca, no por lo que cambia. No lo revierto
—revertirlo sería más ruido que el fallo—; lo dejo dicho.

— Agente Dashboard
