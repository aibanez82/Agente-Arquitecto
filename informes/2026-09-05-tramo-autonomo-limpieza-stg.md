# Tramo autónomo — limpieza de STG

> Arquitecto-IA-Qualitas · 5 sep 2026, noche · **Trabajo hecho sin supervisión, por encargo de Alberto.**
> Ámbito: **STG.** Grafo del bot al cierre de este informe: `9ced3db9`, 318 nodos.

## Lo que se cerró, con medición propia

### Fase 1a — `#341`: la cifra la valida el grafo

Nodo nuevo **`Figure Fidelity Guard`**, entre `Outbound Leak Guard` y `Send message`. Construye el conjunto de cifras autoritativas del turno y compara con lo que el modelo escribió.

**20/20** en la pregunta de la suma asegurada · **10/10** en la de placas · **5/5** offline, incluida la sustitución exacta `5.449,01` → `5.449,04`.

**La tasa real de fabricación de dígito: 0 de 30.** Con el 1-de-5 de ayer, la conclusión es que **es rara e intermitente** — que es justo lo que la hace imposible de perseguir con baterías y necesaria de mirar en cada mensaje.

### Fase 1b — `#324`: no afirmar lo que no se tiene

**10/10** dejan claro que el cliente no tiene Robo Parcial contratado, sin negar el dato correcto. El freno —no inventar aclaraciones sobre coberturas que **sí** tiene— aguantó **0 de 5**.

> «Robo Parcial no viene incluida en tu cotización, es una cobertura accesoria… **Si te interesa agregarla, dime y lo revisamos juntos.**»

**Disparos de la guarda: 0 de 25.** Porque los seis chunks que corregí ya llevan el aviso y el modelo lo trae solo. **Aquí lo que funcionó fue arreglar el dato**, no el determinismo.

### Fase 5a — `#339`: la frase del descuento la escribimos nosotros

Acuse reescrito y nodo compositor nuevo. La pareja que Alberto señaló ahora encaja:

> «**¡Voy a por ello!** Déjame revisar tu cotización para buscarte el mejor precio posible.»
> «**¡Lo conseguí! 🎉** Hay un descuento aprobado y ya estoy armando la nueva con el precio mejorado.»

**La frase comercial queda como constante vacía, para que la fije Alberto.** Si está vacía, no se añade nada — nada de inventar una promesa por rellenar el hueco.

## Lo que se descubrió ya hecho

**La Fase 2 entera (`#297` + `#296`) llevaba entregada desde el 2 de septiembre**, por un handoff que ordené yo. Los nodos `Repair Window (AI)`/`(RAG)` están activos, se dispararon **una vez** y **la conversación muda volvió a hablar** — cadena completa verificada (`6319` reparación → `6320` cliente → `6321` el bot contesta).

Y **el `#296` era el mismo defecto**: el proveedor lo dice literal, `messages.0.content.0: unexpected tool_use_id found in tool_result blocks`.

Llegué ahí midiendo exposición durante media hora **antes de mirar si ya existía el nodo que lo arreglaba.**

## Lo que queda bloqueado, y por qué no lo forcé

**Fase 3 — `#285`.** Mi premisa era falsa: escribí que la función de reserva no comprueba el estado de la sesión. **Sí lo hace**, vía `conversation_control_v1`, y **las 42 cerradas dan `automation_gate = blocked`**. El carril habría fallado el 100 % de las veces.

El bloqueo real es de diseño: el gate no distingue **proactivo** de **reactivo**. «No inicies conversación» y «no contestes a quien te escribe» no son lo mismo, y hoy son la misma regla.

**Toca superficie compartida con Juan.** No la muevo de madrugada para cerrar una fase.

## Decisiones que dejo preparadas, no tomadas

| Issue | Estado |
|---|---|
| **`#285`** | Recomiendo que el gate distinga lo reactivo. El resto del carril está construido: **una tarde corta** tras la decisión |
| **`#338`** | **No hay que instrumentar, hay que decidir.** El canal `ai_tool` no es legible y la alternativa colgó el runner. Propongo renombrar (son turnos informativos, no búsquedas) y subir el umbral: 196 sesiones de PROD, máximo 11 de 15, **cero cortes** |
| **`#279`** | Dos patrones nuevos **ya probados**, con cero falsos positivos en seis controles. Listo para encargar |
| **`#340`** | Diseñado como tercera capacidad del mismo guard: la familia `d156` permite saber que ya se anunció |
| **`#325`** | **Sin reaparición** en 30 ejecuciones en error. Negativo acotado, no cierre |

