# Promoción a PROD — `#409` DENTRO, y paro antes de `#338`/`#256` por un bloqueo de acreditación

**De:** Agente n8n · **Para:** Arquitecto · **Fecha:** 18 sep 2026
**Responde a:** handoff `origin/main:handoffs/2026-09-18-promocion-338-256-409-a-prod.md` (`e23e9067`)

## Paquete 1 · `#409` — HECHO en PROD
Construido sobre la línea base viva de PROD (respaldo citado `scripts/409/respaldos-prod/prod-bot-baseline-de20a75c…json`).
`onError: continueRegularOutput` en `Increment KB Counter`, `Update Out of Scope in DB`,
`Increment Image Counter`. Verificado post-PUT: 330 nodos, **solo esos 3 cambian `onError`**, cero
cambios de `parameters`/`connections`, credencial `Postgres account` intacta, **cero rastro de STG**.
**PROD `eccf76e4`** = export en `origin/main` (`99dee112`). Espejo fiel.

## Por qué paro aquí: no puedo acreditar el comportamiento en PROD con mis medios

Tu handoff pide dos verificaciones **en PROD** que dependen de generar u observar tráfico:
1. `#409`: «fuerza el fallo de un contador y enséñame que el cliente recibe igual, **con tráfico sintético**».
2. `#338`: «verifica en PROD que los seis nodos de abajo **siguen sin ver** la observation».

**Las dos exigen una ejecución del bot en PROD, y no puedo inyectar tráfico sintético en PROD:** el
`WhatsApp Message Trigger` valida `X-Hub-Signature-256`, y **no tengo `PROD_WA_APP_SECRET`** para
firmar el webhook (solo `PROD_WA_ACCESS_TOKEN`, que es para salientes). Es la misma carencia que
anoté en el `#292`. En STG sí pude porque ahí tengo `STG_WA_APP_SECRET`.

**No lo suplo forzando el fallo sobre tráfico real:** eso usaría a un cliente de verdad como conejillo
—su contador no subiría y correría por un nodo roto—; con `onError` recibiría, pero no es algo que
haga en producción sin necesidad.

**Y por eso no sigo con `#338`:** meterlo sin poder verificar el despojo en PROD sería arriesgar una
regresión del `#261` (URLs fabricadas) sin red, y tú marcaste esa verificación como «la parte crítica
del viaje». El `#256` va detrás del `#338` por tu orden, así que también espera.

El `#409` ya está dentro y es seguro: es defensivo y solo mejora el comportamiento ante fallos.

## Cómo desbloqueamos (elige)

- **(a) — mi recomendación, y la más rápida:** me pasas `PROD_WA_APP_SECRET` **por tu terminal**
  (`printf 'export PROD_WA_APP_SECRET=%s\n' '<valor>' >> .env` con `read -s`, nunca en el chat).
  Con él genero tráfico sintético firmado a un número de prueba de PROD y te traigo el control del
  `#409` y la verificación del despojo del `#338`, y sigo con los dos paquetes.
- **(b)** acreditamos con **tráfico real observado**: armo un vigía que capture la primera ejecución
  de PROD que ejerza cada caso (un contador que falla y aun así responde; una consulta KB sin fuga de
  observation). Es fiel pero no es «ahora»: depende de que pase en producción.
- **(c)** aceptas el par de STG (`51853`/`51864`) + la verificación **estructural** en PROD (`onError`
  presente, que ya te dejo confirmado) como acreditación del `#409`, y seguimos con `#338`/`#256`
  cerrando su verificación de comportamiento por la vía (b) cuando haya tráfico.

Dime cuál y sigo. Si es (a), avísame cuando el secreto esté en `.env` y arranco.

— Agente n8n
