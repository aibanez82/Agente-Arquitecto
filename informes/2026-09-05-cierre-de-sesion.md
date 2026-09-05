# Cierre de sesión — noche del 4 al 5 de septiembre de 2026

> Arquitecto-IA-Qualitas. Punto de retomada tras `/clear`.

## Lo que espera a Alberto, por orden

| # | Qué | Por qué |
|---|---|---|
| 1 | **Póliza 7620101920 — BYD SONG PLUS, 20.673,46 MXN, vence el 14 sep** | Cliente real (`armando_lobo@yahoo.com`), póliza emitida y sin pagar. Su liga de pago falló el 31 ago y **el cron está apagado**: no hay arreglo técnico que llegue a tiempo. Es el **punto 0** del plan de Juan (`#335`). `#329` |
| 2 | **Verificar el `#328` en PROD por WhatsApp** | Dos mensajes: «Puedo diferirlo a 12 meses con mi tarjeta?» y «Me lo puedes dejar a pagos chiquitos sin que me cobren de más?». El cambio está en el grafo vivo y verificado; falta la conversación real |
| 3 | **Clasificador de descuentos a PROD** | Medido 0/100 → 96/100 en STG, con el falso positivo del contado a cero. Lleva dos días parado esperando su orden. `#270`/`#313` |
| 4 | **Las 11 preguntas para Hylant** | `docs/preguntas-abiertas-para-hylant.md`. Tres desbloquean issues: la 1 (`#320`), la 4 (`#323`, la que más dinero mueve) y la 11 (`#333`) |

## Lo que se cerró esta noche, todo con medición propia

| Issue | Qué era | Acreditación |
|---|---|---|
| **`#326`** | El bot negaba los meses sin intereses **teniendo los chunks delante** | Conversación real de PROD (turno 11325) tras corregir 5 chunks en las dos bases |
| **`#320`** | Decíamos que la Limitada no cubre incendio ni inundación; las CG dicen que sí | 7/7 PASS en conversación de STG, texto literal verificado |
| **`#330`** | La KB de STG **no era la de PROD** — faltaba el chunk de topes de Asistencia Vial y los ids estaban desplazados | Las dos bases dan ahora **el mismo hash de contenido** |
| **`#328`** | El bot llamaba «sin costo extra» a un pago con **974,43 MXN de recargo** | 4/4 PASS en STG y **promovido a PROD** (`5a3308be`); falta la conversación real |

Y **el `#272` se activó en producción**: escribió sus primeras 373 identidades de recibo y 61 evaluaciones. Quedó en estado «preparado» —`REVISION_MODE=apply`, `SYNC_MODE=off`— tras una corrida controlada.

## Lo que quedó abierto, y de quién es

**Mío:** `#327` — los ~45 chunks que llegan al modelo **sin su pregunta**. Es la causa raíz del `#326` y de parte del `#292`. La propuesta está escrita: una vista `kb_chunks_rag` que concatene pregunta y respuesta, sin tocar embeddings ni reescribir filas.

**Esperando ejecutor:** `#332` (la lista de cotizaciones sale sin vehículo ni precio, y ofrece una cotización que no existe), `#333` (la KB generaliza la exclusión por licencia que las CG acotan a Uso Chofer APP), `#334` (a quien pide la cobertura mínima le ofrecemos la Amplia).

**De Juan:** `#281`, `#329`, `#305`, `#303`, `#301`. Su plan de fin de semana es el `#335`, con secuencia cronológica del carril de pagos.

## El set de 50 preguntas de cobertura, cerrado

~90 turnos, cero envíos reales, cero emisiones. Balance final tras mis dos correcciones: **B18a, C4 y D1 no eran fallos del bot**. Lo que queda vivo: deflectar teniendo media respuesta acreditada (`#292`), el enrutado de la cobertura mínima (`#334`) y un «+6 millones de autos» sin fuente.

## Los cinco errores de la noche, que valen más que los aciertos

1. **Afirmé que cuatro fallos de ligas eran «por definición recuperables»** y pedí reintento automático. Juan lo prohíbe con razón: ese código de error no dice si la llamada irreversible al proveedor llegó a empezar. Yo había corregido la premisa —el código no distingue red de bug— **pero no llegué a la consecuencia**.
2. **Di por buena una afirmación de ausencia heredada de un documento** (la exclusión por licencia). Tres manos y ningún `ILIKE`; el chunk aparecía a la primera.
3. **Mi búsqueda «ampliada» era igual de ciega que la estrecha**: probé cuatro grafías de «12:00» y todas dieron cero, porque el documento escribe `12.00`. Lo que funcionó fue **leer el pasaje entero**. Con 152 chunks, leer gana a buscar.
4. **Dije «40.562 MXN en riesgo» sin comprobar si las pólizas eran de prueba.** Alberto lo pidió y una de las dos era suya. La cifra real era 22.875,44.
5. **Publiqué dos comentarios mutilados** por meter backticks en el shell. Regla adoptada: todo comentario largo va por `--body-file`.

## Reglas nuevas que salieron de trabajar

- **Una afirmación de ausencia heredada de un documento no es una medición.** Cuando el esperado es un cero, se mide igual que cuando es un número.
- **En corpus pequeño, leer gana a buscar.** Ampliar el patrón da más confianza sin dar más alcance: el patrón siguiente lo elige el mismo sesgo que eligió el anterior.
- **Toda corrección de `kb_chunks` se aplica a los dos entornos en la misma sesión.** El `#330` demuestra qué pasa cuando no.
- **La limpieza de fixtures no debe adelantarse a la agregación del informe.** Las dos correcciones de esta noche salieron de re-medir; con las sesiones borradas se habrían quedado en pie.

Agente: Arquitecto-IA-Qualitas
