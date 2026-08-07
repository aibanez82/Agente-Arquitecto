# C1-N8N-CAPABILITIES@1.0.0 — traducción de R2-01…R2-08 a cambios exactos (preparación de R3)

> **DOCS-ONLY.** Preparado durante el stand-down del dictamen
> [`CHANGES` sobre `ac90bc4`](https://github.com/aguayo-co/HYL-WAI/issues/132#issuecomment-5219252160)
> (#132 `c.5219252160`, 7 ago 15:59Z). **No es un handoff** y no autoriza trabajo: liderazgo debe
> publicar antes el **freeze menor** de la acreditación `initially open` (§6.4.1/§11.6).
> Acuse nuestro: `c.5219496097`. Aviso al ejecutor: `Agente-n8n@e48d079`.
>
> Todos los anclajes de fichero:línea están verificados por lectura directa del árbol `ac90bc4`
> (`tree cf64995e`), no tomados del dictamen.
>
> **Estatus de este documento, fijado por liderazgo** (`c.5219659877`): *«la matriz DOCS-ONLY puede
> conservarse como análisis preparatorio fuera del candidato/PR #4, pero **no es GO de
> implementación, no congela decisiones y queda subordinada al patch contractual**»*. Es decir:
> cuando se publique el addendum del freeze menor, **este documento se revisa contra él** — no se
> da por bueno. Lo que aquí se afirme y el patch contradiga, lo gana el patch.

## Estado y dependencias del freeze menor

| Bloqueante | Severidad | ¿Depende del freeze menor? |
|---|---|---|
| R2-01 binding no validado contra el schema | CRÍTICO | **SÍ** — el freeze decide si `initially open` se acredita en preflight/smoke o entra como atestación cerrada en el binding, y eso cambia schema y validador |
| R2-02 cross-workflow y predicates degradados | CRÍTICO | No |
| R2-03 CLI viva sin implementación | CRÍTICO | No |
| R2-04 plan/preflight/pin/rollback sin garantías | ALTO | **PARCIAL** — si la acreditación va a preflight, §11.2 gana un paso; el resto del bloqueante es independiente |
| R2-05 recuperación y cierre incompletos | ALTO | No |
| R2-06 rutas privadas no cerradas | ALTO | No |
| R2-07 los cinco positivos son *contract theater* | ALTO | No |
| R2-08 destino operativo versionado | POLÍTICA | No |

**Se puede empezar por R2-08, R2-06, R2-03, R2-05 y R2-07 sin esperar al freeze.** R2-01 y la parte
de preflight de R2-04 se quedan para el final.

---

## R2-08 — POLÍTICA · dos hostnames REALES versionados (empezar por aquí: es de minutos)

**Verificado, y peor de lo que dice el dictamen.** Éste habla de «*un* test contiene *un* hostname
de infraestructura *aparente*». Son **dos**, y no son aparentes:

| Fichero:línea | Qué contiene |
|---|---|
| `scripts/s1-c1/test/casos-operativos.test.js:31` | `origin` de la instancia **STG** real |
| `scripts/s1-c1/test/casos-operativos.test.js:101` | `origin` de la instancia de **PRODUCCIÓN** real |

Que un carril declarado STG-only lleve versionado el destino de PROD no es una errata de dominio:
es **riesgo de confusión de target**. Trátalo con esa severidad.

**Cambio:** ambos a dominio reservado `.invalid`. Hay precedente interno en el propio candidato
(`lib/contrato.js` y el fixture ya usan `.invalid`). Después, **barrido del diff completo** por
hosts, instance IDs y destinos antes de publicar el sucesor.

**Elevado por liderazgo** (`c.5219659877`), con tres precisiones que cambian cómo se cierra:

1. Se **acepta** el agravamiento: dos destinos reales versionados, uno de PROD. No se reproducen.
2. **El barrido de redacción pasa a ser GATE**, no una comprobación de cortesía: sin él no hay
   sucesor válido. Conviene implementarlo como test que falle solo, no como paso manual de checklist
   — un gate que depende de que alguien se acuerde no es un gate.
3. **NO se autoriza reescritura de historia.** Las dos líneas se corrigen **hacia delante** en el
   sucesor; los commits existentes se quedan como están. Nada de `filter-branch`, `rebase` de
   limpieza ni force-push para «borrar» los hostnames del historial.

Liderazgo hace constar además que **no se observó exposición de credenciales** — el hallazgo es de
destino, no de secreto.

---

## R2-01 — CRÍTICO · el validador de schema es un subconjunto, y `--environment prod` no aborta

### 1a. El validador cubre 6 constructos de los 18 que usa el schema

`lib/binding.js:26-69` (`validarSchema`) implementa a mano: `type` (object/string/integer/boolean),
`properties`, `required`, `additionalProperties:false`, `pattern`, `enum`.

Conté los constructos que **usa** `contract/schemas/runtime-binding.schema.json`. Los no soportados,
con su número de apariciones:

| Constructo | Apariciones | Soportado |
|---|---|---|
| `const` | 11 | ❌ |
| `items` | 9 | ❌ |
| `minimum` | 6 | ❌ |
| `$ref` | 6 | ❌ |
| `minLength` | 4 | ❌ |
| `format` | 4 | ❌ |
| `minItems` / `maxItems` | 3 / 3 | ❌ |
| `maxLength` | 2 | ❌ |
| `allOf` | 2 | ❌ |
| `$defs` | 1 | ❌ |
| `oneOf` | 1 | ❌ |

**52 apariciones ignoradas en silencio.** Ese es el mecanismo exacto por el que el binding con
`const`/`minimum`/UUID inválidos que Juan construyó da schema FAIL con `Draft202012Validator` y
`bnd.compilar()` **ACCEPT**. `$ref`/`$defs` sin resolver es lo más grave: una rama entera del schema
no se recorre.

**Cambio:** semántica Draft 2020-12 completa del schema cerrado, o validación equivalente
exhaustiva, **contrastada contra un validador independiente** (el dictamen exige el contraste, no
solo el resultado). Fijar `contract`/`profile`/`environment` a sus `const`.

### 1b. El builder acepta `prod` si el binding también dice `prod`

`build-candidate.js:197-198`:

```js
if (binding.environment !== a.environment) {
  throw new ErrorContrato('C1_TARGET_DENY', `el binding es de ${binding.environment}, no de ${a.environment}`);
}
```

Comprueba que **coincidan**, no que sean `stg`. Con binding `prod` + `--environment prod` coinciden
→ rc 0. Esto invalida parte de mi propia verificación de r2: yo probé binding `prod` contra
`--environment stg` (que sí deniega) y lo di por bueno; el caso de ambos en `prod` no lo probé.

**Cambio:** denegar **siempre** ambiente distinto de `stg`, con independencia de que coincidan.

### 1c. `validarConsistencia` no comprueba la semántica A/B

`lib/binding.js:85-126` verifica: A≠B en quote/lead/conversation, tres `messages[0].id` distintos,
`from` == recipient, existencia de `payment_event_id`, atestación y aliases.

**No verifica:** el mapeo de quick replies F1-v1→A / F1-v2→B / F2→B, la coherencia
conversación↔cotización↔lead, ni que Payment opere sobre B. Por eso un binding «schema-valid pero
F1-v1 cruzado a B y Payment apuntando A» compila.

**Cambio:** validar todas las relaciones A/B/Payment de §6.4.1.

---

## R2-02 — CRÍTICO · los nueve refs colapsan predicados compuestos a un solo campo

Éste es el bloqueante con más superficie y el que explica los rechazos del happy path.

`lib/binding.js:166-176` construye los refs. Contrastado con la tabla de frases de
`lib/predicados.js:37-64`, el colapso es literal:

| Frase del fixture (`predicados.js`) | Ref emitido (`binding.js`) | Qué compara de verdad |
|---|---|---|
| `quote, lead and session equal binding` | `quote_lead_session` | **solo** `quotation_id` = `quote_b` |
| `event, session, recipient and sender equal binding` | `event_session_recipient_sender` | **solo** `event_id` = `payment_event_id` |
| `resolvedSessionId and messageId equal binding` | `session_and_message` | **solo** `session_id` = `conversation_b` |
| `recipient equals binding and sessionRow.phone_number` | `recipient` | **solo** `phone_number` |

Y hay un segundo defecto encima del primero: **todos los refs se calculan sobre los valores de B**
(`conversation_b`, `quote_b`). Ningún ref admite el valor de A. Por eso los gates Main de affinity,
claim, fetch, mark-sent e history **deniegan el positivo real** — el caso de A no puede satisfacer
un commitment calculado sobre B.

El caso SQL de Payment tiene su propia variante: el ref busca `event_id` **top-level**, mientras el
output real de `S1 Payment Request Guard` lo lleva en **`body.event_id`**.

**Cambios:**
1. **Allowlist por workflow** en los gates de input: hoy ambos reciben los cuatro commitments, por
   eso Payment→Main y Main→Payment atraviesan. Main admite tres valores, Payment uno.
2. Predicados compuestos como **tuplas canónicas completas**, con allowlist por caso A/B — no un
   campo y un valor.
3. Resolver tipado **por predicate y por fuente autoritativa real**, no la primera autoridad para
   todos.
4. Payment compara el **body canónico completo**; outbound compara `event+session+recipient+sender`.
5. Tests: controles **positivos con outputs reales de cada business node** y negativos por cada
   componente de la tupla.

---

## R2-03 — CRÍTICO · la CLI viva es un stub

Verificado: `lib/cliente.js:74` `clienteReal()` lanza siempre `C1_LIVE_CLIENT_FORBIDDEN` (salida
23); `profile-cli.js:114` lo usa; y `test/casos-operativos.test.js:363-367` **exige** ese aborto.
El comando `preflight` sale 23 antes de acreditar nada.

**No es diferible al checkpoint** — el dictamen es explícito: introducirlo allí cambiaría el
candidato después de la conformidad.

**Cambio:** cliente público real implementado **offline** y probado con **transporte HTTP falso**:
API pública de n8n versionada, auth desde entorno, timeout, manejo HTTP/JSON, normalización de
workflow/execution data, PUT compatible, **redirects deshabilitados**, origin/instance/version
acreditados y errores redactados. `pin` sigue GET-only/UI.

---

## R2-04 — ALTO · la CLI no pasa lo que las funciones necesitan

Tres defectos de cableado verificados en firma vs llamada:

| Síntoma | Anclaje |
|---|---|
| `plan()` se llama sin el parámetro que activa la comparación de binding | `profile-cli.js:126` vs firma en `lib/operativa.js:236` |
| `pin-verify` nunca recibe `bindingRefs`, y el chequeo está tras un `if (bindingRefs)` → **se salta en silencio** | `profile-cli.js:134` vs `lib/operativa.js:409` y `:434` |
| `rollback --from` llega como `desdeJournal` pero la función **no tiene ese parámetro** y lo ignora | `profile-cli.js:133` vs firma en `lib/operativa.js:386` |

El patrón común es el mismo defecto de diseño: **argumentos opcionales que degradan a no-comprobar
en vez de abortar**. Un parámetro que activa una garantía no puede ser opcional.

Además, del dictamen (no re-verificado línea a línea, anclado por síntoma en `lib/operativa.js`):
`plan` no verifica `manifest.private.json`, fingerprints, baseline ni run binding, y no persiste
run-id/binding; un plan con role duplicado pasa; `preflight` no verifica perfil/binding homogéneos
ni roots/connections (el fake conforme usa `connections={}` y pasa); un cambio live post-preflight
lo sobreescribe `apply`; la comparación plan recibido↔persistido es **tautológica** (ambos del mismo
fichero); y origins loopback pueden autoacreditarse si el peer devuelve los mismos textos.

**Cambios:** plan **cerrado y sellado** desde manifest privado acreditado (dos roles/IDs/orden/
hashes/binding/run exactos); comandos posteriores revalidan **seal, target e identidad aprobada**;
preflight rehecho **inmediatamente antes del PUT** o compare-and-swap efectivo; commitments de pin
derivados del artefacto privado sin exponerlos; `--from` honrado y validado. Y **anclar el target al
checkpoint privado aprobado**, no a lo que el peer afirme de sí mismo.

---

## R2-05 — ALTO · recuperación y cierre

Anclado en `lib/operativa.js`: `rollback` (`:386`), `close` (`:481`), `executionVerify` (`:452`),
`intentosAbiertos` (`:108`), y la fuga de `e.message` en `apply` (`:337`).

- `rollback` hace PUT sin intención+fsync nueva, sin capturar desenlace incierto y sin GET posterior.
- Tras muerte real, `reconcile` puede clasificar `no-aplicado` pero `rollback` no añade terminal: el
  `attempted` queda **abierto para siempre** y bloquea todo apply/close futuro.
- `close` usa la lógica antigua y **no llama a `intentosAbiertos()`** (existe en `:108`, exportada en
  `:528`): un terminal histórico del mismo workflow puede tapar un `attempted` nuevo.
- `execution-verify` solo consume resúmenes `roots/triggersExternos`; una ejecución sintética con
  case inventado e IDs duplicados pasa.
- `apply:337` propaga `e.message` del transporte al journal → **fuga reproducida** de marcadores de
  body/nonce.

**Cambios:** journal por attempt/operation ID con formatos cerrados; `rollback` con las mismas
garantías de PUT que `apply` más verify posterior; `close` sobre intentos abiertos ordenados;
errores de transporte **redactados**; evidencia de ejecución derivada de run data real con matriz
exacta de cinco casos/orden/roles.

---

## R2-06 — ALTO · el builder valida el fichero, no la cadena

Verificado en `build-candidate.js`:

| Línea | Qué hace | Qué falta |
|---|---|---|
| `:184-190` | `lstatSync` del binding y exige modo `0600` | **no valida el directorio padre** (de ahí que un parent `0777` o un symlink de directorio pasen) |
| `:205` | `mkdirSync(dir, {recursive:true, mode:0o700})` | `mode` en `mkdir` **no corrige un directorio ya existente** en `0777`, y no hay `lstat` del padre de salida |
| `:208`, `:214`, `:218` | `writeFileSync(..., {mode:0o600})` | `writeFileSync` **sigue symlinks**: es exactamente el «`main.json` preexistente como symlink → el builder lo siguió y sobrescribió el destino» |
| `:244` | comprueba `realpath` fuera del worktree | solo eso; no cubre modos ni symlinks intermedios |

**Cambios:** `lstat`/owner/mode/`realpath`/no-symlink de **toda la cadena** (binding, su padre,
`$PRIVATE_OUTPUT`, subdirectorio y cada fichero); abrir salidas con **creación exclusiva y
no-follow** (`flag:'wx'` + `O_NOFOLLOW`) y **verificar `0600`/`0700` después de escribir**. Añadir:
`manifest.redacted.json` con fingerprints de artefactos (§6.4.5) y `manifest.private.json` con el
SHA privado completo del binding (§6.6) — sin nonce ni recipient.

---

## R2-07 — ALTO · los cinco positivos no ejecutan nada

Verificado en `test/casos-positivos.test.js`, y la crítica es exacta:

- **`:25-26`** — ambos workflows se construyen con **`binding = null`**. Con binding nulo los gates
  deniegan por diseño; el test nunca los ejerce.
- **`:65`, `:80-82`** — recorre `caso.visited_nodes`, que es **el propio fixture**, y solo pregunta
  si cada nombre es alcanzable por *algún* camino (`alcanzable()` en `:40-50`, un DFS de existencia).
  No hay secuencia, ni branch, ni predicate, ni SQL, ni postcondición.
- **`:94-95`** — `contar(WF[rol], caso.visited_nodes, …)` clasifica **esa misma lista** y la compara
  con `caso.observed_effects`. El comentario de cabecera afirma que «comparar `observed_effects`
  consigo mismo pasaría siempre» y acto seguido el conteo se deriva de la lista que el fixture da
  como entrada.

Por eso `positive_cases=5` es un **conteo declarativo** y no detectó los rechazos ni los false
allows de R2-02. Los tests nuevos de r2 ejercen gates **aislados**, no P1–P5 end-to-end.

**Cambio:** harness **secuencial por caso**, con binding conforme, outputs realistas de cada
nodo/autoridad y ejecución del **código real de todos los gates**. El recorrido observado debe
**producirse**, no leerse del fixture.

---

## Orden de ataque propuesto para R3

1. **R2-08** (minutos) y **R2-06** (contenido, sin dependencias).
2. **R2-03** — el cliente falso de transporte es prerequisito para probar bien R2-04/R2-05.
3. **R2-04** cableado (los tres defectos de firma vs llamada son mecánicos) → **R2-05**.
4. **R2-02** — el más grande; conviene con R2-07 delante, porque el harness real es lo que demuestra
   que los predicados compuestos quedan bien.
5. **R2-07** harness secuencial.
6. **R2-01** al final, cuando el freeze menor fije dónde vive `initially open`.

**Un sucesor único** sobre el mismo PR/base (`stg@7608f93`), con regresión sintética por cada
reproducción del dictamen — el mismo método que cerró los ocho de r1.
