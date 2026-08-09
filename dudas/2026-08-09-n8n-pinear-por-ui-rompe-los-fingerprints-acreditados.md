# Duda — Agente-n8n → Arquitecto · **pinchar por UI rompe los fingerprints acreditados**: el método del GO se invalida a sí mismo

**Fecha:** 2026-08-09 (02:35Z) · **Ejecutor:** Agente-n8n
**Qué ejecuto:** `GO_S1_P1_P5_AND_CLOSE` (`57501cb`) + adenda del carril partido (`1bb657f`).
**Estado:** **detenido en P1, en el `pin-verify`.** **Cero ejecuciones. Cero envíos.** Nada se ha
enviado a nadie y no hay nada que retirar del lado de Meta.

## 1. Qué pasó

Alberto fijó el pin de P1 correctamente: pin único, en `S1 Fixture Manual Trigger — Main`, un solo
item, y el contenido **es** el de `f1_v1` (lo verifiqué contra el binding antes de nada). Hizo su
parte bien.

`pin-verify` denegó:

```
C1_NODE_FINGERPRINT_DRIFT: main: fingerprint distinto en un nodo acreditado   (salida 22)
```

Le dije que **no ejecutara**. El turno funcionó: el fallo se cazó en el último punto de parada
seguro, que es exactamente para lo que existe.

## 2. La causa, con control positivo y negativo

| Workflow | Tocado por UI | Nodos congelados con drift | `updatedAt` |
|---|---|---|---|
| **Main** | sí, al pinchar | **4 de 14** | **02:28:37Z** (hace minutos) |
| **Payment** | no | **0 de 5** | 19:25:51Z (el `apply` de ayer) |

Y el otro extremo temporal: **Gate A2 pasó a las 02:10Z comprobando esos mismos fingerprints
congelados**. Entre 02:10 y 02:28 lo único que tocó ese workflow fue la UI.

O sea: no es un drift preexistente, no es una mano equivocada y no es el pin. **Es guardar desde el
editor de n8n.**

## 3. Qué cambió exactamente — y por qué es peor de lo que parece

Comparé nodo a nodo el vivo contra el artefacto. **Al vivo le FALTAN claves que el artefacto sí
tiene:**

- `filters.conditions[0].condition` — en `Check Delivery Idempotency`, `Mark Delivery Sent` y
  `Mark Delivery Failed`;
- `operation` — en `Claim Delivery Processing`.

No hay ninguna clave nueva ni ningún valor distinto: **solo desapariciones**. Es el comportamiento
clásico del editor al re-serializar un nodo: los parámetros cuyo valor coincide con el defecto se
omiten al guardar.

Semánticamente el workflow probablemente hace lo mismo. **Estructuralmente es fatal**, porque el
fingerprint de §6.2 se calcula sobre el JSON del nodo entero quitando solo `position`: una clave que
desaparece mueve la huella igual que un cambio de valor. Y así debe ser — es la propiedad que hace
útil al fingerprint.

## 4. La consecuencia, que es la razón de esta duda

**El método del GO se invalida a sí mismo.** El §2 exige fijar el pin **«mediante UI»**, y el paso 1
del ciclo es justo el que rompe los fingerprints que el paso 2 (`pin-verify`) exige intactos. No es
que hayamos tenido mala suerte en P1: **pasaría igual en P2, P3, P4 y P5**, y volvería a pasar en
cualquier reintento.

Con el estado actual, P1–P5 **no son ejecutables por esa vía**. No es un fallo de implementación de
S1 ni un error de Alberto.

Nota amarga: es la tercera cara del mismo gotcha #12 que llevamos citando todo el día —«en el editor
los cambios se persisten de inmediato»—. Lo teníamos escrito, lo puse en el guion con esas palabras,
y aun así ninguno de los dos previó que **el propio acto de pinchar cuenta como un cambio que se
persiste**. Lo doy por hallazgo mío y por aviso no dado a tiempo.

## 5. Lo que NO he hecho, y por qué

**No he hecho el rollback del §5.** Lo digo explícitamente porque el GO lo pide en la vía de fallo y
me estoy apartando de la letra a propósito:

1. **Restaurar `blocked` son dos PUT que sobrescriben el estado vivo, que ahora mismo ES la
   evidencia** de este hallazgo. Una vez restaurado, nadie puede volver a mirar los cuatro nodos
   drifteados.
2. Si la salida acaba siendo re-aplicar el artefacto `s1_stg_f1f4`, restaurar `blocked` antes es un
   viaje de ida y vuelta gratuito y dos escrituras de más.
3. Y **si `ABORTED_SAFE` es acreditable o no depende de cómo clasifiques esto**, que es justo lo que
   te estoy preguntando. No pienso presentar un cierre incierto como seguro.

No hay ninguna prisa: los dos workflows están **inactivos**, Payment está **intacto**, no se envió
nada, y la ventana de Meta aguanta hasta ~01:53Z de mañana.

## 6. Lo que veo como salidas — decides tú

- **(a) Re-aplicar el artefacto y pinchar por API.** Un `apply` restaura los fingerprints, y el pin
  se pone por `PUT` de `pinData` sin pasar por el editor. Es lo que el §4 del GO original prohibía
  «improvisar»… pero ahora hay evidencia de que **la vía prohibida es la única que no rompe la
  acreditación**, y la autorizada es la que la rompe. Si eliges esto, quiero autorización escrita y
  la comprobación previa de que un `pinData` puesto por API es el mismo objeto que `pin-verify`
  espera — que era tu preocupación legítima y sigue en pie.
- **(b) Aceptar la normalización como equivalencia.** Que la acreditación compare una proyección
  normalizada en vez del JSON crudo. Es **cambio de contrato**, no de implementación, y no lo toco.
- **(c) Abortar la ventana**, cerrar como se pueda acreditar y rehacerla mañana con el método
  corregido.

Mi recomendación, si vale: **(a)**, y no esta noche.

## 7. Estado exacto ahora mismo

- Main: `active=false`, con el pin de P1 puesto y 4/14 nodos congelados con drift.
- Payment: `active=false`, sin pins, 0/5 drift, intacto desde el `apply`.
- `db_writes=0`, `data_table_writes=0`, `outbound_real=0`, cero ejecuciones.
- state-dir, receipt ordinal 2, binding y artefactos privados **íntegros**.

Sin secretos ni PII: no lleva binding, run-id, recipient, IDs A/B, message IDs, pin data, target,
hosts ni rutas privadas. Los nombres de nodo que cito están ya versionados en el repo.
