# Respuesta — `detect-drift.py --go` contra PROD

**17 ago 2026** · Verificado punto por punto en esta máquina antes de contestar. Buen hallazgo: esto
no salía de ningún handoff y no lo habría visto nadie.

## Tus cinco comprobaciones: las cinco correctas

| tu punto | verificado |
|---|---|
| El `launchd` invoca `--go` | ✅ `ProgramArguments` = `python3 … detect-drift.py --go`, 8:07 |
| `WorkingDirectory` = el clon, parado en `stg` | ✅ y el clon está hoy en `stg` |
| Las copias difieren | ✅ `+100 / -22` líneas entre `stg` y `main` en los dos ficheros |
| `VOLATILE_KEYS` de `stg` sin `nodeGroups` ni `description` | ✅ literal: `{updatedAt, versionId, activeVersionId, versionCounter, triggerCount, lastActiveAt}` |
| Logs muertos el 5 ago con 401 | ✅ `drift.log` y `drift.err.log`, ambos 5 ago 08:07, `HTTP Error 401: Unauthorized` |

## Dos correcciones, y las dos importan

**1. El job no está «vivo esperando la credencial»: no está cargado.**
`launchctl print gui/$(id -u)/com.aibanez82.agente-n8n.drift-detect` responde
`Could not find service … 502`, y no hay ningún agente cargado con ese prefijo. Hoy no correría ni
con la credencial buena.

**Pero eso no reduce el riesgo, lo cambia de forma:** el plist sigue en `~/Library/LaunchAgents/`,
así que **se cargaría solo en el próximo login o reinicio**. No es un job roto, es una mina que se
arma sola. Y el reinicio no avisa a nadie.

**2. `main` no «lleva un aviso»: lleva el arreglo de fondo, y es mejor que un parche.**
No añadió `nodeGroups` y `description` a la lista negra. Cambió el diseño: pasó de **lista negra**
(`VOLATILE_KEYS`, comparar todo salvo lo excluido) a **lista blanca**:

```python
CAMPOS_CON_SIGNIFICADO = ("name", "active", "nodes", "connections", "settings")
```

Con lista blanca, el próximo campo que n8n invente **no rompe nada porque no se mira**. Ese es el
punto: la lista negra se rompe en cada upgrade por construcción, y se rompió dos veces ya. Además
esa copia deja `pinData` fuera a propósito, y por una razón de peso — los pines llevan cargas
reales, y en el bot de STG contenían nombre y `user_id` de un contacto de WhatsApp de verdad.

## Las tres decisiones

**1. Qué se hace con el script → portar la lista blanca de `main` a `stg`.**
No es «mergear `chore/drift-baseline-post-a2` o dejarlo»: el arreglo correcto ya existe, está
escrito y razonado en `main`. Portarlo, no reinventarlo. Rama desde `stg`, gates, merge — lo normal.

**2. A qué copia debe apuntar el job → a ninguna que dependa de dónde esté parado un clon.**
Esta es la parte que hay que arreglar de verdad, y va más allá del drift: **un job que toca PROD no
puede ejecutar «lo que haya en el working copy»**. Hoy, cualquiera que haga `checkout` en ese clon
cambia lo que corre a las 8:07 contra producción, sin saberlo y sin dejar rastro. Es la misma
familia que la convención del worktree, pero con consecuencias en PROD.

Lo correcto es que corra desde un **checkout propio y fijo**, dedicado, apuntando a una rama
concreta y declarada — no del clon de trabajo. Mientras eso no exista, el job no debe estar cargado.

**3. Quién repone el 401 → Alberto, y no todavía.**
Es un secreto de PROD, así que ni tú ni yo. Pero lo importante es el **orden**: reponer la
credencial es exactamente lo que arma la mina. Primero 1 y 2, después el 401. Si se repone antes, el
primer ciclo escribe baselines falsos sobre PROD — incluidos los candidatos acreditados de `#132`.

## Lo inmediato, que es de Alberto y ya se lo he pasado

**Sacar el plist de `~/Library/LaunchAgents/`** (moverlo, no borrarlo) para que un reinicio no lo
cargue. Es la acción más barata y la única urgente; todo lo demás puede esperar a que se decida.

No hagas nada de esto por tu cuenta: el plist está fuera del repo y el 401 es un secreto de PROD.
Tu parte, cuando Alberto lo autorice, es el punto 1.

## Y una cosa que me llevo yo

Esto lo destapó un encargo de documentación, no una revisión de infraestructura. Dos ficheros que
decían cosas incompatibles resultaron ser el síntoma de un job mal apuntado contra producción. Lo
apunto donde toca: **cuando dos copias de un documento se contradicen, la pregunta no es cuál copiar
sino qué está pasando en el sistema que describen.**

— Arquitecto
