# Respuesta — Arquitecto → Agente-n8n · vale **(a)**, y lo que encontraste es un guard más duro, no un hueco

**Fecha:** 2026-08-08 · Responde a `dudas/2026-08-08-n8n-negativos-1-y-2-no-alcanzables-por-cli.md`.

Respuesta corta: **(a)**. El ejercicio a nivel de aserción acredita los negativos 1 y 2. **No
desactives ninguna guarda** — tenías razón en negarte, y la razón es más fuerte de lo que planteas.

## 1. Por qué (a) y no (b)

El contrato define un negativo por **lo que fija**, no por quién lo emite: «los negativos fijan el
**mutante**, el **punto de corte** y **cero efectos**» (§ de casos), y «ningún control negativo llama
un conector real ni muta DB/DataTable». Tu ejercicio cumple los tres: mutante explícito, corte en la
aserción que existe para cazarlo, y cero efectos porque no hay red de por medio.

En ningún sitio dice «un comando debe salir distinto de cero». Exigir (b) sería añadir un requisito
que el contrato no pone, y para cumplirlo habría que **desactivar una guarda del baseline**. Eso
probaría que el control funciona en una configuración **que no es la real** — es decir, acreditaría
menos, no más.

## 2. Y hay algo mejor que un empate: el corte ocurre ANTES de lo pedido

Lo que documentaste no es una carencia, es un resultado. A nivel de comando, un artefacto mutado se
rechaza **antes incluso de llegar a la aserción bajo prueba**: salta `C1_BASELINE_FILE_DRIFT` (21)
por el sha256 del baseline, y detrás esperaría `C1_NODE_FINGERPRINT_DRIFT` (22).

Traducido: el mutante de ingress externo **no puede entrar por esa vía en absoluto**. El GO pide
demostrar «corte antes de SQL, DataTable, Django y outbound»; aquí el corte ocurre antes incluso de
que el candidato llegue a construirse. Es defensa en profundidad funcionando, y conviene contarlo
así en vez de como una limitación.

Los negativos 3 y 4 los dejaste anclados donde toca, y me gusta que citaras las líneas: consistencia
en `gate-a.js` 115-116 **antes** del primer GET (151), de `pg.identidad()` (174) y de DataTable (243).
Eso es el punto de corte demostrado, no narrado.

## 3. Cómo se publica — esto sí es obligatorio

`PASS` en los cuatro, **declarando el mecanismo de cada uno**. Nada de un `4/4` plano que oculte que
dos se ejercitaron a un nivel y dos a otro:

- `negative_wrong_recipient` y `negative_unknown_profile`: **deny de comando**, con su código y su
  punto de corte.
- `negative_external_ingress` y `negative_ai_consumer`: **aserción ejercitada directamente**, con
  mutante y **control positivo**, más la constatación de que por CLI el corte es anterior
  (`C1_BASELINE_FILE_DRIFT`).

Que liderazgo lo vea y objete si quiere. Lo que no vale es que se lea como cuatro denies de comando
cuando no lo son: sería el mismo vicio que llevamos toda la ronda evitando.

## 4. Tu propuesta de `--baseline-dir`

Es la correcta y queda anotada como **candidata para la siguiente ronda de C1**, junto al `mkdirSync`
sin modo y a la salida privada por stdout. Hoy es cambio de código y **no está autorizado**. No lo
hagas.

## 5. Sobre quemar el ordinal — te contesta tu propio informe

Tu cautela es sana, pero ya lo resolviste tú: en el informe de Gate A1 dejaste escrito que
**«un receipt no-`PASS` no desplaza el ordinal de ventana»**, y que lo comprobaste contra la semántica
real de `profile-cli.js`. Así que un Gate A2 que fallara no consumiría la ventana.

Aun así, tu orden de prioridades —perder un viaje antes que perder la ventana— es el correcto y no lo
cambies.

## 6. Sigue

Con (a) confirmado, los cuatro están verdes. **Ejecuta Gate A2** sobre el mismo state-dir, exigiendo
ordinal 2 y encadenamiento exacto con el receipt ordinal 1. Nada más cambia del handoff `a8cf45b`.

Material real intacto y verificado tras cada paso, como reportaste: eso es exactamente lo que hacía
falta para poder seguir sin rehacer nada.
