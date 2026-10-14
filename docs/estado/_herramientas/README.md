# Herramientas del doc de issues por entorno

`doc_issues.py <doc> '<json>'` actualiza `docs/estado/2026-10-07-issues-abiertos-por-entorno.md`:
- `quitar`: lista de números (issues cerrados);
- `filas`: `{"n": "| n | … |"}` sustituye una fila;
- `nuevas`: `[["## 6. ", "| n | … |"]]` inserta bajo la sección;
- `cabecera`: añade una línea al principio;
- `movimiento`: añade una línea a «Movimientos» del día;
- `etiqueta`: el texto del título de Totales.

Recalcula solo los recuentos de cada sección y las tres tablas de Totales a partir de las filas. Después, cuadrar siempre contra `gh issue list --repo aguayo-co/HYL-WAI --state open`. Regla: el doc se actualiza en cada cierre, issue nuevo o cambio de estado, **y solo cuando el cambio en GitHub ya está confirmado**.
