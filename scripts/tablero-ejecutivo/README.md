# Tablero ejecutivo del tracker HYL-WAI

Vista ejecutiva de los issues abiertos de `aguayo-co/HYL-WAI`, agrupados **por lo que compran
para el negocio** en vez de por sistema.

**Artefacto publicado:** <https://claude.ai/code/artifact/e0d915fd-be3d-4c02-bad9-60e7e7f89fa9>

## Actualizar

```bash
scripts/tablero-ejecutivo/actualizar.sh
```

Genera el HTML. Para que llegue a la página, hay que **republicarlo en esa misma URL** — lo hace el
Arquitecto pidiéndoselo («actualiza el tablero»), o cualquiera con el fichero y la URL.

## Qué es derivado y qué es real

| Columna | Origen |
|---|---|
| número, título, asignado, criticidad, fechas | **Reales**, del tracker |
| sistema | Real, de las etiquetas `sistema:*` |
| **área / caso de negocio** | **Derivada**: la clasifico yo por palabras del título y el cuerpo |
| **entorno** (PROD / STG / ambos) | **Derivada**: el tracker no lleva entorno |
| edad, quieto | Calculadas de `createdAt` / `updatedAt` |

**Las dos derivadas son el punto débil y hay que saberlo.** GitHub no lleva ni área ni entorno, así
que **nadie más puede reproducir esa clasificación**: depende de los patrones de `clasificar.py`.
El día que existan como etiquetas en el tracker, este mapeo se retira y la vista lee el dato real.
Mientras tanto, un issue mal clasificado es un issue que aparece bajo el epígrafe equivocado — no se
pierde, pero engaña.

## Por qué no es una página viva

No consulta GitHub, y no es un descuido:

- el repositorio es **privado** y una página publicada no puede llevar credenciales;
- una página publicada tiene **bloqueadas las llamadas a hosts externos**;
- no hay conector de GitHub disponible para el runtime de artefactos.

Lo que sí hace: **la página sabe de qué día son sus datos y lo dice.** A partir de dos días avisa en
ámbar; a partir de siete, en rojo. Si no puede estar viva, que al menos no aparente estarlo — la
lección del Dashboard, que estuvo una semana pintando conciliación del 18 de agosto sin advertirlo.

## Guardas

`actualizar.sh` **aborta si lee cero issues**. Un tracker vacío y una lectura fallida (token caducado,
sin permisos) se ven exactamente igual desde dentro, y la diferencia importa.

## Ficheros

| | |
|---|---|
| `actualizar.sh` | El único comando que hace falta |
| `clasificar.py` | Deriva área, entorno, criticidad, edad y resumen. **Aquí viven los patrones** |
| `emitir.py` | Genera el HTML: KPIs, secciones por área y el aviso de frescura |
