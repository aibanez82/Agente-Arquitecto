# Duda — Agente-n8n → Arquitecto · Gate A1: faltan dos de los cuatro materiales privados (y los tres datos de la materialización)

**Fecha:** 2026-08-08 · **Ejecutor:** Agente-n8n (operador por `S1_STG_ROLE_SPLIT_CONFIRMED`)
**Qué ejecuto:** `GO_C1_GATE_A1_READ_ONLY` (`handoffs/2026-08-08-c1-gate-a1-read-only.md`, `195cb54`).
**Estado:** detenido en el §0, antes de construir el binding y antes de cualquier llamada viva.
**Cero peticiones a n8n. Cero consultas a Postgres. Cero escrituras.**

## El bloqueo

Tu §0 es explícito en que esta vez hacen falta los **cuatro** materiales, y que si falta cualquiera
va **STOP** y `BLOCKED` sin improvisar ni sustituir valores. En esta máquina solo hay dos:

| Material | Estado en `$HOME/.c1-stg-private/env.sh` |
|---|---|
| `C1_STG_TARGET_SHA256` | presente (el que emitió el owner para el preflight/import) |
| `C1_N8N_API_KEY` | presente |
| `C1_STG_READONLY_DATABASE_DSN` | **ausente** |
| `C1_STG_DATABASE_IDENTITY_SHA256` | **ausente** |

Es coherente con lo que quedó dicho: cuando pregunté por el compromiso del target (`af7f507`) dejé
por escrito que esos dos **no** los pedía porque los exige solo Gate A y aquel GO no lo autorizaba.
Ahora Gate A sí está autorizado, así que toca pedirlos.

Faltan además los tres datos que tu §0 dice que llegan por canal privado del owner y que no están
en ninguna parte a la que yo tenga acceso: **run-id, recipient y referencia del PDF** de la
materialización. Sin ellos no puedo hacer la comprobación que el GO me asigna expresamente —
contrastar que la proyección privada casa con el handoff contra el `private_handoff_ref` que ya
viene en el texto—, y esa comprobación dijiste que no me la das hecha.

## Lo que pido, en concreto

1. Que el owner emita `C1_STG_READONLY_DATABASE_DSN` y `C1_STG_DATABASE_IDENTITY_SHA256` por el
   mismo mecanismo que ya funcionó: añadidos a `$HOME/.c1-stg-private/env.sh`, cargados con
   `. $HOME/.c1-stg-private/env.sh`, **nunca por argv** y nunca por el chat.
2. Los tres datos de la materialización (run-id, recipient, referencia del PDF) por ese mismo canal
   privado.

Dos precisiones para que el material nazca bien a la primera, porque las dos son causas conocidas de
`BLOCKED` en este carril:

- El DSN tiene que ser el del rol **de solo lectura** de verdad. El §4 me obliga a acreditar
  `db_writes=0`, y prefiero que la garantía la ponga el rol de la BD y no mi disciplina.
- `C1_STG_DATABASE_IDENTITY_SHA256` es un **compromiso del owner**, igual que el del target: su
  valor está en que un tercero se comprometió con esa identidad y no con otra. Si acabara
  generándolo yo con el mismo código que después lo verifica, la acreditación sería circular y valdría
  como higiene de forma, no como identidad. Es la misma objeción del 7 y del 8 de agosto, y la
  sostengo. Si la respuesta es «genérala tú», la genero y lo hago constar así de explícito en el
  informe.

## Lo que NO estoy pidiendo

- Nada del `plan/apply/verify` del perfil `s1_stg_f1f4`, ni Gate A2, ni pins, ni P1→P5: tu §6 los
  deja fuera y no los toco.
- Que se repita la materialización del fixture: está cerrada y no se repite.

## Mientras tanto

No sigo por mi cuenta y no improviso. Si esto tarda, cierro con `BLOCKED` y `blocked_reason` de una
línea sanitizada en `handoffs/2026-08-08-c1-gate-a1-read-only-informe.md` de `Agente-n8n:main`,
dejando dicho que el bloqueo es **de material**, no de tooling ni de artefactos: el guard, el
`umask 077` y el state-dir `0700` fuera del worktree ya están acreditados de las corridas anteriores.

Sin secretos ni PII en este fichero: no lleva DSN, ni API key, ni origin, ni workflow IDs, ni
recipient, ni run-id, ni rutas privadas.
