# Cierre de sesión — 5 al 6 de septiembre de 2026

> Arquitecto-IA-Qualitas. **Punto de retomada tras `/clear`.**

## Lo que espera a Alberto, por orden

| # | Qué | Por qué |
|---|---|---|
| 1 | **El gate del `#285`** — que distinga **proactivo** de **reactivo** | Es lo único que bloquea un carril **ya construido**. Hoy `automation_gate=blocked` en las 42 sesiones cerradas: «no inicies conversación» y «no contestes a quien te escribe» son la misma regla. Toca `conversation_control_v1`, superficie compartida con Juan |
| 2 | **La frase comercial del `#339`** | Queda como constante **vacía** en `Build Discount Resolution Copy`. Y hay un dato: **Django ya la tiene escrita** — su `offered_copy` dice «Logré un descuento especial **si contratas hoy conmigo**» |
| 3 | **Los seis chunks de accesorias en la otra base** | Corregidos solo en STG. La escritura contra la otra **la denegó el clasificador de permisos y no la rodeé**. Si se corrige un solo lado, vuelve el `#330` |
| 4 | **`#288`** — el acuse repetido | Propuesta escrita: variación determinista. **El arreglo del `#339` no lo resuelve** |

## Lo acreditado en STG, con medición propia

`#320` · `#323` · `#324` · `#326` · `#327` · `#328` · `#332` · `#334` · `#336` · `#339` · `#340` · `#341` · `#279` — más `#270` y `#313`, medidos con Alberto en conversación real hasta la aplicación `430` del ledger.

**Cuatro barreras deterministas nuevas**, todas en el `Figure Fidelity Guard`, último tramo antes de Meta: la cifra que no está en el payload no sale · no se afirma una cobertura no contratada · no se anuncia dos veces el mismo descuento · y dos huecos más cerrados en la guarda de emisión.

## Lo que resultó estar ya hecho

**`#297` y `#296`** llevaban arreglados desde el 2 de septiembre —`Repair Window (AI)`/`(RAG)`—, y funcionan: se dispararon una vez y **la conversación muda volvió a hablar**, cadena verificada. Los dos eran **el mismo defecto**.

## Reencuadrados, no construidos

- **`#338`**: no hay que instrumentar, hay que **decidir**. El canal `ai_tool` no es legible y la alternativa colgó el runner. 196 sesiones de PROD, máximo 11 de 15, **cero cortes**. Propuesta: renombrar (son turnos informativos) y subir el umbral.
- **`#325`**: sin reaparición en 30 ejecuciones en error. Negativo acotado.
- **`#277`**: sigue siendo **la salida estructural** de la familia de emisión. El `#279` es contención.

## Juan

**36 horas parado** al cierre. La rama del `#281` tiene 5 commits, **todos `docs`**, cero código: sigue en su hito `R0 — Plan aprobado`. Monitor vivo y verificado (`watch.sh`, proceso comprobado), vigilando ramas, PRs, comentarios de la cadena y **config vars de Heroku** — que es la señal que no deja rastro en git.

Lo único que su plan nos dejaba en paralelo —**el rebase del candidato del `#144`**— está hecho: 30 nodos, tres puentes, y los seis nodos que habían derivado puestos al día.

## Estado físico

- Grafo del bot en STG: **`846288b5`**, 318 nodos.
- **STG sin fixtures**: 213 sesiones, 946 historiales y 90 dispatch borrados; **quedan 109 y las 109 son reales**.

## Lo que este día enseñó, y vale más que los arreglos

**1 · Un prompt no gobierna un dato exacto.** Medido tres veces: el `#341` («cifra LITERAL» y un dígito cambiado), el `#324` y el `#206` con tres redacciones en nivel de ruido. Si el dato es exacto o la prohibición es dura, **lo pone el grafo**.

**2 · Pero a veces la fuente estaba mal y basta con arreglarla.** El `#324` cerró con **0 disparos de 25**: los seis chunks corregidos hicieron el trabajo y la barrera quedó de cinturón.

**3 · Una guarda que confunde «no lo tengo escrito» con «es falso» no protege: censura.** Mi conjunto autoritativo se quedó corto **dos veces** — cifras de la KB y del contrato, y cifras **derivadas** (el «ahorro de $2.850,95» habría mutilado el anuncio del descuento). **Validación ancha, acción estrecha.**

**4 · Escribir la regla, no un proxy de la regla.** Cinco veces el mismo error: criterios anclados a un indicio, a una posición («no *cierres* preguntando» → lo movió al principio), a mi paráfrasis en vez de la frase del cliente, o a un `grep` con el patrón incompleto.

## Mis errores, contados

Afirmé dos ausencias sin medirlas (la exclusión por licencia y el 25 % del Robo Parcial, **los dos existían**) · medí media hora la exposición del `#297` **antes de mirar si el arreglo ya existía** · dije que la función de reserva no comprueba el estado, con un `grep` que no incluía `automation_gate` · y **mi propio diseño habría borrado dos verdades**, cazadas las dos por los frenos que puse en los encargos del ejecutor.

Agente: Arquitecto-IA-Qualitas
