# Informe de ventana — Retomar Conversación promovida a PRODUCCIÓN

**13 ago 2026 · Agente n8n · ejecutada. Pendiente de tu acreditación.**

Handoff `2026-08-13-ventana-retomar-conversacion-EJECUTAR.md`. Autorizó Alberto y lo confirmó en el
chat antes del `PUT`. Registro completo en `Agente-n8n:docs/fase4/1-retomar-conversacion.md` §0
(`docs/fase4-preparacion@11aa76b`).

## Lo primero, porque vas a verlo al acreditar

**Mi guion abortó con `aparecio una referencia a WA Config STG (Bug #15)` y escribió `REVERTIR ya`. Es
un FALSO POSITIVO de mi propio guard. No hay Bug #15 y no se revirtió nada.**

El guard hacía `'WA Config STG' in json.dumps(workflow)`. El `jsCode` que se promueve **menciona
`WA Config STG` en dos líneas de comentario** — y copiarlo byte a byte, comentarios incluidos, era una
decisión escrita y que tú aprobaste en el §1 de tu handoff. **Escribí una comprobación que contradice
una decisión escrita en el mismo fichero**, así que el guion abortó por cumplir su propio plan y encima
empujaba a deshacer algo correcto. Si hubiera obedecido a mi salida, habría revertido un cambio bueno en
producción.

Te lo digo antes de que acredites porque **vas a encontrar esa cadena en la instancia** y el §4③ de tu
handoff no la contempla: está en un comentario del `jsCode`, no en un nodo ni en una expresión.

## Estado, medido campo a campo contra el retrato antes de decidir nada

**Una sola diferencia en todo el workflow, y es la esperada.**

| | Resultado |
|---|---|
| nodos | **12**, ninguno añadido ni perdido |
| `active` | **true** |
| `versionId` | `a83ec90c-ab83-4b8f-bbeb-2fbc1c01535a` → **`fa42a9b4-f0d9-4491-bebf-96d16023d8b5`** |
| `webhookId` `Webhook` | `afd2b47d-bd99-4525-93a6-42764b8f56df` — **intacto** |
| `webhookId` `Send message` | `fd3be604-82e2-4806-89fa-ffc8f7b01969` — **intacto** |
| `Normalize & Validate.jsCode` | 1 338 → **10 169**, **byte a byte idéntico al de STG**, **cero** referencias `$('...')` |
| `connections` / `settings` | **idénticos** al retrato |
| otros 11 nodos | **sin un solo cambio** de parámetro, tipo, `typeVersion`, credencial ni posición |
| ¿nodo `WA Config STG`? | **no existe** |
| `Send message.phoneNumberId` | `={{ $('WA Config').first().json.waPhoneNumberId }}` — el de PROD |

Tus tres criterios (①②③) los cumple. Y los mido yo para tenerlo escrito, no para sustituir tu lectura:
quien despliega no acredita, y hoy esa regla acaba de justificarse otra vez — con mi propio guard como
el que se equivocó.

## El arreglo, ya hecho

`fuga_de_staging()` sustituye la búsqueda de texto por las **dos únicas formas que serían el Bug #15 de
verdad**: un **nodo** llamado `WA Config STG`, o una referencia **`$('…STG…')`** en una expresión. Un
comentario no ejecuta nada. Probado contra el PROD vivo (**cero fugas**) y contra un caso deformado a
propósito, donde detecta las dos.

**El mismo defecto estaba en `promover-atencion-humana.py`** y queda corregido ahí también, antes de que
la promoción 2 tropiece con lo mismo. Lo arreglé **después** del `PUT`, no durante: nada se arregla con
una ventana abierta.

## Dos cabos menores, dichos en vez de callados

1. **Lancé el guion con `| tee` y la shell reportó `0` cuando el guion salió `1`.** No cambió ninguna
   decisión —leí la salida entera— pero en una ventana el código de salida **es** una señal y la anulé
   sin darme cuenta. Sin `tee`, o con `PIPESTATUS`.
2. **`settings` sobrevivió intacto**, incluidos `binaryMode` y `availableInMCP`, que el `PUT` **no**
   manda por la allowlist. n8n los conserva del lado del servidor en vez de borrarlos — o sea que la
   allowlist protege del HTTP 400 **sin coste de pérdida**, que es mejor de lo que asumíamos.

## Lo que NO está acreditado

Que el workflow **quedó bien escrito** ≠ que **funciona**. Falta el mensaje proactivo real desde el
Dashboard de producción, que manda Alberto y cuya fila en `n8n_chat_histories` confirmas tú.

## Y un paso de ventana que sigue pendiente y no es mío

El export de `main` (`workflows/Retomar Conversacion.json`) **ya no describe a PROD**: `detect-drift.py`
dará drift en ese destino, correctamente. Lo levanté en la preparación y sigue igual — no lo he tocado
porque el handoff de la Fase 4 prohíbe empujar a `main`. Hace falta o tu OK para actualizarlo, o
declararlo como drift esperado hasta que se integre la rama.
