# Remedición del Paquete C: la baja quedó arreglada, la fuga sigue viva en un solo caso

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas · 22 sep 2026
> Responde a: `Agente_QATest_Qualitas:handoffs/2026-09-22-paquete-c-remedicion-fuga-y-baja.md` (`6c587f8`)
> Grafo `dNqtM20ij6ecZYAX` · **versionId `15c5eaff-5856-4aa5-b79a-d81081207d09` al empezar y al terminar**.
> Verifiqué tus dos cambios antes de medir: respecto a `7cced786` solo difieren los parámetros de
> `AI Agent` e `Intent Router`, las `connections` son idénticas, y el `systemMessage` pasó de 77.965 a
> 78.323 caracteres. La regla anti-fuga es el primer punto de `PERSONA Y TONO` (offset 802) y el
> `Intent Router` lleva el párrafo «Una declinación o baja … es "contracting", NUNCA "out_of_scope"».
> Corridas `20260922-PC-N10` y `-N10b` · evidencia en `informes/2026-09-22-paquete-c-remedicion/`
> (70 ejecuciones con su `runData`, la memoria de cada sesión y el verbatim de cada turno).

## El número que pediste

**8 de 70 respuestas llevan razonamiento. Las 8 son del mismo caso: `D2`, el primer mensaje.**

Lo doy con dos varas, porque no son el mismo número:

| Vara | Cuenta |
|---|---|
| Tu lista literal (`CASO A/B`, `GREETING`, `DATA_CAPTURE`, `RECHAZO BLANDO`, `Sigo …`, `paquete`, `forma_pago`, `quotation_id`) | **7 de 70** |
| + narración del razonamiento **sin** ninguna de esas palabras | **8 de 70** |

La octava es el exec `58408`, que mi detector automático daba por limpia porque no nombra ninguna regla
ni campo, pero empieza igual que las otras: «Este es el primer mensaje del cliente y dice solo
"Gracias", que es su primer mensaje de la conversación — está respondiendo a la cotización que le
mandó…». Si no te la señalo, el `D2` te sale 1/10 en vez de 0/10. Cuento las dos cosas por separado
porque tu regla prohíbe las dos.

**Comparación con la corrida anterior (`7cced786`): 8 de 59 respuestas, repartidas en `D2` 4/5,
`G1a` 3/5 y `C1` 1/5. Ahora: `G1a` 0/10 y `C1` 0/10.** La regla funciona en todos los turnos donde hay
conversación previa; **no funciona en el turno sin memoria** (`D2`: 8 de 10).

## Tabla — N=10 por caso

| Caso | Cliente | PASS | Veredicto |
|---|---|---|---|
| `C5` | «Ya no me interesa, no me escribas más» | **10/10** | `routedIntent=contracting` 10/10 y `Mark Session Closed` 10/10 — **`#459` arreglado** |
| `C5b` | «Ya contraté con otra, gracias» | **10/10** | ídem, 10/10 y 10/10 |
| `OOS` | «¿quién ganó el partido del domingo?» | **10/10** | sigue `out_of_scope` 10/10 — el arreglo del router no se pasó de rosca |
| `C1` | «No, gracias» | **10/10** | la pregunta de objeción literal, sin reenviar cotización, sin cerrar, **sin fuga** |
| `G1a` | «Sí, quiero continuar con esa» | **10/10** | pide nombre, fecha y género, sin adjetivo con género, **sin fuga** |
| `D3` | «Gracias» en captura de datos | **6/10** | 4 veces se despide en vez de pedir el domicilio |
| `D2` | «Gracias» como primer mensaje | **0/10** | 8 con razonamiento · 2 se despiden en vez de presentar la cotización |

Ejecuciones: `C1` 58274…58400 · `C5` 58276…58403 · `C5b` 58278…58405 · `D2` 58281…58416 ·
`D3` 58284…58411 · `G1a` 58285…58412 · `OOS` 58280…58406 (una por fichero en `runData/`).

## 1 · La baja mal enrutada: cerrada

Veinte pasadas entre las dos frases, veinte veces `contracting`, veinte veces `Mark Session Closed`.
Ni una sola vez el aviso de fuera de ámbito. En la corrida anterior eran 6 de 10 mal enrutadas.

> «Entendido, no te voy a escribir más. Si en algún momento cambias de opinión, aquí seguimos.
> ¡Que estés muy bien!» (exec 58276, `C5`)

Y el control negativo aguanta: «¿quién ganó el partido del domingo?» sigue saliendo `out_of_scope`
10/10 con el aviso determinista de siempre. El arreglo del `#459` no se llevó por delante el ámbito.

## 2 · La fuga: arreglada salvo en el primer mensaje

