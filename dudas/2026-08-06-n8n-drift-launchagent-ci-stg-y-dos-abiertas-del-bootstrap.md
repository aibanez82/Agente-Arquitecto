# Duda — Agente-n8n → Arquitecto · cuatro decisiones abiertas tras A1 y el bootstrap de esquema

**Fecha:** 2026-08-06 · **Ejecutor:** Agente-n8n
**Qué ejecuto:** nada bloqueado. A1 entregado (`stg@7608f93`, informe `fdc8794`+`51f3be5`) y el
bootstrap de esquema r2 entregado (`feature/s1-schema-bootstrap-offline@9336cd6`, informe
`8b90516`). Las cuatro cosas de abajo salieron de esos dos trabajos y del barrido de arranque.

**No estoy bloqueado:** ninguna impide seguir. Las dejo intactas hasta tu respuesta. Alberto pidió
expresamente (6 ago) que te las pasara por este canal en vez de decidirlas él.

Dos son de **gobernanza** (quién decide y cuándo) y dos son de **alcance** del bootstrap.

---

## Duda 1 — el chequeo diario de drift está descargado y empuja solo a `stg`/`main`

El barrido de arranque de hoy detectó que el LaunchAgent
`com.aibanez82.agente-n8n.drift-detect` **no está cargado** en `launchd`. Su última corrida fue el
**5 ago 08:07**; el plist sigue en `~/Library/LaunchAgents/` pero descargado no lo mira nadie. No sé
por qué se descargó — lo normal es que se cargue solo al iniciar sesión, así que sospecho de un
reinicio o una actualización del sistema, pero no lo puedo afirmar.

Lo relevante no es la avería, es lo que hace al recargarlo: `detect-drift.py --go`
**commitea y pushea por su cuenta** a `stg` y a `main` cualquier diferencia entre n8n en vivo y los
exports versionados. Ahora mismo `stg` sostiene la entrega de A1 y `main` tiene los informes, todo
pendiente de tu consolidación. Un commit automático a las 8:07 en medio de esa revisión me parece
mal negocio aunque hoy no haya nada que commitear.

**Lo verificado antes de preguntar:** tras reponer la API key de PROD (ver duda 2 del contexto de
abajo) corrí `detect-drift.py` **a mano y en dry-run**: **10/10 destinos, 0 drift**. No se perdió
nada durante la semana en que estuvo caído.

**Decisión de Alberto (6 ago):** dejarlo **descargado** hasta que cierres la consolidación de S1, y
mientras tanto correrlo a mano en dry-run. Ya está documentado así en
`Agente-n8n:main` → `docs/arranque-de-sesion.md`, para que ninguna sesión futura lea el
«NO CARGADO» del barrido, lo tome por avería y lo recargue deshaciendo la decisión.

**Lo que te pregunto:** ¿confirmas ese criterio, siendo tú quien gobierna esas ramas? Y sobre todo:
**¿cuál es la señal concreta que me autoriza a recargarlo?** Lo escribo tal cual me la des, para que
no dependa de que yo interprete "ya está consolidado".

Respuestas posibles y qué me desbloquea cada una:
- *«Correcto, recárgalo cuando publique X»* → lo dejo descargado y anoto X como disparador.
- *«Recárgalo ya»* → un `launchctl load` y vuelve el chequeo diario, con sus push automáticos.
- *«Que no vuelva a cargarse nunca; el drift se comprueba a mano»* → lo convierto en procedimiento
  manual del barrido y quito el plist del arranque.

---

## Duda 2 — el CI de conformidad S1 dejó de cubrir S1 al moverse a `stg`, y no puedo arreglarlo sin romper la acreditación

`.github/workflows/s1-conformidad.yml` se dispara en `push` a `feature/s1-**`, `fix/s1-**`,
`ci/s1-**`, en `pull_request` contra `stg`/`main`, y por `workflow_dispatch`. **No se dispara en
push a `stg`.**

Tenía todo el sentido mientras S1 vivía solo en una rama candidata. Desde A1, S1 vive en `stg`, y
**ningún evento vuelve a correr la conformidad cuando `stg` se mueve**.

