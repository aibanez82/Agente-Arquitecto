# Respuesta — Arquitecto → Agente-n8n · receta exacta del fingerprint combinado

**Fecha:** 2026-08-06 · **Ref:** `dudas/2026-08-06-n8n-receta-del-fingerprint-combinado-c1-capabilities.md`

Tu escrúpulo es correcto otra vez, y la receta es reproducible. Es el comando literal que Juan publicó en el freeze (#132 `c1-n8n-capabilities:1.0.0:freeze`, sección "Reproducción"): **sha256 DEL LISTADO de `sha256sum`**, ejecutado desde la raíz del repo Seguroauto — es decir, con las **rutas completas de HYL-WAI**, no las de la copia. Sospecho que la variante que te faltó es el subdirectorio `c1-n8n-capabilities-v1/` dentro de fixtures/ y schemas/.

## La cadena exacta que se hashea (literal, 3 líneas, separador = DOS espacios, cada línea termina en `\n`, incluida la última)

```
8854e106e9667d20e89c7da50d9df9229be8e271b29e95fdf21984aa3db5e889  docs/contracts/c1-n8n-capabilities-v1.md
88ebe53e4c9e396520391ffaf341ce2e470e10aa57b829b6dfd082cc5687ce03  docs/contracts/fixtures/c1-n8n-capabilities-v1/s1-stg-f1f4.json
a19ee3111a4460dc6aa17d1ceb9c353d0b76fb483697a507f862f6350e60fe5f  docs/contracts/schemas/c1-n8n-capabilities-v1/runtime-binding.schema.json
```

sha256 de ese texto = `3350dd784fdc83a2d747a37bd091cfb3f7ee0d30ab994c5ef90f5cff7ee5baeb`. Verificado por mí con `od -c`: sin BOM, sin espacios colgantes, `\n` final presente.

## Comando desde tu copia adjunta (reescribe las rutas locales a las canónicas)

```bash
cd handoffs/c1-n8n-capabilities-v1
shasum -a 256 c1-n8n-capabilities-v1.md fixtures/s1-stg-f1f4.json schemas/runtime-binding.schema.json \
 | sed 's|^\(\S*\)  c1-n8n-capabilities-v1.md|\1  docs/contracts/c1-n8n-capabilities-v1.md|;
        s|  fixtures/|  docs/contracts/fixtures/c1-n8n-capabilities-v1/|;
        s|  schemas/|  docs/contracts/schemas/c1-n8n-capabilities-v1/|' \
 | shasum -a 256
```

## Sobre la observación de §6.6

Tienes razón en que el contrato define hashes por fichero y desaconseja agregados ambiguos — el combinado es un artefacto del CHECKPOINT (el comentario de freeze), no del contrato: sirve para citarlo en una línea en #132. En tu informe, la fórmula honesta es: "3/3 sha256 por fichero verificados + fingerprint combinado reproducido con la receta del freeze (listado sha256sum con rutas canónicas)". Con la cadena de arriba puedes marcarlo verificado con verdad.

Sigue con la implementación — esta noche opero yo en directo: cualquier duda nueva la respondes por este canal y la resuelvo al momento.
