# Marca y posicionamiento de Insurmind

> Decidido con Alberto el **6 sep 2026**. Aquí vive lo acordado; los ficheros de al lado son lo que se le manda a quien diseñe.

## El titular, cerrado

> **Cotiza, resuelve, emite y cobra. Sin intervención.**
>
> Sobre las aseguradoras que ya usas — una o varias a la vez.
> Tú ves cada conversación, mides la conversión y tomas el control cuando el negocio lo pida.

Los cuatro verbos son la prueba de que **el recorrido se completa**, que es lo que casi nadie en el sector puede decir. «Resuelve» es el que separa de un cotizador.

**Nunca «vende y cobra solo»:** en español «solo» se lee como *solamente*, y diría lo contrario.

## Lo que Insurmind NO es

**No es un core asegurador.** No guarda la póliza de registro, ni gestiona siniestros, ni lleva contabilidad técnica: `Issue Policy` es una llamada al webservice de la aseguradora, y quien tarifica es ella.

**Es todo lo que pasa antes y después del core.** Antes: captar, cotizar, conversar, negociar y emitir. Después: cobrar y retener. El core es el trozo del medio y es de la aseguradora.

Decirlo al revés lo desmonta cualquier comprador con dos preguntas —«¿gestionáis siniestros?», «¿lleváis la contabilidad técnica?»— y perder credibilidad en la primera reunión cuesta más que no tener categoría.

**Si hace falta una casilla** para un directorio o un inversor: *capa de distribución digital multi-aseguradora*. Aburrida y defendible.

## Dos palabras prohibidas, y por qué

| No decir | Decir | Motivo |
|---|---|---|
| «core asegurador» | «antes y después del core» | Falso y comprobable en dos preguntas |
| «modelos entrenados» | «afinados con conversaciones reales», «aprendido en producción» | «Entrenar» significa ajustar pesos con un dataset. No es lo que hacemos, y el primer técnico que lo lea lo desmonta |

## Cómo se pone en valor la tecnología

**No en el titular.** Quien firma no compra el motor. La tecnología va en una sección propia, y **el argumento fuerte no es «usamos IA de punta»** —eso a un asegurador le suena a riesgo— sino:

> **Conversa como una persona. Se equivoca como una máquina: no puede.**

Modelos frontera de Anthropic para conversar; **barreras deterministas** para lo que no se puede equivocar. Las cinco barreras están en el brief, y ninguna depende de que el modelo se porte bien: **están en la infraestructura, no en el prompt**.

**Anthropic sí se nombra. El orquestador no** — a un departamento de sistemas, el nombre le abre la pregunta equivocada; se nombra la capacidad: «orquestación de eventos con reintentos, idempotencia y control de concurrencia». **Versiones de modelo, nunca**: envejecen en seis meses.

## El foso, que es lo que de verdad no se copia

El modelo lo tiene cualquiera. **Las correcciones no.** Meses leyendo conversaciones reales de leads mexicanos y corrigiendo cómo contesta. Ejemplos en el brief, todos reales.

Y el hallazgo que lo hace creíble: **un prompt no gobierna un dato exacto** — medido tres veces. Por eso las correcciones que importan bajan al grafo.

## Ficheros

| Fichero | Para qué |
|---|---|
| `prompt-rediseno-landing-insurmind.md` | Brief completo para quien diseñe la landing |
| `adenda-diagrama-insurmind.md` | Por qué el diagrama de satélites está mal y qué debe decir el nuevo |
| `insurmind-tres-planos.svg` | El diagrama dibujado, como referencia editable |

## Lo que queda abierto

- **`[MÉTRICA POR CONFIRMAR]`** en el brief: no hay cifras públicas verificadas. Antes de publicar ninguna, medirla contra la base y decir si se sostiene.
- **La captura de COBRA es una especificación, no un recorte.** El sistema ya detecta el recibo por vencer y genera la liga a diario en PROD, pero **el envío proactivo no sale todavía** — `HYL-WAI#241`, abierto, de Juan. Decisión de Alberto: enseñarlo igual porque llega pronto. **Quien haga demos debe saber que ese tramo no se enseña en vivo.**
