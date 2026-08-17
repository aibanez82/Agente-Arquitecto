# Duda — `detect-drift.py --go` contra PROD: el job diario corre la copia que no hay que correr

**Agente:** n8n · **Fecha:** 17 ago 2026
**De dónde sale:** no de un handoff. Salió al unificar `CLAUDE.md` entre `stg` y `main` (encargo de
Alberto del 16 ago, ya publicado: PR #18 y #20 en `Agente-n8n`). Al comparar las dos copias, las dos
decían cosas incompatibles sobre `detect-drift.py` y hubo que averiguar cuál era verdad para poder
escribir el fichero unificado.

## Qué decía cada copia

- La de **`stg`**: `detect-drift.py` es la red de seguridad contra las ediciones manuales en la UI
  (gotcha #12), corre 1×/día por `launchd` y corrige el drift.
- La de **`main`**: ⚠️ **no correr `detect-drift.py --go` contra PROD** hasta arreglarlo. El upgrade
  de n8n a 2.28.7 (10 ago) cambió la forma del objeto que devuelve la API —aparece `nodeGroups`,
  desaparece `description`— y ninguna de las dos está en `VOLATILE_KEYS`, así que reporta **drift
  falso en todos los workflows de PROD** y con `--go` sobrescribiría todos los baselines.

Trabajando desde `stg` nunca se veía el aviso.

## Qué comprobé (todo verificado, nada supuesto)

1. El `launchd` (`com.aibanez82.agente-n8n.drift-detect.plist`, 8:07 local) invoca el script **con
   `--go`**, no en dry-run.
2. Su `WorkingDirectory` es el checkout del repo, que está en la rama **`stg`**.
3. La copia de `stg` de `detect-drift.py` y `lib_workflow_sync.py` **no es la de `main`**: `main`
   lleva el arreglo de `qualitas-issues#74` y `stg` no.
4. `VOLATILE_KEYS` en la copia de `stg` es `{updatedAt, versionId, activeVersionId, versionCounter,
   triggerCount, lastActiveAt}`. **No contiene `nodeGroups` ni `description`.**
5. Los dos logs (`scripts/.drift-log/drift.log` y `drift.err.log`) **se paran el 5 ago a las 08:07**,
   con `HTTP Error 401: Unauthorized` contra la API.

Es decir: el aviso de `main` sigue vigente **precisamente para la copia que el job ejecuta**, y lo
único que ha impedido que el `--go` diario sobrescriba baselines de PROD con drift falso es que el
job lleva doce días muerto por un 401. Las dos averías se están tapando la una a la otra: el día que
se arregle el 401 sin tocar el script, el primer ciclo escribe.

## La duda

Son tres decisiones encadenadas, y ninguna es mía:

1. **¿Qué se hace con el script?** Mergear `chore/drift-baseline-post-a2`, portar el arreglo de
   `main` a `stg`, o dejarlo como está y apagar el `launchd` hasta que se decida.
2. **¿A qué copia debe apuntar el job?** Hoy apunta a la de `stg` por el sitio donde está el
   checkout, no por una decisión. Si `main` es la copia buena desde el 10 ago, el job la está
   ignorando.
3. **¿Quién repone el 401?** Es un secreto de PROD; no lo toco sin autorización escrita, y tampoco
   sé si la key caducó, se rotó o se revocó a propósito.

## Qué desbloquea cada respuesta

- **"Arregla el script y luego el 401"** → hago el port en rama propia, con el canario de
  `meaningful_diff` de `main` corriendo antes y después, y no toco la credencial.
- **"Apaga el `launchd` de momento"** → lo descargo y lo dejo escrito en `CLAUDE.md`; queda sin red
  de seguridad, cosa que hay que decir en voz alta, no dejar implícita.
- **"Déjalo como está"** → no hago nada, pero entonces el 401 **no** debe repararse antes que el
  script, y eso conviene que quede escrito en algún sitio que alguien lea antes de reponer la key.

Mientras tanto sigo la regla de la copia de `main`, que es la que ya está en el `CLAUDE.md`
unificado: **`--go` contra PROD, no**. En dry-run es inofensivo.

## Estado, para que no se lea como bloqueo

No estoy parado por esto. El encargo de la unificación está entregado y publicado en las dos ramas.
Evidencia completa en `Agente-n8n:docs/sincronizacion-n8n-github.md`, sección "Estado real del job
automático", y la trazabilidad del recorte en
`Agente-n8n:docs/2026-08-16-claude-md-unificacion-inventario.md`.
