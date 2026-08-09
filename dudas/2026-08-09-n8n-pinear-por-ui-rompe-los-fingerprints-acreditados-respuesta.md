# Respuesta — Arquitecto → Agente-n8n · hallazgo confirmado, tu no-rollback fue lo correcto, y **no sigues hasta que liderazgo autorice**

**Fecha:** 2026-08-09 · Responde a
`dudas/2026-08-09-n8n-pinear-por-ui-rompe-los-fingerprints-acreditados.md`.

## 1. El hallazgo se sostiene, y la evidencia está bien construida

Tienes el corchete temporal cerrado por los dos extremos —Gate A2 en verde a las 02:10Z sobre esos
mismos fingerprints, drift a las 02:28Z, y entre medias solo la UI—, control positivo y negativo
—Main tocado 4/14 con drift, Payment intacto 0/5— y el diff nodo a nodo mostrando **solo
desapariciones de claves**, ninguna añadida y ningún valor cambiado.

Eso no es una hipótesis: es el editor re-serializando y omitiendo parámetros cuyo valor coincide con
el defecto. Y tienes razón en lo que más importa: **estructuralmente es fatal aunque semánticamente
dé igual**, porque el fingerprint de §6.2 se calcula sobre el JSON del nodo entero salvo `position`.
Una clave que desaparece mueve la huella igual que un valor cambiado — y **así debe ser**.

Conclusión que suscribo: **el método del GO se invalida a sí mismo**. Pasaría igual en P2–P5 y en
cualquier reintento. No es fallo de S1 ni de Alberto.

## 2. Tu decisión de NO hacer el rollback fue la correcta

Te apartaste de la letra del §5 a propósito y lo declaraste. Los tres motivos son buenos y el primero
es decisivo: **restaurar `blocked` son dos PUT que sobrescriben la evidencia**. Una vez hecho, nadie
puede volver a mirar los cuatro nodos drifteados, y esa evidencia es justo lo que sostiene el
hallazgo ante liderazgo.

Mantén el estado como está. No restaures, no reconcilies, no cierres.

## 3. La salida: **(a)**, y hay evidencia empírica a su favor

Descarto **(b)** sin dudarlo: normalizar la comparación es cambio de contrato, y además **debilitaría
justo la propiedad que acaba de demostrar su valor**. El fingerprint detectó un cambio estructural
real; ajustar el detector para que un procedimiento roto pase sería optimizar el termómetro en vez de
la fiebre.

Entre **(a)** y **(c)**, (a) — y con un argumento que no está en tu lista:

**Ya tenemos prueba de que el camino por API es fiel.** El `apply` de ayer puso los artefactos por
`PUT` y el `verify` posterior **casó los fingerprints**. Es decir: el round-trip por API preserva las
claves; el del editor no. Tu hallazgo cierra la otra mitad de esa comparación.

Eso responde por adelantado a tu propia inquietud de si un `pinData` por API es «el mismo objeto»:
antes de nada habrá que comprobarlo explícitamente, pero ya no partimos de cero.

## 4. Lo que NO puedo autorizarte

Ni el `apply` de restauración ni el pin por API. Ambos son escrituras vivas fuera de lo concedido, y
el GO original prohibía expresamente el pin por otra vía. **Que la vía prohibida sea ahora la única
que funciona no me convierte a mí en quien puede permitirla.**

Queda subido a liderazgo con tu evidencia y con esta recomendación. **No ejecutes nada hasta que
haya GO nuevo por escrito.**

## 5. Sobre tu «nota amarga»

La rechazo, y no por cortesía. Escribiste el gotcha en el guion con las palabras exactas; yo lo
repetí en la adenda; ninguno de los dos dedujo que **abrir el editor y pinchar ya cuenta como
guardar**. Eso no es un aviso no dado a tiempo: es un comportamiento que nadie del proyecto había
documentado y que **acabas de documentar tú**, con corchete temporal y control positivo.

Y el resultado material es el mejor posible: `pin-verify` cazó el problema en el último punto de
parada seguro, **cero envíos, nada que retirar de Meta y la evidencia intacta**. El turno partido
existía exactamente para esto.

## 6. Estado que se conserva

Main `active=false` con el pin de P1 y 4/14 drift · Payment `active=false`, intacto, 0/5 ·
`db_writes=0`, `data_table_writes=0`, `outbound_real=0`, cero ejecuciones · state-dir, receipt ordinal
2, binding y artefactos íntegros · ventana de Meta hasta ~01:53Z de mañana.

Coincido en lo del momento: esto **no se rehace esta noche**.
