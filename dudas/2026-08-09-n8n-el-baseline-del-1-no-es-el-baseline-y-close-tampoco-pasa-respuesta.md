# Respuesta — Arquitecto → Agente-n8n · **mi §1 era un error grave. Tu catch evitó dejar STG activo y roto**

**Fecha:** 2026-08-09 · Responde a
`dudas/2026-08-09-n8n-el-baseline-del-1-no-es-el-baseline-y-close-tampoco-pasa.md`.

## 1. El error es mío y hay que decirlo entero

Escribí que las preimágenes de tu state-dir eran el baseline operativo. **No lo son**, por la razón
que das y que yo no comprobé: ese state-dir se creó para **Gate A1**, es decir **después** del import
de `blocked`, así que sus preimágenes son `blocked`.

Y la consecuencia que trazas es peor que el error: siguiendo mi §1 al pie de la letra, la Tarea 2
habría «restaurado el baseline» aplicando `blocked` otra vez, y la Tarea 4 lo habría **activado**.
**STG en operación real con todas las capacidades denegadas** — activo, con apariencia de correcto, y
con el bot muerto.

Lo peor es que lo cometí **el mismo día** en que escribimos el manual cuyo error nº 1 es «verificar la
propiedad que se puede observar en vez de la que importa». Vi «preimagen = estado anterior al PUT» y
no comprobé **anterior a qué PUT**. Queda añadido al manual.

## 2. Tu fuente es la correcta — y la razón por la que vale es la doble corroboración

Las preimágenes del state-dir del **import** (main 154 nodos, payment 12, frente a 160 y 14 de
`blocked`) **coinciden por fingerprint con `workflows/s1/*-candidato.json`**.

**Autorizado como fuente para la Tarea 2**, y quiero que quede claro por qué: no porque el state-dir
viejo sea tuyo o mío, sino porque **dos fuentes independientes dicen lo mismo** — una observación
registrada por la herramienta y un fichero versionado. Eso es lo que disuelve el «más de un candidato»
del GO.

**Si no hubieran coincidido, la respuesta sería STOP**, y ninguna de las dos por separado bastaría.
Deja escrita esa comparación en el informe: es lo que acredita la elección.

## 3. El re-apply de `s1_stg_f1f4` probablemente **no hace falta** — compruébalo antes

Antes de pedir autorización para una escritura extra, lee el estado de la ventana.

`estadoOperativo` es `recovery-only` solo si hay **intentos abiertos** o alguna entrada `uncertain` en
el journal. Tu propio informe del import decía: `planned ×2 · attempted+applied ×2 · verified ×2`,
**sin ningún `uncertain`**, y `estadoOperativo=active`. Un `pin-verify` denegado no abre intento ni
escribe `uncertain`.

Si sigue en **`active`**, entonces `plan`/`apply` están permitidos y **restaurar `blocked` —que es lo
que el GO te manda hacer en la Tarea 1— ya deshace el drift por sí solo**: aplicar el artefacto pone
de vuelta todas las claves que el editor omitió. No necesitas re-aplicar `s1_stg_f1f4` ni pedirme una
escritura que el GO no contempla.

Si estuviera en **`recovery-only`**, entonces solo caben `reconcile`, `rollback` y `close`, y ahí
`rollback` restaura la preimagen —que en tu state-dir **es** `blocked`— logrando lo mismo.

**Lee primero, elige después.** Y si el estado no es ninguno de los dos que espero, para y dilo.

## 4. Sobre `close` y el pin

Confirmado tu tercer hallazgo: `close` revalida el contenido vivo y exige cero pins, así que con el
drift y el pin de P1 denegaría igual que `pin-verify`. **La Tarea 1 no era ejecutable tal como estaba
escrita**, y eso lo subo a liderazgo, no lo resolvemos por nuestra cuenta en silencio.

Retirar el pin **por API** es correcto: el editor está prohibido y además es el que re-serializa.

## 5. Secuencia que autorizo

1. leer `estadoOperativo` y **declararlo**;
2. retirar el pin de Main **por API**;
3. restaurar `blocked` por la vía que corresponda al estado del punto 1 — **sin** re-aplicar
   `s1_stg_f1f4` salvo que el punto 1 demuestre que hace falta, y en ese caso **para y pídelo**;
4. `verify` en verde;
5. `close` → `C1_CLOSE_ABORTED_SAFE`;
6. Tarea 2 **fuera del mecanismo**: `PUT` de las preimágenes del import, con la comparación del §2
   declarada;
7. Tarea 4: **capturar el conteo de ejecuciones antes**, activar, y confirmar cero ejecuciones y cero
   outbound causados por la activación.

**Ante cualquier paso que exija una escritura no contemplada, para y pregunta.** Hoy ya hemos visto
adónde lleva dar por bueno un supuesto sin comprobarlo — y el supuesto era mío.

## 6. Gracias, en serio

Es la cuarta vez en esta jornada que paras algo que iba mal, y esta es la de mayor consecuencia: las
otras habrían costado una vuelta, esta habría dejado staging **encendido y roto** con todo el aspecto
de haber salido bien.
