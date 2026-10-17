# n8n · A → Arquitecto: `#551` adenda 23 (nombre sin partir). Medición sobre las 22 sesiones y propuesta de mecanismo

**Fecha:** 17-oct-2026 · **Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md`, adenda 23 (`06eed775`).

**No he tocado nada. 0 llamadas a modelo.** Solo he leído `whatsapp_sessions` de PROD.
**Sin PII:** aquí solo van formas (número de palabras y posición de partículas e iniciales), nunca nombres.

**Acuse de tu mensaje sobre la 38:** recibido. No construyo nada de la 38 hasta la adenda con la respuesta de Alberto sobre el opt-out.

## Medición: `recovery_precarga.nombre_completo` en las 22 sesiones Recovery de PROD

- **Django no precarga ningún dato del grupo 1** en las 22 sesiones: ni `nombre`, ni `apellido_paterno`, ni `fecha_nacimiento`, ni `genero`.
- Las 22 traen solo `nombre_completo`. Con el nombre partido, **seguirían faltando la fecha de nacimiento y el género en las 22.**

| Clase | Sesiones | Forma |
|---|---|---|
| **No ambiguo** (4 palabras, sin partículas ni iniciales) | **10** | W W W W |
| **Ambiguo, 3 palabras** | **8** | W W W |
| **Ambiguo, con partícula** | 1 (`waq_4518`) | W **P** W W W, con la partícula en la 2.ª posición. Seguramente es parte del nombre de pila. |
| **Raro, con inicial** | 1 (`waq_4513`) | W W W W **I** W: 6 palabras con una inicial en la 5.ª. |
| **Empresa** | 2 (`waq_4498`, `waq_4504`) | W P W W y W W W. |
| Una sola palabra, dos palabras o vacío | 0 | — |

- **Empresas:** las detecto por palabra clave («construcciones», «gestión», «servicios», «grupo», «S.A.», «C.V.», «S.C.», «SAPI», «S. de R.L.», «comercializadora», «transportes», «inmobiliaria»…).
  - `waq_4504` tiene 3 palabras. **Sin la lista**, caería en «ambiguo» y la pregunta le ofrecería como apellidos una palabra de la razón social.
  - Una persona moral que no esté en la lista caería igual. **La lista no es completa: es un riesgo conocido.**

## Mecanismo propuesto

Todo va en `precarga.js`, que es fuente única con copia literal en `Validate Recovery Envelope` y `Merge Session Data`. **El modelo no parte nada.**

1. **`partirNombre(full)`, una función pura:**
   - **Empresa** (por la lista) → `{ clase: 'empresa' }`. No se separa nada y queda como hoy, fuera del alcance.
   - **No ambiguo** (4+ palabras sin partículas ni iniciales) → paterno y materno son las 2 últimas palabras, y el nombre lo que queda delante.
   - **Ambiguo:** 3 palabras, partículas o iniciales.
     - Propone la separación más probable: las 2 últimas palabras son los apellidos.
     - Si hay una partícula justo delante de una de ellas, va pegada a ese apellido: «de la X» queda como apellido paterno.
     - Así, en `waq_4518` la partícula de la 2.ª posición queda en el nombre de pila.
   - Una o dos palabras → `{ clase: 'insuficiente' }`. Se piden por separado, como hoy.
2. **`estadoRecovery`** usa la separación **no ambigua** como valor **precargado** de nombre, paterno y materno, igual que si los hubiera mandado Django.
   - Con eso salen de `faltan` y entran en `precargado=` del `[CTX:]`.
   - Se guardan en el grupo 1 por el camino de los precargados, y **los confirma el resumen**: «se guarda sin preguntar».
   - `nombre_sin_partir` ya no se manda en ese caso.
   - **Lo calculo en cada turno, en `Merge Session Data`, y no solo al recibir el contexto.** Así entran también las sesiones que ya existen, sin escribir nada en la BD.
3. **`rfcBase`** (`#545`) usa la misma separación cuando no hay grupo 1 guardado. Va por el mismo fallback que ya añadí para la precarga, con la regla del RFC sobre recovery_precarga, así que el RFC sale de esa separación.
4. **Ambiguo.** El `[CTX:]` lleva `pregunta_apellidos=«¿Tus apellidos son *[AP1] [AP2]*?»`, ya montada por el grafo. `pendienteRecovery` le dice al modelo que la haga **sola y copiada exacta**.
   - Si el cliente dice «sí», se guarda la propuesta.
   - Si dice «no», se le piden por separado.
   - Para que el «sí» o el «no» se resuelvan en el grafo, `Merge Session Data` ve que la última fila `ai` contiene esa pregunta. Con un sí o un no corto, aplica la separación o la descarta: con el sí, los tres campos pasan a `precargado`; con el no, a `faltan`.
5. **Lo que falte, en lista.** `pendienteRecovery` monta el mensaje entero y el modelo lo copia:
   > Ya tengo tu nombre: *[NOMBRE COMPLETO]*. Para terminar tus datos solo me falta:
   > - Fecha de nacimiento (DD/MM/AAAA)
   > - Género (M/F)

   Las etiquetas de la lista son fijas, una por campo.
6. **Lo que se sustituye:** la línea de la adenda 15 («NO lo partas tú: pide sus apellidos…»), que es la del `551nom` (STG `e8695148`, PROD `5793e40c`). Es un hunk de `[CTX:]` y entra en la lista viva.

## Lo que necesitas decidir
1. **Ambiguo: ¿la pregunta va sola, o junto a la lista?** La regla dice «una sola cosa, corta».
   - Mi propuesta: sola. La lista va en el turno siguiente.
2. **La inicial de `waq_4513`.** ¿La trato como ambigua, con la pregunta? Mi propuesta: sí.
3. **La lista de palabras de empresa.** Se queda corta por definición.
   - ¿La acepto como salvaguarda, o prefieres que, mientras Hylant no decida, se le pida a Juan que Django marque `persona_moral` en el contexto?
   - Recomiendo la lista ahora y pedirle la marca a Juan después.

**Arnés**, cuando toque, con la 13.2 y la 38:
- **Primero, sin modelo:** `partirNombre` y `estadoRecovery` en node, sobre las 22 formas medidas, con nombres sintéticos de la misma forma.
- **Después, con modelo, N≤3 por caso:** un caso no ambiguo, uno de 3 palabras, uno con partícula, y la regresión N=1. **Unas 12 llamadas.**

Agente n8n · A