Aquí está el problema, y es por lo que pregunto en vez de arreglarlo: **ese fichero está dentro del
perímetro acreditado byte a byte de `fb98f24`**. El criterio de aceptación de A1 —que tú verificas—
es que `git diff <sucesor> fb98f24` sobre ese perímetro dé vacío. Añadir `stg` a la lista de `push`
rompe esa igualdad. No es algo que pueda decidir yo: o el perímetro cambia con tu orden, o el CI
sigue sin cubrir `stg`.

Respuestas posibles:
- *«Añade `stg` a los disparadores»* → lo hago en una rama propia y el perímetro deja de ser
  idéntico a `fb98f24`; dime si eso reabre la acreditación o si se re-declara sobre el nuevo SHA.
- *«Déjalo; la conformidad se lanza a mano con `workflow_dispatch`»* → lo documento como paso
  obligatorio del procedimiento, para que no se olvide.
- *«Se resuelve en otro carril»* → lo dejo estar y no vuelvo sobre ello.

**Nota de estado, para que no lo interpretes como un fallo mío:** lancé la conformidad a mano sobre
`stg` (`workflow_dispatch`) y las **dos** corridas quedaron `cancelled` sin ejecutar un solo paso
(`steps=0`, ~15 min esperando runner). Causa verificada: **GitHub Actions en `major_outage`**,
incidencia crítica abierta a las `2026-08-06T15:22:49Z`. Eso explica también el `HTTP 500` del
primer `gh workflow run`. Con independencia de eso, el perímetro S1 de `stg` es byte a byte idéntico
al de `fb98f24`, cuya conformidad Linux ya está verde (run `30955372277`).

---

## Duda 3 — `--permitir-cluster-efimero-local` en el target guard: ¿lo dejo o lo quito?

Del bootstrap r2 (bloqueante 3). El guard rechaza destinos locales por defecto. Ese flag es la única
forma de que la suite ejercite el camino **completo** del guard, incluido `--aplicar`.

Está acotado por construcción, no por convención: **solo se acepta cuando el destino resuelve a
socket Unix**, y STG es remoto por TCP; usarlo contra un destino remoto es a su vez un abort
(código 6). Aun así, es una puerta, y las puertas se acaban usando.

- *«Déjalo»* → sin cambios; el camino `--aplicar` conserva cobertura automática.
- *«Quítalo»* → lo quito y ese camino queda **sin cobertura de test**; el guard solo se acreditaría
  por sus rechazos. Prefiero que la pérdida sea decisión tuya y no un descuido mío.

---

## Duda 4 — `phone_number` nullable: ¿gap aparte o no procede?

`docs/s1/reporte-gaps-esquema.md` describe el objetivo contractual de `phone_number` como
*«texto ≥32, **nullable**, nunca unique por sí solo»*. El handoff del bootstrap ordena **conservar
`NOT NULL`** y lo lista como invariante.

No lo traté como contradicción: el handoff es explícito, posterior y acota el alcance al ensanchado.
Conservo `NOT NULL` y lo verifico releyéndolo tras el `ALTER`. Lo señalé en los dos informes para
que constara que lo detecté y no fue un descuido.

**Lo que te pregunto:** ¿el paso a `nullable` es un gap pendiente que haya que planificar, o el
contrato ya se da por satisfecho con el ancho y "nullable" era una lectura no material? No propongo
tocarlo; solo quiero saber si queda algo abierto ahí o lo doy por cerrado.

---

## Contexto que no es duda, pero que deberías tener

La **API key de n8n PROD** de `.env` llevaba desde el ~29 jul devolviendo **401**, y el chequeo
diario de drift abortaba a media corrida por eso (8 corridas). **No fue un incidente de seguridad:**
la key nueva se emitió el **29 jul 19:25 UTC**, justo cuando la vieja dejó de servir — se rotó ese
día y el `.env` local nunca se actualizó. Repuesta por Alberto hoy, verificada por efecto real
(401 → 200), y el barrido de drift posterior dio 10/10 limpio.
