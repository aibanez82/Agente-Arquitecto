# Acuse y órdenes — `#551` v2, E2E con el participante 105

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **8 oct 2026**

**Aceptado:**
- los puntos 2 y 4 del gate en vivo (texto → contexto → RAG → «Ver promo» con memoria);
- D1 y D4 aplicados (STG `486aa457`);
- el `context.id` recuperado en `Discount Reply Intake` (`861def47`).

## Defecto A (el binario no cruza el fence): **aprobado tu Code `Recovery PDF Binary`**

Entre `IF Send Recovery?`[verdadero] y `Upload Recovery Media`. Devuelve el `$json` intacto y el `binary` de
`$('Download Recovery PDF')`. **El orden del fence (`#481c`) no cambia.** Arnés con un PDF real de STG y diff de un
nodo y una arista.

**Repetir el punto 3:** el 105 queda `uncertain_no_retry` y **no se repara a mano**. El punto 3 se repite con el
participante que use Juan para el punto 1. Se lo pido yo en el `#551`.

## Defecto B: dos órdenes, no una

1. **Etiqueta del contexto (grafo): aprobada.** En `Merge Session Data`, la línea pasa a ser `poliza_anterior_recovery` con
   «campaña de recuperación: se vende una póliza NUEVA; no es una renovación». Va solo cuando el contexto viene de
   Recovery, y no toca el `systemMessage`. La regla de RENOVACIÓN del prompt queda anotada para la firma de Alberto.
2. **La fuga del razonamiento interno: guarda de salida.** En `Outbound Leak Guard`, quita las líneas de
   meta-razonamiento: el modelo hablando **del cliente en tercera persona** («El cliente está pidiendo…»), «Esto es
   CASO A/B», o claves internas del contexto (`poliza_anterior`, `qid=`, `phase=`, `[CTX`). Patrones **estrechos**.
   - **Regresión obligatoria**, contra los mensajes `ai` reales de PROD (solo lectura): **no puede quitar nada
     legítimo**. Medido por mí hoy: en todo el historial de PROD, la única coincidencia amplia es una frase legítima
     («Para su caso, le recomendamos…», fila 4286) y **no debe tocarse**.
   - **Control positivo:** el texto de la exec 82308 queda limpio y solo sale la frase al cliente.

Las dos en STG, de uno en uno, con informe. **No importes en PROD.**

Agente: Arquitecto-IA-Insurmind
