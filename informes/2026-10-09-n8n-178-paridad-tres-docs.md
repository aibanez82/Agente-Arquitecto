# Informe — `#178`: paridad de los tres docs + guarda sobre los tres (PR #110 a `main`, lo fusiona Alberto)

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Responde a:** `Agente-n8n:handoffs/2026-10-08-178-paridad-de-los-tres-docs.md` (2681ea33).

## Paridad medida (`origin/`, tras `fetch`)

| doc | main | stg | estado |
|---|---|---|---|
| `docs/convenciones-de-rama.md` | `bdfb977c` | `bdfb977c` | ✅ |
| `docs/scripts-vivos.md` | `c94bd5bc` | `c94bd5bc` | ✅ |
| `docs/gotchas-n8n.md` | `56649938` | `e79b1b45` | ❌ diverge: a `main` le falta el gotcha 14 completo, el 31 y del 36 al 40 |

**Lo vigente es `stg`**, y nada indica lo contrario: lo que le falta a `main` son gotchas posteriores, ya citados en el trabajo de septiembre y octubre.

## El cambio: rama `docs/178-paridad-tres-docs` sacada de `origin/main` → **PR #110 a `main`**

1. `docs/gotchas-n8n.md` de `main` pasa a ser el de `stg`, byte a byte.
2. `scripts/arranque-sesion.sh` §3.bis: la guarda pasa de 1 doc a los **3**.
   - Ya fallaba en positivo ante un doc ausente: `cat-file -e` en las dos ramas, para que un doc ausente en ambas no salga «idéntico».
   - Las referencias son parametrizables (`GUARDA_REF_MAIN`/`GUARDA_REF_STG`, por defecto `origin/…`) para el control.

**Por qué el PR va a `main` y no entra por `stg`:**
- lo vigente ya está en `stg`;
- `arranque-sesion.sh` **solo existe en `main`**, como dice `CLAUDE.md`.

El único lado que cambia es `main`. El merge lo dispara Alberto (`convenciones-de-rama.md`, 18 ago).

## Control positivo (worktree, commits locales sin pushear; la sección de la guarda extraída tal cual)

| caso | salida |
|---|---|
| (a) hoy, `origin/main` vs `origin/stg` | `DRIFT: docs/gotchas-n8n.md difiere entre main y stg`; los otros dos, ok |
| (b) la rama del PR como main vs `origin/stg` | los 3 `ok` (la paridad tras el merge) |
| (c) divergencia provocada en `scripts-vivos.md` | `DRIFT: docs/scripts-vivos.md difiere` |
| (d) `gotchas-n8n.md` borrado en main | `DRIFT: docs/gotchas-n8n.md no existe en main` |
| (e) borrado en las dos | `DRIFT: … no existe en main y stg` (no da «idéntico») |

**Pendiente:** el merge del PR #110 (Alberto). Después, el arranque de sesión dará los 3 `ok`.

Agente: Agente-n8n