## Mis errores de este tramo

1. **Medí la exposición del `#297` durante media hora antes de mirar si el arreglo ya existía.** Estaba desplegado desde el 2 de septiembre y lo había ordenado yo.
2. **Afirmé que el 25 % del Robo Parcial no existía «en ninguna fuente».** Está en la KB **y** en las Condiciones Generales. Segunda ausencia sin medir del día.
3. **Escribí que la función de reserva no comprueba el estado.** Mi `grep` no incluía `automation_gate`. **Una lectura incompleta se siente igual que una completa.**
4. **Mi diseño de la Fase 1a habría borrado una frase verdadera** —el 25 % del parcial, que no está en la cotización pero sí en el contrato—. Lo cazó el ejecutor y lo acotó.

Los cuatro son la misma forma, y ya tiene nombre: **decidir sobre un ámbito que no comprobé que fuera completo.**

## Y una cosa que no pude hacer

**La corrección de los seis chunks de coberturas accesorias solo está en STG.** La escritura contra la otra base **la denegó el clasificador de permisos de mi sesión, y no la rodeé.** Queda para decisión de Alberto: si se corrige un solo lado, reaparece el `#330`.

Agente: Arquitecto-IA-Qualitas

---

# Cierre del tramo

Después de escribir lo de arriba se cerraron tres cosas más.

## `#279` — dos patrones al `NIEGA_EMISION`

**La frase que da nombre al issue ya se cazaba.** Lo que escapaba era el presente sin auxiliar («no se emite… póliza») y el participio interpuesto («no ha quedado emitida»). Dos patrones nuevos, **verificados por mí contra el código vivo**: 4/4 positivos caen, **6/6 controles salen intactos** — incluidos los de recibo, factura y link.

## `#340` — no anunciar dos veces, y el defecto que destapó

**22/22 offline**, con el mensaje literal de Alberto como caso 1: el párrafo repetido sale y la lista de datos sobrevive.

**Pero lo importante es lo que encontró el freno.** «Un ahorro de $2.850,95» es la **resta** de dos cifras autoritativas y no viaja en ningún XML: **mi lógica de la Fase 1a la habría borrado, mutilando el anuncio del descuento** que acabábamos de construir. Corregido validando también las diferencias par a par, **solo validación, jamás sustitución**.

Es la **segunda vez en la noche** que mi conjunto autoritativo se queda corto — la primera fue el 25 % del Robo Parcial, que vive en la KB y en el contrato.

**El principio, que me llevo:** una cifra puede ser verdadera porque está en el payload, porque viene de otra fuente o porque **se deriva** de las que están. **Una guarda que confunde «no lo tengo escrito» con «es falso» no protege: censura.** Validación ancha, acción estrecha.

## `#288` — el acuse repetido es NUESTRO

Medido: la frase de Django no aparece **ni una vez** en el historial de conversación. **La que se repite es la nuestra** — 28 sesiones la recibieron más de una vez, **72 apariciones**, hasta 4 en una conversación. Las «tres veces seguidas» que el `#248` atribuye a Juan son de nuestro acuse.

Y descarté una alarma propia: **no es un envío triplicado**. Las tres están separadas 25 y 17 segundos, con su oferta detrás cada una.

**Consecuencia incómoda:** el `#339` de esta noche **reescribió esa frase pero no arregla la repetición**. Cambiamos una plantilla por otra mejor. Propuesta en el issue: variación determinista en el nodo que ya compone.

## Estado final de STG

| | |
|---|---|
| **Cerrados hoy con medición propia** | `#320` `#323` `#324` `#326` `#327` `#328` `#332` `#334` `#336` `#339` `#341` `#279` `#340` · `#270` y `#313` contigo |
| **Ya estaban hechos** | `#297` y `#296` |
| **Esperando decisión tuya** | `#285` (gate reactivo) · frase comercial del `#339` · `#288` |
| **Reencuadrados, no construidos** | `#338` (decidir, no instrumentar) · `#325` (sin reaparición) · `#277` (la salida estructural) |

## Lo que no pude hacer

**Los seis chunks corregidos solo están en STG.** La escritura contra la otra base la denegó el clasificador de permisos y **no la rodeé**.

Agente: Arquitecto-IA-Qualitas
