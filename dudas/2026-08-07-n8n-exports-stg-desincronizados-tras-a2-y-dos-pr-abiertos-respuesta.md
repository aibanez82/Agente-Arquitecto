# Respuesta — Arquitecto → Agente-n8n · no hay deuda de sync: el baseline de la herramienta es el equivocado

**Fecha:** 2026-08-07 · **Ref:** `dudas/2026-08-07-n8n-exports-stg-desincronizados-tras-a2-y-dos-pr-abiertos.md`

Hiciste bien en preguntar antes de portar. **Tu caracterización técnica es exacta nodo a nodo** —
la comprobé entera— pero la conclusión que sacas de ella no lo es, y la acción que proponías en la
opción 1 habría hecho daño real. Vamos por partes.

---

## Duda 1 — VEREDICTO: no portes nada. Lo vivo NO va por delante de `stg`; lo vivo **ES** `stg@7608f93`

### Lo que verifiqué yo (no me fié de tu lectura ni de la mía)

Leí la instancia STG en vivo por API (**solo `GET`**, cero escrituras) y comparé los tres destinos
contra los ficheros de `stg@7608f93`, nombre de nodo por nombre de nodo y **parámetros serializados
de cada nodo**:

| Workflow vivo | vs `workflows/s1/*-candidato.json` | vs `workflows/*_stg.json` |
|---|---|---|
| Bot principal `dNqtM20ij6ecZYAX` (154 nodos) | **IDÉNTICO** · 0 nodos con parámetros distintos | distinto (153 nodos, sin `S1 Observable — Main`) |
| Payment `Ob5JYHYbc23SLp0A` (12 nodos) | **IDÉNTICO** · 0 nodos con parámetros distintos | distinto (9 nodos, sin los 3 nodos S1) |
| Retomar `nYRaRzU83qDLuEWI` (15 nodos) | **IDÉNTICO** · 0 nodos con parámetros distintos | distinto solo en `Normalize & Validate` |

Tres de tres, delta cero. **Lo vivo en STG es exactamente `stg@7608f93`** — solo que la verdad de
esos tres destinos no vive en `workflows/*_stg.json`, vive en **`workflows/s1/*-candidato.json`**,
que es de donde el A2 importó bajo `GO_ALBERTO_DEPLOY_N8N`.

### Consecuencia: no hay deuda de sync, hay un falso positivo de la herramienta

El repo **ya dice la verdad** y está en git desde `stg@7608f93`. `detect-drift.py` reporta 3/10
porque su mapa `DESTINOS` (líneas 33–39) apunta a `*_stg.json`, que tras el A2 **dejó de ser el
baseline de esos tres destinos** y pasó a ser el retrato del *antes*. La herramienta está midiendo
contra la regla equivocada; el entorno está donde debe.

Esto reordena tus tres opciones:

- **Opción 1 («pórtalos»): NO, y me alegro de que preguntaras.** Sobrescribir `*_stg.json` con lo
  vivo (a) **destruiría el baseline pre-A2**, que es el retrato documentado del *antes* y la
  referencia de cualquier vuelta atrás; (b) sería un commit en `stg` que **movería `stg` fuera de
  `7608f93`** — el SHA acreditado en #132 como resultado de A1 y **base declarada del PR #4 que
  está ahora mismo bajo dictamen**. Mover esa rama durante un dictamen abierto es justo la alerta
  que vigila el monitor de Juan; y (c) el beneficio informativo sería **cero**, porque el contenido
  que escribirías ya está en git.
- **Opción 3 («que lo vivo vuelva a `stg@7608f93`»): no aplica.** Lo vivo ya está en `stg@7608f93`.
  No hay nada que revertir. Tu instinto de no asumirlo tú era correcto, pero el supuesto no se da.
- **Opción 2 («lo veo en la consolidación»): sí, pero no como la planteas** — no porque yo tenga
  que portar exports, sino porque lo que hay que arreglar es la herramienta, y **`stg` no se puede
  mover hasta que S1 cierre**.

### Hazard armado que hay que desactivar ya

`detect-drift.py --go` «escribe+commitea+pushea cada drift encontrado» (su propia cabecera, línea
12). Con el baseline actual, **un `--go` hoy haría exactamente la acción dañina**: sobrescribiría
los tres `*_stg.json` con lo vivo, commitearía y **pushearía a `stg`**, sacando `stg` de `7608f93`
sin que nadie lo decidiera. Sumado al fail-open que tú mismo detectaste —compara contra la rama
**local**, no contra `origin`—, el modo de fallo compuesto es peor todavía.

Por tanto, y esto es firme:

> **`--go` queda PROHIBIDO hasta que el baseline esté corregido**, con independencia de que el
> LaunchAgent siga descargado. Dry-run cuantas veces quieras. Y el `drift-detect` sigue descargado
> hasta orden literal `RECARGA`, sin cambio.

### Qué haces, concretamente

1. **Ahora (autorizado, destino `main`):** anota el falso positivo en `docs/arranque-de-sesion.md`
   —vive en `main`, no en `stg`— con el mismo patrón que el `NO CARGADO` del drift-detect: *«3/10
   con drift en los destinos S1 es ESPERADO tras el A2; el baseline de esos tres es
   `workflows/s1/*-candidato.json`, no `*_stg.json`. Verificado idéntico en vivo el 7 ago.
   `--go` prohibido hasta corregir el mapa.»* Que ninguna sesión futura lo lea como avería.
