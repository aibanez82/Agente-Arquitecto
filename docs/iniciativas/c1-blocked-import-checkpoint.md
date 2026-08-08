# Checkpoint de import `blocked` — plan público, redactado y **no ejecutado**

> **Naturaleza.** Documento de checkpoint producido por Alberto para `ALBERTO_C1_BLOCKED_IMPORT_CHECKPOINT_READY`
> (#132 `c.5224460251`). **Nada de lo aquí descrito se ha ejecutado**: ni prelecturas, ni backup, ni
> importación, ni postlecturas, ni rollback. No se ha recuperado, validado, copiado ni materializado
> ningún material sensible. Este checkpoint **no autoriza operación alguna**; un GO posterior y
> separado deberá citar literalmente su fingerprint.

## 1. Autoridad contractual e identidad

| Elemento | Valor |
|---|---|
| Contrato | `C1-N8N-CAPABILITIES@1.0.2`, **CONGELADO** |
| Commit del contrato | `4053e82d90d1849ff2820ea4ab39c858b50c65d9` |
| Fingerprint combinado | `852489c77248bb95aa80d84d64c3f929b73282fcc83d848c0f4cb2260c000b71` |
| Implementación consumidora | `Agente-n8n/stg@10920d7d55c0b49464ccccc6383b1d6537be21fe` |
| Tree | `ff966940ee79577a5bb28240b21449282b26fd4a` |
| Conformidad | `IMPLEMENTATION_PASS` sobre `8a41b1f` (`c.5224344009`) · merge verificado (`c.5224460251`) |
| Compatibilidad cerrada | n8n **2.28.7**, exclusivamente **API pública** |

## 2. Artefactos de entrada — perfil `blocked`

Versionados en `stg@10920d7`, bajo `build/s1-c1/blocked/`:

| Artefacto | SHA-256 | Bytes |
|---|---|---|
| `main.json` | `d530168045d31bc6c689b3129d0828cded437af49eb4373e05d411467292ea89` | 556 426 |
| `payment.json` | `688c4aed6b96a0159a5d99e755748ae76155fff1d0d2ede1eaeba14981d5d8b5` | 67 218 |
| `manifest.json` | `2c63db43a290fc1e0a41f4a973cd3ed2295c8356a9c5ca57e5bee2e62c22ed53` | — |
| `scripts/s1-c1/manifests/s1-stg-f1f4.redacted.json` | `ad49eec0b0f02e0fc5d17c10cb9e175bd9772e5067e4e3ac65d79badfab73a43` | — |

Forma declarada de los artefactos: Main **160 nodos**, Payment **14 nodos**, ambos con
`active: false`. Son públicos y versionados: se releen con `leerVersionado`, con revalidación de
bytes y hash.

## 3. Roles, input, output, operador y ventana

- **Productor del checkpoint:** Alberto / `@aibanez82`. **Receptor:** liderazgo / operador n8n STG,
  en un GO posterior.
- **Operador de la ejecución:** el operador STG autorizado, bajo GO separado. **No** el productor.
- **Ventana:** la que fije ese GO. Este checkpoint no abre ventana ni la reserva.
- **Input:** los cuatro artefactos de §2, tomados exclusivamente de `stg@10920d7`.
- **Output esperado (futuro):** Main y Payment C1 importados **exactamente**, `active=false`,
  **cero pins** y default-deny.

## 4. Identidad del target STG — comprometida, no revelada

El target privado es un **JSON cerrado** con exactamente `origin`, `instance_id`,
`n8n_version="2.28.7"` y los dos workflow IDs normativos. Su acreditación es por **compromiso**:

- el operador dispone del sha256 del JSON canónico del target por **canal privado separado**;
- `instance_id` y versión son **metadata comprometida, no headers vivos** — la API pública fijada no
  los expone, extremo que quedó acreditado como bloqueo contractual y resuelto en `1.0.2`;
- la instancia se acredita **por contenido**: GET públicos de los dos workflows y comparación de la
  proyección completa contra el par esperado de la fase.

**Aquí no se publica ningún valor**: ni origin, ni instance id, ni los workflow IDs. Se referencian
por **rol** (`main`, `payment`) y por la variable de proceso que los porta.

## 5. Prelecturas (redactadas, no ejecutadas)

Todas por API pública 2.28.7, **solo GET**:

1. `GET` del workflow de rol `main` por su ID normativo → proyección writable y fingerprint.
2. `GET` del workflow de rol `payment` → ídem.
3. Lectura de estado de activación de ambos.
4. Lectura de pin data de ambos.

De cada respuesta se deriva **fingerprint y conteos**; no se conserva el cuerpo íntegro más allá de
la preimagen de §6.

## 6. Backup y preimágenes

- **Preimagen por workflow**, capturada del GET de §5 **antes** de cualquier escritura, serializada
  canónicamente y persistida en `$PRIVATE_STATE/preimages/<id>.json`, modo `0600`, sin symlinks y
  fuera del worktree.
- La intención y la preimagen se persisten **con `fsync` antes** del primer PUT: es lo que hace
  recuperable un proceso muerto entre la escritura y la inspección.
- **Backup histórico adicional — no requerido.** Existe un export completo previo de la instancia,
  fijado por **ref `origin/backup/2026-08-06-stg-pre-a2-import`, commit
  `204d067cb0dc76f244dd8444723dbc7c63af1f48`, bajo `backups/2026-08-06-stg-pre-a2-import/`**. En la
  versión anterior de este documento lo cité como si fuera un path de `stg@10920d7`, y **no lo es**:
  es una ref aparte y el directorio se llama `backups/`, en plural.
  **No sustituye a las preimágenes**: la reversibilidad normativa de este import depende
  exclusivamente de §11. Se declara como respaldo adicional y **no se ha recuperado ni validado su
  contenido**. Un backup vivo nuevo **no está autorizado** por este checkpoint.

## 7. Estado previo exigido

Antes de mutar nada, y como condición de continuación:

- ambos workflows con **`active === false`** — literal, la ausencia del campo **no** vale como
  inactivo;
- **cero pin data** en ambos;
- el par vivo `(main, payment)` coincide con el par esperado de la fase; un **par mixto** deniega;
- guard de target satisfecho **antes de cualquier request**.

Cualquier incumplimiento → **STOP**, sin escribir.

## 8. Comando inerte, con placeholders

Ninguno de estos comandos se ejecuta aquí. Los `$…` son **placeholders**; sus valores los aporta el
operador en la ventana autorizada.

```bash
set -euo pipefail

# ── 0) GUARD DE PROCEDENCIA — fail-closed. Si algo no cuadra, el bloque muere aquí ─────────────
#      `plan` sella el hash de los bytes que ENCUENTRE; eso evita drift posterior, pero no prueba
#      que esos bytes sean los congelados. Esto sí lo prueba, y antes de llegar a `preflight`.
CHECKOUT="${CHECKOUT:?ruta del checkout de Agente-n8n}"
cd "$CHECKOUT"

[ "$(git rev-parse HEAD)" = "10920d7d55c0b49464ccccc6383b1d6537be21fe" ] \
  || { echo "STOP: HEAD no es el acreditado"; exit 1; }
[ "$(git rev-parse HEAD^{tree})" = "ff966940ee79577a5bb28240b21449282b26fd4a" ] \
  || { echo "STOP: tree no es el acreditado"; exit 1; }
# El fallo del comando y el resultado limpio se separan: un `git status` que muere sin escribir
# stdout daba sustitución vacía y `[ -z "" ]` éxito, o sea "limpio". `set -e` no rescata ese caso
# porque el estado que ve el shell es el de la prueba exterior.
GIT_STATUS="$(git status --porcelain=v1 --untracked-files=all)" \
  || { echo "STOP: no se pudo acreditar limpieza"; exit 1; }
[ -z "$GIT_STATUS" ] \
  || { echo "STOP: worktree sucio"; exit 1; }

sha256sum --check --strict <<'SUMS'
d530168045d31bc6c689b3129d0828cded437af49eb4373e05d411467292ea89  build/s1-c1/blocked/main.json
688c4aed6b96a0159a5d99e755748ae76155fff1d0d2ede1eaeba14981d5d8b5  build/s1-c1/blocked/payment.json
2c63db43a290fc1e0a41f4a973cd3ed2295c8356a9c5ca57e5bee2e62c22ed53  build/s1-c1/blocked/manifest.json
ad49eec0b0f02e0fc5d17c10cb9e175bd9772e5067e4e3ac65d79badfab73a43  scripts/s1-c1/manifests/s1-stg-f1f4.redacted.json
SUMS

# 1) preflight — acredita target y estado antes de tocar nada
node scripts/s1-c1/profile-cli.js preflight \
  --target-file "$PRIVATE_TARGET" --state-dir "$PRIVATE_STATE"

# 2) plan — fija los artefactos y sella la corrida
node scripts/s1-c1/profile-cli.js plan \
  --target-file "$PRIVATE_TARGET" --state-dir "$PRIVATE_STATE" \
  --profile blocked --artifact-dir build/s1-c1/blocked

# 3) apply — único paso que escribe; toma los artefactos del plan, no de un flag nuevo
node scripts/s1-c1/profile-cli.js apply \
  --target-file "$PRIVATE_TARGET" --state-dir "$PRIVATE_STATE" \
  --plan "$PRIVATE_STATE/plan.json"

# 4) verify — POSTLECTURA EFECTIVA. `apply` hace los PUT y no acredita: es `verify` quien relee y
#    comprueba proyección writable, IDs, `active=false` y cero pins. Sin esta orden, §10 sería
#    una promesa narrada y no una postcondición ejecutada.
node scripts/s1-c1/profile-cli.js verify \
  --target-file "$PRIVATE_TARGET" --state-dir "$PRIVATE_STATE"
```

> **Portabilidad del guard.** `sha256sum --check --strict` es GNU. En macOS el equivalente es
> `shasum -a 256 --check` (y **no** admite `--strict`). Se señala porque hoy mismo un comando GNU
> dado por portable falló en silencio en BSD y costó una ronda: el operador debe usar el de su
> plataforma y comprobar que el comando **falla** ante un hash alterado antes de fiarse de él.

Propiedades **fail-closed** ya acreditadas de estos comandos:

- el **guard de target** corre en los diez subcomandos **antes del primer request**; con commitment
  incorrecto denegaron con **cero llamadas al cliente y cero escrituras**;
- `plan` **rechaza antes de escribir** aunque no haga ninguna petición;
- un error observado **después** de iniciar la request deja la ventana en `recovery-only`; un fallo
  del guard puro, anterior a la request, no la invalida.

**No hay ningún comando Heroku en este checkpoint.** Django permanece `shadow` y no se toca. Si un
GO posterior introdujera alguno, deberá llevar literalmente `--app hyl-wai-stg`.

### Canarios del guard (ejecutados offline, sobre un `git` sintético)

El guard se acredita como se acredita cualquier otra garantía de este carril: comprobando que
**falla cuando debe**, no que pasa cuando todo está bien.

| Canario | Resultado exigido | Observado |
|---|---|---|
| `git status` **falla sin escribir stdout** | STOP antes de `preflight` | STOP, exit 1 ✔ |
| Uno de los cuatro hashes alterado | STOP antes de `preflight` | STOP ✔ |
| `HEAD` distinto del acreditado | STOP | STOP ✔ |
| Todo correcto (control positivo) | continúa hasta `preflight` | continúa ✔ |

El primero es el que motivó esta revisión: en la versión `96aa1fff…` el bloque **llegaba a
`preflight` con exit 0** ante un `git status` muerto, porque la sustitución vacía y el worktree
limpio se veían igual. Reproducido con un `git` sintético que devuelve los valores acreditados en
`rev-parse` y sale 128 sin stdout en `status`.

## 9. Alcance de la mutación

- **Exclusivamente** los dos workflows C1 de rol `main` y `payment`, por sus IDs normativos.
- El cuerpo enviado es la **proyección writable**: `name`, `nodes`, `connections` y `settings`
  restringido a la allowlist `executionOrder`, `timezone`, `saveDataErrorExecution`,
  `saveDataSuccessExecution`, `saveManualExecutions`, `saveExecutionProgress`, `executionTimeout`,
  `errorWorkflow`. Nada de campos server-managed.
- **Dos PUT como máximo**, uno por rol. Ninguna activación, ningún pin, ningún otro workflow de la
  instancia.

## 10. Postlecturas

**Las ejecuta el subcomando `verify` del §8**, no `apply`: `apply` emite los PUT y no acredita nada.
Tras el apply, por GET público:

1. **Byte/fingerprint**: la proyección writable viva coincide **exactamente** con la del artefacto
   acreditado, para cada rol.
2. **`active === false`** en ambos.
3. **Cero pins** en ambos.
4. **Default-deny** verificable en el perfil importado: `allowed_capabilities=0` para `blocked`.

Discrepancia en cualquiera → no se declara éxito; se va a §11 o §12 según acredite la preimagen.

## 11. Restauración exacta

- La restauración usa **la preimagen exacta** de §6 y su fingerprint; **nunca un retry ciego** ni una
  reconstrucción.
- `reconcile` es **GET-only** y clasifica: `aplicado-propio`, `no-aplicado` o `incierto`.
- `rollback` persiste intención y preimagen **antes** del PUT inverso, verifica por GET después, y
  cuando `reconcile` acredita `no-aplicado` escribe un terminal **no-op durable** en vez de saltarse
  la anotación.

## 12. STOP y rollback

- Todo STOP —forma, evidencia, incertidumbre, crash o pérdida de exclusividad— marca la ventana como
  **`recovery-only` de forma durable, antes de devolver el error**.
- En `recovery-only` solo se admiten `reconcile`, `rollback` y `close`; los demás subcomandos paran
  **antes de cualquier request** (verificado: cero llamadas, cero escrituras).
- Un PUT cuyo resultado no se conozca es **incierto**, no fallido: **no se repite**; se reconcilia
  por GET.
- `verified` **nunca** terminaliza un intento abierto; solo `applied` o `rolled_back`.

## 13. Validación independiente

- Los artefactos se revalidan por **bytes y hash** contra los valores de §2 en el momento de leerlos.
- La instancia se acredita **por contenido**, no por etiqueta.
- El resultado se acredita contra la **proyección writable**, que es la misma función que construye
  el cuerpo del PUT: se compara lo que se envía, no una descripción de ello.
- Liderazgo revisa este checkpoint **antes** de cualquier llamada viva.

## 14. Materiales sensibles — referencias opacas

Se declaran **ubicación y propietario**, nunca valores, y **no se han recuperado ni validado**:

| Material | Propietario | Portador |
|---|---|---|
| Compromiso del target STG | Alberto (owner) | variable de proceso privada, canal separado |
| DSN read-only de la BD STG | Alberto (owner) | variable de proceso privada |
| Compromiso de identidad de la BD | Alberto (owner) | variable de proceso privada |
| API key de n8n STG | Alberto (owner) | variable de proceso privada |
| Target privado, binding privado, state-dir | operador, en la ventana | fuera del worktree, `0600`, sin symlinks en ancestros |

Ninguno de estos materiales es necesario para **este** checkpoint. El GO posterior fijará cuáles
entran y cuándo.

## 15. Lo que este checkpoint NO autoriza

Import, deploy, activación, backup vivo, prelecturas vivas, Gate A, pins, fixtures, run-id, binding
o recipient real, Dashboard `read_only`, Django `dual`, DML/DDL, envíos, rollback vivo ni PROD.

Estado seguro vigente y sin cambios: Django `shadow`, Dashboard `blocked`, n8n inactivo/default-deny.
S2 sigue bloqueado hasta `S1_OPERATIVO_PASS`.
