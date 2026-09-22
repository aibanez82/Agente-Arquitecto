# `D2` y `D3` con la puerta en `GREETING`: `D3` queda limpio, `D2` no cumple

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 22 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-22-paquete-c-d2-d3-puerta-en-greeting.md` (`61b331a`)
> Grafo `dNqtM20ij6ecZYAX` · **versionId `4034d6d9-c4d5-4f63-b53e-71d110d83d01`**, el mismo al empezar y
> al terminar las tres corridas. Verificado antes de medir: respecto a `d5da10ad` cambia solo el
> `AI Agent`, connections idénticas, `systemMessage` 78.573 → 78.675; «ANTES DE NADA, DOS PUERTAS» ya no
> existe; la condición b) trae el paréntesis del turno anterior; `GREETING` abre con «El primer mensaje
> del cliente entra SIEMPRE aquí»; y el `#316` cierra con la línea del «gracias» durante la captura.
> Corridas `20260922-PC-PUERTA`, `-PUERTA-B`, `-PUERTA-C` · evidencia en
> `informes/2026-09-22-paquete-c-puerta/` (40 ejecuciones con su `runData`, la memoria de las sesiones y
> el verbatim de los 40 turnos).

## Resultado

| Criterio | Exigido | `D2` | `D3` |
|---|---|---|---|
| Fuga literal (incluida la regla nombrada en prosa) | 0 | **1/20** | **0/20** |
| Fuga narrada sin nombres | 0 | **1/20** (la misma) | **0/20** |
| Despedida indebida | ≤1/20 | **9/20** | **0/20** |
| Turnos limpios | — | 10/20 | **20/20** |

**`D3` cumple el criterio de cierre entero.** `D2` no: la despedida indebida sigue en 9 de 20.

## `D3`: arreglado

Veinte de veinte. Ni una despedida, ni una fuga, y con redacción variada en cada pasada:

> «Con gusto, Juan. Entonces me faltaría la calle y número, y la colonia de tu domicilio para continuar 🙂»
> (exec 58617)

Contra el 6/20 de `d5da10ad`: **6/20 → 0/20, p = 0,02** (Fisher, dos colas). Es la única cifra de toda la
serie que pasa de «falla» a «no falla» con significación. La línea del `#316` hizo el trabajo.

## `D2`: la fuga sí se arregló, la despedida no

Dos cifras que se mueven en direcciones distintas respecto a `d5da10ad`:

| `D2` | `d5da10ad` | `4034d6d9` | Fisher |
|---|---|---|---|
| Fuga (cualquiera de las dos varas) | 7/20 | **1/20** | p = 0,04 |
| Despedida indebida | 13/20 | **9/20** | p = 0,34 |

La fuga prácticamente desapareció: **1 de 20**, y es una sola respuesta (exec 58608), que además acierta
en la conducta —presenta la cotización— pero explicándose antes:

> «Este es el primer mensaje de la sesión y el cliente solo dice "Gracias" — no hay ningún turno anterior
> mío en esta conversación, así que la regla de despedida social no aplica (requiere que un turno mío
> previo haya cerrado algo). Debo saludar y presentar la cotización con normalidad.
>
> ¡Hola! Soy Carla, de Quálitas 😊 Ya tengo tu cotización para tu *AUDI Q7 2010*…»

Cuenta como **fuga literal** con la vara que acordamos: nombra la regla en prosa («la regla de despedida
social no aplica»), aunque no use ninguna cadena de la lista. Y también como narrada, porque abre
deliberando. Es la misma respuesta en las dos cifras, no dos.

La despedida indebida, en cambio, **no mejora de forma medible**: 9 de 20 primeros mensajes se contestan
solo con

> «¡Con gusto! Aquí estoy cuando quieras retomar 🙂» (execs 58533, 58546, 58564, 58573, 58577, 58582,
> 58598, 58603, 58614)

frente a las 10 que responden lo correcto:

> «¡Hola! Soy Carla, de Quálitas 😊 Ya tengo tu cotización para tu *AUDI Q7 2010* con Cobertura Limitada,
> pago anual de $7,718.70 MXN. ¿Continuamos con esta opción…?» (exec 58529)

El 13/20 → 9/20 con p = 0,34 no permite afirmar que haya bajado: con N=20 en cada lado, esa diferencia
entra dentro de lo que da el azar. Lo que sí queda medido es el nivel actual: **9 de cada 20**.

Cumplo lo que pediste: no propongo texto ni hago otra vuelta por mi cuenta. La decisión —incluida la
alternativa de sacar el bloque de despedida del paquete y llevar a PROD solo lo limpio— es tuya.

## Higiene, y una cosa que salió mal en la corrida

- 40 turnos medidos, **sesión limpia y memoria sembrada en cada uno**, sobre la cotización dedicada 2307.
  **Cero** envíos, **cero** `Issue Policy` / `Save Policy Data`, **cero** escrituras.
- **La primera corrida se cayó en el turno 33**: `psql` agotó su plazo de 30 s durante la comprobación de
  memoria del propio runner (`ETIMEDOUT`, sesión `QA-SUITE-PC-DB-Q`), el proceso murió y **no llegó a
  limpiar: 33 sesiones se quedaron vivas en STG**. Las vi al revisar, exporté su memoria y las borré a
  mano por IDs exactos. STG quedó y sigue en **0 filas `QA-SUITE-%`**.
- Los 33 turnos de esa corrida **no se perdieron**: el `runData` de cada uno ya estaba exportado a disco
  turno a turno, que es justo para lo que pediste el export. Reconstruí sus veredictos desde esos ficheros
  con `scripts/reconstruir_pc.py` (mismos criterios que el runner) y los contrasté con lo que el runner
  había impreso antes de morir: **coinciden turno a turno**. El turno 33, el interrumpido, sí se midió —
  su ejecución terminó y su memoria previa estaba limpia—, así que cuenta. Los 7 que faltaban para N=20 se
  corrieron después sobre sesiones nuevas (`-PUERTA-B` y `-PUERTA-C`).
- El runner ya lleva plazo de 60 s y reintentos en `psql` para que un corte de la base no vuelva a tumbar
  una corrida a mitad.

— Agente QA & Testing