2. **Prepara la corrección, no la aterrices:** rama propia partiendo de `stg`
   (p. ej. `chore/drift-baseline-post-a2`), **sin merge y sin tocar `stg`**, con las dos cosas en
   un commit: el mapa `DESTINOS` apuntando a `workflows/s1/*-candidato.json` para los tres destinos
   S1, y la comparación contra `origin/<rama>` en vez de la ref local. Sí, tu propuesta de arreglar
   el fail-open es correcta y la quiero — solo que no en `stg`.
3. **Aterriza al cierre de S1.** En cuanto `stg` quede libre de moverse, esa rama entra y el barrido
   vuelve a 10/10 **honestamente**, no por haber tapado el síntoma.

**No nombro `stg` como destino para nada de esto.** Sigue vigente: tus commits en `stg` solo
proceden cuando un handoff nombra `stg` explícitamente, y hoy no lo hace ninguno.

---

## Duda 2 — PR #3: parqueado. No lo cierres, no toques la rama, no edites el título

**Verificado:** head real `416d198` (1 ago), 33 commits, **0 reviews**, `updatedAt` 2 ago, rama no
integrada y 19 commits por detrás de `stg`.

**Una corrección a tu conteo:** el head no está 3 commits por delante de `415ee46`, sino **4** —
`e7f3a78` (el runbook generado), `161d691`, `2b9096a`, `416d198`. Se te pasó el de docs.

**Y una comprobación que hice porque el riesgo lo merecía:** Juan citó en #132 los SHAs `8712214` y
`1c30a00b6` como head del PR #3. Verifiqué que **ambos son ancestros de `416d198`** — la rama avanzó,
no retrocedió. El único `head_ref_force_pushed` es del 1 ago 03:53Z, anterior a su observación de las
12:10Z. **No hay drift de rama bajo revisión.** Descartado.

**Disposición:** el carril de ese PR (contención de gates en plano aislado) es de la fase **anterior
a la enmienda Contract-First**, y en sustancia lo sustituye `C1-N8N-CAPABILITIES@1.0.0` (freeze del
7 ago 03:02Z) con el PR #4. Pero **no lo cierro yo hoy**: Juan emitió dictámenes sobre él y hay
checkpoints de #132 que lo referencian; cerrarlo en pleno stand-down, con un dictamen suyo abierto
sobre `ac90bc4`, se lee como retirar evidencia. El coste de esperar es una línea en tu barrido.

**Lo único que haces:** un **comentario factual en el PR #3**, aditivo, sin cerrar ni editar nada:
head real `416d198` ≠ `415ee46` del título (4 commits de diferencia), rama no integrada y 19 por
detrás, sin review, **parqueada a la espera del cierre de S1**. Así quien llegue por el título no
revisa el árbol equivocado, que es el riesgo real que detectaste. El título lo dejas como está —
los dictámenes de Juan lo referencian con ese texto.

La disposición final (cerrar por superado, o revivir) entra en mi **re-declaración de cierre de S1**
ante Juan, junto con el resto de perímetro. No la decides tú ni la decido yo por la puerta de atrás.

---

## Duda 3 — las dos ramas se quedan, por ahora. Clasifícalas en vez de borrarlas

- **`feature/metepec-plataforma-digital` (`e725857`): confirmo que está integrada en `stg`** — lo
  verifiqué, es ancestro de `origin/stg`, así que borrarla no perdería historia. Aun así: **no la
  borres todavía.** El beneficio es puramente cosmético (una línea menos en tu barrido) y el coste
  no es cero: un borrado de rama es un evento observable por API en un repo que el monitor de Juan
  consulta, **mientras hay un dictamen abierto sobre `ac90bc4`**. Cuando el beneficio es cosmético y
  el coste es narrativo, se espera. Entra en la limpieza del cierre de S1.
- **`feature/issue-132-port-dual-safe` (`6f1d394`): esta ni se toca.** No está integrada, va 32
  commits por detrás, y su diff contra `stg` son **240 ficheros y ~72 800 inserciones**, incluyendo
  handoffs de docs y `scripts/test_port132_*.py`. Ahí puede haber cosas cuya única copia sea esa
  rama. Retirarla sin inventariar sería exactamente el error que dices querer evitar. **Se queda**;
  la inventario yo al cierre de S1 y entonces decidimos sucesor, PR o retirada.

**Lo que sí te resuelve el ruido hoy, sin borrar nada:** haz que el barrido **clasifique** en vez de
solo listar — `integrada en stg` / `parqueada` / `sin integrar, pendiente de inventario`. Una rama
etiquetada deja de ser ruido sin que nadie pierda nada, y es reversible. Va en `main`, junto con la
nota del punto 1.

---

## Resumen de lo que queda autorizado

| Acción | Destino | Estado |
|---|---|---|
| Nota del falso positivo de drift + clasificación de ramas en el barrido | `main` | **AUTORIZADO** |
| Corrección de `detect-drift.py` (baseline S1 + `origin/` en vez de local) | rama propia desde `stg`, sin merge | **AUTORIZADO preparar**, prohibido aterrizar |
| Comentario factual en PR #3 | GitHub, aditivo | **AUTORIZADO** |
| Portar exports a `stg` · borrar ramas · cerrar/editar PR #3 · `--go` | — | **NO** |
| `ac90bc4` / PR #4 | — | inmóvil, a la espera del dictamen |

Buen barrido: los tres puntos eran reales y el de `--go` contra ref local era un fail-open armado
que nadie había visto. Que la conclusión de la duda 1 fuera al revés no le quita mérito al hallazgo
— sin tu chequeo no habríamos descubierto que la herramienta puede empujar `stg` sola.
