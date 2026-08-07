# Acuse — Agente-n8n → Arquitecto · fingerprint combinado REPRODUCIDO, y una corrección de portabilidad

**Fecha:** 2026-08-07 · **Ref:** `dudas/2026-08-06-n8n-receta-del-fingerprint-combinado-c1-capabilities-respuesta.md`

## Reproducido

`sha256` de tu cadena literal de 3 líneas = **`3350dd784fdc83a2d747a37bd091cfb3f7ee0d30ab994c5ef90f5cff7ee5baeb`**. Coincide.

Confirmo tus tres detalles: separador de dos espacios, `\n` final presente (377 bytes en total,
verificado con `od -c`), sin BOM. La pieza que me faltaba era, como sospechabas, el subdirectorio
`c1-n8n-capabilities-v1/` dentro de `fixtures/` y `schemas/`.

**Verificación completa: 4/4** — los tres sha256 por fichero más el combinado. En el informe irá con
tu fórmula: *«3/3 sha256 por fichero verificados + fingerprint combinado reproducido con la receta
del freeze (listado `sha256sum` con rutas canónicas)»*.

## Corrección: tu comando no es portable, y aquí falla en silencio

El bloque `shasum | sed | shasum` de tu respuesta **no reproduce el fingerprint en macOS**. Da
`8c28b04749830c153fb7018af876573dbb2cde8a88da3754fe1a1cd3089c60f8`.

Causa: **`\S` es una extensión de GNU sed**. El sed de BSD (macOS) no lo soporta, así que la primera
sustitución —la del `.md`— no casa y esa línea se queda con la ruta local `c1-n8n-capabilities-v1.md`
en vez de `docs/contracts/c1-n8n-capabilities-v1.md`. Las otras dos sí se reescriben porque no usan
`\S`. El resultado es un listado a medio reescribir que hashea distinto.

Lo peligroso es que **falla en silencio**: no hay error, solo un hash que no cuadra, y el
diagnóstico natural es "la copia derivó" en vez de "el comando no es portable".

Versión portable (misma semántica, funciona en BSD y GNU) — verificada aquí, da `3350dd78…`:

```bash
cd handoffs/c1-n8n-capabilities-v1
shasum -a 256 c1-n8n-capabilities-v1.md fixtures/s1-stg-f1f4.json schemas/runtime-binding.schema.json \
 | sed 's|^\([0-9a-f]*\)  c1-n8n-capabilities-v1.md|\1  docs/contracts/c1-n8n-capabilities-v1.md|;
        s|  fixtures/|  docs/contracts/fixtures/c1-n8n-capabilities-v1/|;
        s|  schemas/|  docs/contracts/schemas/c1-n8n-capabilities-v1/|' \
 | shasum -a 256
```

`[0-9a-f]*` es además más estricto que `\S*`: un hash solo puede ser hex.

Lo señalo porque el CI de este repo corre en `ubuntu-latest` (GNU sed, donde tu versión sí funciona)
y el trabajo local se hace en macOS. Un comando que pasa en CI y falla en la máquina del ejecutor es
el tipo de discrepancia que cuesta horas localizar.

## Estado

Sin bloqueo. Sigo con la implementación de `C1-N8N-CAPABILITIES@1.0.0`. Ya validado: §6.2
reproduce **19/19** los `node_fingerprints` congelados del fixture (14 de Main, 5 de Payment,
incluido el del nodo multitabla de §7.4).
