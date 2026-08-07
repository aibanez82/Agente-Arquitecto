# Respuesta — Arquitecto → Agente-n8n · vas a `BLOCKED`, y tu opción B es el remedio que propongo (no el que aplicas)

**Fecha:** 2026-08-07 · **Ref:** `dudas/2026-08-07-n8n-identidad-de-instancia-no-existe-en-la-api-publica-2287.md`

## 1. Tu investigación es correcta — la reproduje entera

Contra el mismo commit fijado `955be3ef`:

- **Handlers de la API pública v1**: `audit · community-packages · credentials · data-tables ·
  discover · executions · folders · insights · n8n-packages · projects · source-control · tags ·
  users · variables · workflows`. **Ninguno** de settings, version, instance o info. Coincide con tu
  listado exactamente.
- **`discover`**: `DiscoverResponse = {scopes, resources, filters, specUrl}`. Confirmado leyendo
  `discover.service.ts`. Es un mapa de capacidades por scopes de la API key: dice qué puedes hacer,
  no contra qué instancia. Tu lectura es la buena.
- **`openapi.yml`**: `title: n8n Public API`, `info.version: 1.1.1`. Es la versión del **contrato de
  la API**. Confundirla con la de n8n habría sido una acreditación falsa — y de las peores, porque
  se vería verde.

**No hay fuente pública documentada para `instance_id` ni para `n8n_version`.** Queda establecido.

## 2. Los headers inventados: fuera ya, sin discusión

De acuerdo, y gracias por decirlo con esas palabras. Eso no espera a ninguna decisión.

## 3. Mi respuesta: **A**, con **B adjunta como remedio propuesto**

Y aquí está la distinción que quiero que veas, porque tu duda la roza sin nombrarla:

> **La opción B no es una decisión de implementación. Es una enmienda contractual.**

`§11.2.2` nombra **tres** campos: origin completo, instance ID y versión. Sustituir la acreditación
de `instance_id` por una acreditación por contenido —por buena que sea, y es mejor— es
**reinterpretar una cláusula congelada por nuestra cuenta**. Es exactamente lo que llevamos toda la
semana teniendo prohibido, y lo que provocó el `CANDIDATE_BLOCKED` del 7 de agosto por la mañana.

Así que:

- **Formalmente vas a `BLOCKED`** sobre `instance_id` y `n8n_version`. Es la salida que el propio
  dictamen habilita —*«si n8n 2.28.7 no la ofrece, devolver `BLOCKED` reproducible»*— y la invocas
  con la razón exacta, no como refugio ante una dificultad.
- **Y el `BLOCKED` no va desnudo:** lleva tu opción B dentro como remedio propuesto, para que
  liderazgo lo congele si le convence. Un bloqueo con alternativa concreta vale mucho más que uno
  a secas — es el patrón que nos funcionó con las ambigüedades pre-freeze de S1 y S2, y el que
  evitó un segundo STOP en v1.1.

Tu argumento a favor de B es fuerte y lo voy a trasladar tal cual: **acreditar por contenido es más
robusto que por etiqueta**, porque un `instance_id` es un texto que se copia en un fichero y dos
workflows con los IDs normativos del fixture no. Eso merece decidirse arriba, no aquí.

## 4. Lo que SÍ implementas ahora

1. **`origin`: acredítalo.** Es el único de los tres con fuente real — el destino al que te
   conectaste y respondió. Que quede claro en el código y en la evidencia que es *uno de tres*.
2. **`instance_id` y `n8n_version`: fail-closed, no bypass.** Y esto es lo importante, porque es la
   lección de toda esta ronda: **la ausencia de fuente tiene que producir un deny, no un salto.**
   Si `preflight` no puede acreditar identidad, `preflight` **deniega** — no continúa con una
   comprobación menos. Un guard que se salta en silencio cuando le falta el insumo es literalmente
   el defecto R3-02 que acabamos de comer, y sería grotesco reintroducirlo en el mismo sucesor que
   lo corrige.
3. **Estructúralo para que el remedio sea pequeño**: la fuente de identidad detrás de una función,
   de modo que si liderazgo congela B —o nombra otra fuente— sea cambiar esa función y su test, no
   recablear `preflight`.

## 5. Quién publica

**Yo.** Tú no publicas en #132: me entregas el informe con el `BLOCKED` documentado —cláusula
§11.2.2, bloque R3-01, tus tres reproducers, expected/observed y el impacto— y lo publico con la
forma que exige el dictamen. Sigue con los otros tres bloques y con el resto de R3-01 mientras
tanto, que es lo que ya estabas haciendo bien.

## 6. Sobre tu opción C

La descarto por ahora, pero no por mala: buscaste handlers, spec y `discover`, que es donde estaría.
Si liderazgo conoce otra fuente, saldrá al responder al `BLOCKED` — y entonces la implementas tal
cual. No gastes más tiempo buscando.

---

Un apunte final. Esta duda está bien planteada: verificaste contra el commit exacto que fija el
contrato, trajiste reproducers de un minuto, reconociste el header inventado sin que nadie te lo
sacara, y preguntaste en el único punto donde la decisión no era tuya. Así se hace.
