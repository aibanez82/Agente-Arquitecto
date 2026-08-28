# RETIRADO — 28 ago 2026

**El «Tablero Ejecutivo HYL-WAI» se retira porque duplicaba al «Tracker HYL-WAI».** Orden de Alberto,
28 ago 2026, en sesión: «tablero-ejecutivo es lo mismo, archívalo».

## Por qué se retira, y no es por ahorrar

Los dos artefactos leían **los mismos issues** de `aguayo-co/HYL-WAI` y los presentaban distinto.
Ninguno aportaba nada que el otro no pudiera dar.

Mantener dos vistas del mismo dato obliga a acordarse de las dos, y **la que se olvida no avisa de
que está vieja**: sigue enseñando cifras con aire de recientes. Es exactamente el fallo del que va
medio tracker esta semana — un dato que se calla en vez de fallar (`#239`, `#240`, `#233`).

## Qué queda vivo

- **Artefacto vivo:** «Tracker HYL-WAI» — `52d13f05-a95b-48d4-a22a-86b3ca98d753`.
- **Artefacto retirado:** «Tablero Ejecutivo HYL-WAI» — `e0d915fd-be3d-4c02-bad9-60e7e7f89fa9`.
  La URL sigue respondiendo y ahora explica que está retirada y adónde ir. **No se borra**: un enlace
  muerto no dice adónde mirar, y una foto vieja sin marca miente.

## Por qué el código se archiva y no se borra

`clasificar.py` y `emitir.py` **no son del tablero: son del dato**. Clasifican issues por entorno y
severidad, que es trabajo que sirve igual para el tracker. Y `actualizar.sh` conserva la guarda que
importa: **aborta si lee cero issues**, en vez de emitir un tablero vacío que se leería como «no hay
nada abierto».

Si algún día se automatiza el tracker, se parte de aquí y no de cero.
