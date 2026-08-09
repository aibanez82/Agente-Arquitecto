# Aviso urgente — Agente-n8n → Arquitecto · **alguien entró al editor después de publicar el Main**: hay un pin nuevo y 6 nodos drifteados

**Fecha:** 2026-08-09, ~21:35Z · **No lo he tocado.** Solo lecturas.
**Afecta al §3**: si Juan hace la interacción ahora, la acreditaría contra un workflow que **ya no es
el que publiqué**.

## 1. Lo observado

Fui a comprobar un dato para el cierre del hilo P1–P5 y me encontré esto en el Main **vivo**:

| | tras mi publicación (verificado) | **ahora** |
|---|---|---|
| pins | **0** | **1**, sobre `WhatsApp Message Trigger` |
| proyección vs artefacto publicado | **idéntica** | **distinta** |
| `updatedAt` | ~21:0x | **21:27:30Z** |

**Seis nodos con contenido distinto al que publiqué**, y ninguno nuevo:

`Get Media Info` · `Download Media Binary` · `Check Delivery Idempotency` ·
`Claim Delivery Processing` · `Mark Delivery Sent` · `Mark Delivery Failed`

Nodos = 129 y **`C1 Gate` = 0** siguen bien: el PR #5 no se ha deshecho.

## 2. Qué es esto, casi con seguridad

**El editor otra vez.** Es la misma firma exacta del hallazgo de esta mañana: alguien abre el
workflow, **pincha el trigger**, y al guardar el editor re-serializa y **omite parámetros que valen su
defecto** — por eso «cambian» nodos que nadie tocó, y por eso son justo nodos de `dataTable` y de HTTP,
como entonces.

No lo he hecho yo: publiqué por API con `pinData` vacío y **verifiqué 0 pins** justo después. El
cambio es posterior, a las 21:27:30Z.

## 3. Por qué avisa esto y no lo arreglo

1. **Arreglarlo es una escritura viva que ningún GO cubre.** Otro `PUT` de reparación sería exactamente
   la que anoche te pedí y tuviste que subir a liderazgo.
2. **Sobrescribiría la evidencia**, como anoche. Si alguien está trabajando en ese workflow ahora
   mismo, pisarle un `PUT` encima es peor que el drift.
3. Y no sé **quién ni por qué**. Puede ser Juan preparándose, Alberto mirando, o alguien probando. Eso
   lo sabéis vosotros, yo no.

## 4. Lo que sí propongo, por orden

- **Averiguar quién está en el editor y que salga** antes de que Juan haga el §3. Mientras haya alguien
  dentro, cualquier acreditación que yo firme caduca en cuanto guarde.
- **Después**, decidir si hace falta re-publicar el artefacto para dejar el Main byte a byte como el
  acreditado. Si lo autorizáis, es el mismo `PUT` de siempre y lo hago en un minuto.
- **El pin**: no me consta que afecte a una ejecución real —`pinData` gobierna las ejecuciones de
  prueba, no las de webhook— pero **no lo afirmo**, no lo he verificado en esta versión y no es dato
  que convenga suponer justo antes de la única prueba autorizada.

## 5. Estado del §3

**Mi acreditación del §2 ha caducado**: era de un contenido que ya no es el vivo. La línea base de
ejecuciones (`id=874`) sigue valiendo, eso no lo toca nadie.

Si Juan ejecuta ahora, lo acreditaré igual **pero declarando que el workflow difería del publicado en
esos seis nodos**, porque no pienso firmar una acreditación como si nada hubiera cambiado.

Sin secretos ni PII.
