# Informe — `#230`: el export ya no lleva un segundo grafo. PR #95, sin instancias tocadas.

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Handoff:** `2026-08-25-el-export-no-lleva-un-segundo-grafo.md` · **Issue:** `aguayo-co/HYL-WAI#230` (abierto por mí, proyecto 2)

## Qué hay

Rama `fix/230-export-sin-segundo-grafo` (de `origin/stg`), **PR #95**, dos commits:

1. `186161e` — `write_export` filtra `activeVersion`, `activeVersionId` y `versionCounter`
   (constante `ENVOLTORIO_EXCLUIDO_DEL_EXPORT`, con tu porqué en el comentario: un respaldo no
   lleva dos grafos que digan cosas distintas; lo primero confunde, lo segundo se puede ejecutar).
2. Limpieza única de envoltorios en los **17 exports de primer nivel** de `workflows/`, con el
   mensaje de commit diciendo explícitamente que NO es drift ni cambio de grafo.

**Decisión de ámbito que tomé y reporto:** los archivos congelados (`borrados-stg-2026-08-14/`,
`c1-aislado-archivado-2026-08/`, `vivo-stg-2026-08-14/`) y **todo `s1/`** NO se tocan — zona
congelada de la revisión Contract-First. Sus `activeVersion` son instantáneas coherentes con su
momento (no gemelos divergentes), y el sync jamás los reescribe.

## Aceptación

| # | Comprobación | Resultado |
|---|---|---|
| 1 | Export **nuevo** (GET fresco de STG → `write_export`) sin las 3 claves, comprobado sobre el **fichero crudo** | ✅ |
| 2 | `name`/`active`/`nodes`/`connections`/`settings` idénticos al GET fresco (sort_keys) | ✅ |
| 3 | `CAMPOS_CON_SIGNIFICADO` sin cambios | ✅ — su definición no aparece en el diff (solo un comentario nuevo que la cita); 32 tests del helper en verde |
| 4 | Limpieza toca solo envoltorios | ✅ — hash SHA-256 de `nodes` y de `connections` idéntico pre/post en los 17; el diff son −26.629 líneas de envoltorio y 15 inserciones que son la misma línea `"tags": []` recuperando su coma final |
| 5 | Barrido `/i` de `is a separate technical value` sobre ficheros crudos | **NO da cero — 5 ficheros, cada uno con causa medida. Ver abajo** |

## §5 · Por qué no es cero, fichero a fichero

El **síntoma que abrió el handoff — la frase en un envoltorio rancio — sí está a cero**: ya no
existe ningún `activeVersion` en los exports vivos. Lo que queda vive en `nodes` (grafo real) y
tiene gobernanza encima:

| Fichero | Dónde vive | Por qué no lo he tocado |
|---|---|---|
| `WhatsApp Insurance Quotation Bot.json` | `nodes` (tool description) | **Es el espejo de PROD, y PROD vivo aún lleva la frase** (el secado nunca se importó allí — PROD apagado por Alberto). Quitarla del export sería falsificar el espejo |
| `WhatsApp Insurance Quotation Bot_stg.json` | `nodes` | En `stg` el secado vive en el **PR #94, sin mergear** (apilado sobre #93). En la rama `fix/228-secar-fuentes` este fichero ya está limpio; al mergear #93→#94, `stg` queda a cero aquí |
| `s1/main-candidato.json`, `s1/main-candidato-prod.json`, `s1/main-operativo-dual-stg.json` | `nodes` | **Zona S1 congelada** — prohibido tocar sin orden |

Es la misma foto que el apilado del `#228`: el cero real llega cuando Alberto mergee #93/#94 (stg),
ordene el paquete de PROD (espejo), y alguien dictamine qué pasa con los candidatos S1 congelados,
que arrastran el prompt de su época.

## Lo que no ha pasado

Ninguna instancia tocada. PROD `8c43fdd0-…` (sin releer esta vez: no hubo motivo — nada de esta
tarea se acerca a una API). El import sigue exactamente igual.
