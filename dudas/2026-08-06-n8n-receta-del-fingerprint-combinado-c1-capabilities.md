# Duda — Agente-n8n → Arquitecto · la receta exacta del fingerprint combinado `3350dd78…`

**Fecha:** 2026-08-06 · **Ejecutor:** Agente-n8n
**Qué ejecuto:** `handoffs/2026-08-06-c1-capabilities-implementacion.md` (`GO_ALBERTO_OFFLINE`).
**No estoy bloqueado:** la verificación de fondo pasó y sigo con la implementación. Esto solo
afecta a poder marcar como verificado el dígito combinado en mi informe.

## Lo que sí verifiqué

Los tres artefactos de la copia adjunta son **byte a byte idénticos** a los sha256 que publicas:

| artefacto | sha256 | resultado |
|---|---|---|
| `c1-n8n-capabilities-v1.md` | `8854e106…5889` | coincide |
| `fixtures/s1-stg-f1f4.json` | `88ebe53e…ce03` | coincide |
| `schemas/runtime-binding.schema.json` | `a19ee311…0fe5` | coincide |

Esa es la garantía sustantiva y está en verde: la copia no ha derivado respecto a
`aguayo-co/HYL-WAI@6e40a715`.

## Lo que no puedo reproducir

El **fingerprint combinado `3350dd784fdc83a2d747a37bd091cfb3f7ee0d30ab994c5ef90f5cff7ee5baeb`**.

Su única definición es el paréntesis del handoff — *«orden §: md, fixture, schema → sha256 del
listado»* — y «listado» no queda especificado: no dice si lleva rutas, cuáles, con qué separador,
ni si termina en salto de línea. Probé del orden de cien combinaciones y ninguna lo da:

- hexes concatenados sin separador, con `\n`, con `|`, con `,`; con y sin salto final;
- formato `shasum`/`sha256sum` (`hash␣␣ruta`) con un espacio, dos, tabulador, `|` y `:`;
- rutas en cuatro formas: solo basename, relativas al directorio del contrato, relativas al repo, y
  bajo `docs/contracts/`;
- hexes en mayúsculas.

Tampoco está la receta en ningún otro sitio: **§6.6 del propio contrato define hashes por fichero y
dice expresamente «nunca un hash agregado ambiguo»**, y el valor solo aparece en tu handoff. Ni el
contrato ni el schema ni el fixture lo mencionan.

## Lo que pido

**La cadena exacta que se hashea**, literal, con sus separadores y su final de línea — o el comando
con el que lo generaste. Con eso lo reproduzco y lo doy por verificado en el informe.

## Por qué no lo doy por bueno sin más

Los tres hashes coinciden, así que el riesgo real es nulo y sería fácil escribir «fingerprint
verificado» y seguir. No lo hago: tu handoff lo pone como **primer paso obligatorio**, y declarar
verificado algo que no he podido calcular es precisamente el tipo de verde forzado que llevo toda
la ronda evitando. Prefiero dejarlo dicho y que el informe diga la verdad: 3 de 3 artefactos
verificados, combinado pendiente de receta.

Si resulta que el combinado no es reproducible por diseño (p. ej. lo calculaste sobre los ficheros
originales con otras rutas), con que me lo confirmes basta y lo consigno así.
