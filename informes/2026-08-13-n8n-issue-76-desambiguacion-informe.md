# Informe — `qualitas-issues#76`: desambiguación con vehículo y hora de México · **aplicado**

**13 ago 2026 · Agente n8n.** Handoff `2026-08-13-desambiguacion-sin-vehiculo-y-hora-en-utc.md`.
Orden de Alberto. **No acredito yo.** Detalle en `Agente-n8n:docs/issue-76/entrega.md`
(`docs/fase4-preparacion@82f03bb`).

## El diff

**Un nodo, un parámetro.** `Format Disambiguation Message.jsCode`, 1 746 → 4 051 chars. El `PUT`
demuestra su alcance antes de enviarse, como en el arreglo de la credencial:

```
=== DIFERENCIAS del cuerpo contra el vivo: 1 ===
  .nodes[63].parameters.jsCode: cambia (1746 -> 4051 chars)
  -> una sola, y es el jsCode del nodo objetivo ✓
```

| | |
|---|---|
| `versionId` | `def23539-…` → **`fd298073-257f-4229-b889-f2c1e8301f70`** |
| nodos | **119** · `active = true` · los 7 `webhookId` intactos |

```
ANTES   1. #3496  ·   ·   ·   · 13/08 20:18
DESPUES 1. #3496 FORD EXPLORER 2020 · 13/08 14:18
        2. #3495 TOYOTA SIENNA 2027 · 13/08 13:49
```

## Verifiqué tus dos causas antes de tocar nada

No por desconfianza: porque hoy ya me ha costado dos correcciones dar por buena una afirmación sin
medirla, una de ellas tuya que tú mismo retiraste.

**`quotation_data`:** 1 085 filas · 454 `NULL` · 631 `{}` · **0 con algo dentro**. Confirmado: no era que
los nombres estuvieran mal adivinados, es que la columna no se rellena. **La hora:** la misma fila da
`20:18 UTC` y `14:18 CDMX` — el síntoma exacto que capturaste.

El formateo lleva respaldo por si el contenedor tuviera ICU reducido: `timeZone` lanzaría y **este nodo
es el único que produce el mensaje**. Resta 6 h fijas, exacto hoy porque México no observa DST desde
2022, y probado que los dos caminos coinciden incluido el cruce de día.

## Estuve a punto de mentirle al cliente, y lo paró tu handoff

Al escribir el nodo copié de STG la frase de cierre: *«Responde con el número de la lista (1, 2, 3…) o
con el folio»*. **En producción eso es falso:** `Session Resolution` parsea con `/^[1-9][0-9]?$/`, así
que un folio como `3495` no se reconoce. La copia es correcta **en STG** porque allí su
`Session Resolution` acepta folios — y ese nodo no ha viajado.

Lo cacé releyendo tu sección «lo que NO tienes que arreglar aquí». La frase queda **exactamente como
estaba**, y el guion tiene ahora una guarda que **aborta si el mensaje promete elegir por folio**.

**Y de ahí sale un acoplamiento que quiero dejarte registrado:** el día que `Session Resolution` viaje,
la frase de cierre tiene que viajar con él. Hoy son dos nodos que se contradicen entre entornos y no hay
nada que lo vigile — ni el drift, que compara cada instancia contra su propio baseline.

## Criterios

Cuatro de cinco cerrados. **El quinto es tuyo y de Alberto**: la desambiguación real en producción.
Lo subrayo con tus palabras: hoy Multicotización pasó cinco comprobaciones estáticas y estaba rota.

## Y sobre lo que dejaste fuera

De acuerdo en no tocar el parser en esta ventana. Pero **elegir por folio no funciona en PROD** y el
folio es el número más visible de la línea: el cliente que vea `#3495` y escriba `3495` no será
reconocido. Me parece que merece issue propia, con un matiz: **la copia y el parser se arreglan juntos o
no se arreglan** — si viaja solo el parser, la frase sigue sin decirlo; si viaja sola la frase, promete
lo que no hay.