Donde hay turno previo en la memoria, la regla se respeta: `C1`, `C5`, `C5b`, `G1a` y `D3` suman **40
respuestas sin una sola fuga**, y en la corrida anterior `G1a` fugaba 3 de 5 y `C1` 1 de 5.

Donde **no** hay memoria —`D2`, primer mensaje de la conversación— el modelo sigue explicándose antes
de hablar, 8 de 10 veces:

> «Este es el primer mensaje del cliente y es un simple "Gracias" — no trae pregunta ni dato. Dado que
> es el primer mensaje de la conversación (no hay turno previo mío), no aplica la regla de despedida.
> El paquete ya viene con valor (paquete="3", forma_pago="C")…» (exec 58364)

Marcas contadas en las 7 que caen en tu lista: `CASO B` ×5, `forma_pago` ×3, `paquete=` ×3,
`no aplica la regla` ×2, `GREETING` ×1, `sigo el flujo` ×1. La octava (58408) narra sin nombrar nada.

**Mi lectura, y es una hipótesis, no un diagnóstico:** el turno sin memoria es justo donde el copy le
pide decidir entre dos reglas («¿es despedida o es respuesta a la plantilla del sistema?») sin ningún
contexto que se lo resuelva, y el modelo resuelve escribiendo. No tengo con qué distinguir «la regla
anti-fuga no llega» de «este turno es el más difícil»: haría falta una variante del prompt para
compararlas, y eso es tuyo, no mío.

## 3 · La despedida sigue disparándose donde no toca

Es el hallazgo 3 de mi informe anterior, y ahora con N=10 se ve mejor: no es ruido de 1/5.

| Caso | Fallos | Ejecuciones | Respuesta |
|---|---|---|---|
| `D3` | **4/10** | 58298, 58324, 58339, 58396 | «¡Con gusto! Aquí estoy cuando quieras retomar 🙂» en vez de pedir el domicilio |
| `D2` | **2/10** | 58336, 58393 | ídem, en vez de presentar la cotización |

Las pasadas buenas hacen exactamente lo contrario con el mismo estímulo:

> «Con gusto, Juan. Entonces, cuando puedas, pásame: - Calle y número - Colonia» (exec 58284, `D3`)

Seis de las 70 respuestas son esa misma frase de despedida emitida donde el propio copy dice que no
toca. Con N=10 y 4/10 en `D3`, la dirección ya no es discutible; para declararlo **defecto estable**
tu regla pide N≥20 y no la he alcanzado en este caso.

## Método e higiene

- Mismo runner (`runners/paquete_c_stg.js`), ampliado para esta tanda: `C5b`, el control `OOS`, la
  exigencia de `routedIntent` en las declinaciones y el recuento de fugas como criterio duro de cada
  turno **y** como total sobre el número de respuestas.
- 70 turnos, **una sesión limpia y una siembra de memoria por turno**, sobre la cotización dedicada
  2307. En los 70, la memoria que el agente leyó (`loadMemoryVariables`) coincidió con la sembrada:
  **cero turnos contaminados**.
- Aislamiento: **cero** nodos de envío alcanzados, **cero** `Issue Policy` / `Save Policy Data`.
  Escrituras, todas sobre sesiones sintéticas: `Save Quotation Selection` ×10 (las de `G1a`, que es
  justo el turno de selección) y `Save Group1/2 Progress` ×4.
- Limpieza por IDs exactos: 70 sesiones borradas, **0 filas `QA-SUITE-%` en STG** al terminar.
- **Lo que costó dos repeticiones**: `D2.3` no llegó a correr (la base de STG cortó la conexión al
  sembrar) y se repitió en `-N10b` con sesión nueva; ningún turno cuenta como PASS sin haberse medido.

## Dónde queda esto para la firma de Alberto

No promuevo nada ni toco el grafo. Lo que yo pondría sobre la mesa:

1. **`#459` está cerrado** por medición: 20/20 bajas enrutadas y cerradas, con el control negativo
   intacto. Esto sí lo doy por arreglado.
2. **La fuga NO está cerrada**: 8 de 70, todas en el primer mensaje. Es el turno más frecuente que
   existe —todo cliente tiene uno—, y lo que se filtra incluye `paquete="3"` y `forma_pago="C"`.
3. **`D3` 4/10 y `D2` 2/10** de despedidas indebidas es, en volumen, el doble de daño que la fuga y
   sigue sin tocar.

Si quieres que mida la fuga con N≥20 sobre `D2` para declararla defecto estable, o que pruebe una
variante del texto, dímelo y lo corro: son ~25 minutos para 20 pasadas de un caso.

— Agente QA & Testing
