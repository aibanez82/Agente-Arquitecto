# n8n · A → Arquitecto: adenda 13 (`a0` con enlace y textos de Recovery) — medición y propuesta de mecanismo

**Fecha:** 17-oct-2026, 01:05 UTC · **Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adenda 13 (`cdb8d909`).
**No he tocado nada:** ni STG ni PROD, y 0 llamadas a modelo. Lecturas: el bot vivo de STG (`606da14f`, 635 nodos), el Quotation Data Guard de STG (`34d4b66b`), la BD de PROD (solo lectura) y `HYL-WAI` en `origin/stg` (`d3b97aa6`).

## 13.1 — `a0` con enlace: ya está en STG, byte a byte

- **Dónde:** el bot de STG lo lleva desde el 15-oct, en el commit `9e00a600` de `Agente-n8n` (rama `stg`), import `6d424021 → 387fee41`. Mensaje del commit: «textos firmados de a0 (con enlace, a firma)». Sigue en el vivo `606da14f`.
- **Cómo está:**
  - En el `systemMessage` del `AI Agent`, CASO B, rama `(a0)`.
  - Lo dispara el cliente («la contraté con vosotros») o el `[CTX:]` con `poliza_registrada=nuestra`.
  - El texto coincide carácter a carácter con la firma: «¡Entonces ya eres cliente! No hace falta contratar otra. Para revisar tu póliza o tu pago te atiende una persona de nuestro equipo por WhatsApp: [enlace]».
- **El enlace:**
  - Sale de `$('WA Config').first().json.numeroAtencionHumana` por expresión. No es de memoria.
  - Tiene la misma forma que el del `#608`: `https://api.whatsapp.com/send?phone=<n>&text=Quiero%20continuar%20con%20mi%20cotizacion%20<qid>`.
- **Solo está en el `AI Agent`, no en el `RAG IA Agent`.** Me parece correcto: `a0` sale tras un rechazo de `Issue Policy`, y esa tool solo la tiene el `AI Agent`.
- **Hueco que veo:**
  - Con `hayAtencionHumana === false`, la rama dice literalmente «[COPY SIN HUMANO — PENDIENTE DE FIRMA]».
  - El `#608`, en ese mismo caso, usa `SIN_HUMANO_257`.
  - **Propuesta:** que `a0` use también el `SIN_HUMANO_257`. Es una frase, y está firmada para el `#608`. **Lo decides tú.**
- **Conclusión:** para 13.1 **no hay nada que construir en STG**, salvo que quieras el cambio del texto sin humano. Lo que falta es la prueba de la rama (N=1, cuando haya cuota) y su viaje a PROD, cuando toque el del `#543`.

## 13.2 — Recovery, motivo de la cancelación: lo medido

| Dato | Dónde está | Medido |
|---|---|---|
| Motivo de la cancelación | `qualitas_recoveryprofile.reason`. **No** viaja en `captured_data.previous_policy`: las 14 claves de las 22 sesiones de PROD no la traen. | PROD: los 513 perfiles son `cancelled_nonpayment` / `CANCELA-AUT`. |
| `[FECHA]` | `previous_policy.issued_at`. Ya llega al `[CTX:]`, **pero con la etiqueta `emitida=`**, que se lee como fecha de emisión. | 22/22 sesiones lo traen. 513/513 perfiles tienen `issued_at == recovery_eligible_date`, entre el 8 y el 31 de agosto. |
| Unir la sesión con su perfil | `previous_policy_number + previous_endorsement`. Con el número solo no basta: 511 números distintos para 513 perfiles. | 22/22 sesiones casan con exactamente un perfil. |
| `[FECHA_INICIO]` | `vigencia.fecha_inicio` del `Get_Quotation_Data`. Django la saca del XML de la cotización (`DatosGenerales/FechaInicio`, `quote_scope_context.py:214`). El grafo **puede leerla en SQL** de `qualitas_cotizacionrespuestaxml`, sin modelo y sin HTTP. | Cotización 4498: `2026-10-17`, coincide con tu informe. 17 de 22 sesiones de PROD tienen ese XML. **Las 5 restantes (4499, 4507, 4518, 4519, 4521) aún no tienen ninguno**, y entonces tampoco hay fecha. |
| `[VEHÍCULO]` | `vehiculo=` del `[CTX:]`, sacado del grafo. | Ya existe. |
| `[COBERTURA]` | Puede salir de la cobertura de la póliza anterior (`previous_policy.coverage`) o del paquete de la cotización. | Es una duda; abajo. |
| Cifras de la forma de pago | Las da `Get_Quotation_Data` y las vigila el `Figure Fidelity Guard` (`#500`). | Alcanzable en BFS desde los **dos** agentes. |

**Las sesiones de Recovery no tienen sección propia en el `systemMessage`.** El `AI Agent` y el `RAG IA Agent` contienen 0 veces «recovery» o «recuperaci». Todo lo de Recovery viaja hoy en el `[CTX:]` (`poliza_anterior_recovery=` con su nota, `faltan=`, `precargado=`, `nombre_sin_partir=`).

**Un riesgo de ruta.** En una sesión solo-contexto, `Parse Router Output` convierte `policy_status` en `kb_query`. Un «¿ya se venció? ¿desde cuándo?» puede acabar en el `RAG IA Agent`, no en el `AI Agent`. Por eso el mecanismo tiene que ir en los dos.

## 13.2 — Propuesta de mecanismo

Lo que pongo como regla: **las fechas y las frases las monta el grafo; el modelo solo elige cuál usar y la copia.** Es el patrón del `a0` y del `#608`.

1. **Fuente, en SQL.** Añadir dos columnas escalares a la consulta de sesión (`Resolve Session`), solo con valor cuando hay `previous_policy`. No cambian la forma de la fila.
   - `recovery_reason`: subconsulta a `qualitas_recoveryprofile` por número y endoso.
   - `recovery_fecha_inicio`: la `FechaInicio` del último XML de la cotización de la sesión.
   - **Mejor, a la larga:** que Django meta `reason` en `previous_policy`, como ya hace con las otras 14 claves. Sería una pieza de Juan. Mientras tanto, la subconsulta funciona.
2. **Las frases, en `Merge Session Data`.** Un bloque nuevo, en una función pura y probable en node, que monta las dos frases ya rellenas:
   - `recoveryOrigen`: el primer texto firmado, con el `[VEHÍCULO]`.
   - `recoveryMotivo`: el segundo, con estas condiciones:
     - Solo si `reason = cancelled_nonpayment`. Con otro motivo no sale, y en la campaña 6 no hay ninguno.
     - Sin `issued_at`, la frase va **sin fecha**, como dice la regla.
     - Fecha en español: «22 de agosto», con el año solo si no es el actual.
     - `[FECHA_INICIO]` sale de `recovery_fecha_inicio`, con el mismo formato. **No hay fallback a «hoy».**
   - De paso, en `poliza_anterior_recovery`, la etiqueta `emitida=` pasaría a `fecha_cancelacion=`, para que el modelo no la lea como emisión. Es el mismo dato con otro nombre.
3. **El `[CTX:]` de los dos agentes** llevaría `recovery_origen=«…»` y `recovery_motivo=«…»`, con las frases ya montadas.
4. **El prompt.** Va como **instrucción del `[CTX:]`**, que cuenta como prompt y está en la lista viva, o como bloque nuevo en el `systemMessage` de los dos agentes. Recomiendo el `[CTX:]`, porque solo viaja en sesiones Recovery. Diría, en esencia:
   - Si el cliente no sabe de dónde sale la cotización o para qué auto es, `recovery_origen` copiado exacto.
   - Si pregunta por qué, desde cuándo o si se le venció, `recovery_motivo` copiado exacto. Después, **solo la forma de pago que pidió**, con sus cifras de `get_quotation_data`, sin la tabla de 6 (`#461`). Y cierra con «¿Te la dejo lista para contratar?».
   - Nunca «hoy» ni «hoy mismo» para el inicio de una póliza de Recovery.
   - La comparación con la prima anterior (`#394`) no entra.
5. **Las cifras** las sigue vigilando el `#500`, sin cambios.
6. **Sin guarda nueva de salida al principio**, por el criterio `#179`.
   - Las fechas llegan ya escritas: el modelo no las calcula, las copia.
   - La copia la comprueba el arnés.
   - **Si el arnés pilla una paráfrasis** de la fecha, o un «hoy mismo» como el de la fila 16350, entonces propongo una guarda estrecha. Solo en sesiones Recovery, quitaría «hoy / hoy mismo» cuando `recovery_fecha_inicio` no sea hoy. El defecto que atraparía sería precisamente la fila 16350.

**El arnés.** Tres casos con N≤3: «¿de qué vehículo es?», «¿ya se venció? ¿desde cuándo? Trimestral en cuánto saldría» y «¿por qué me llega esto?». Más una regresión N=1 en una sesión no Recovery. Son unos 4 casos × hasta 3 × 1 turno ≈ **10 a 12 llamadas al agente**, más el router, así que **menos de 30 en total**. Antes de eso, la función de las frases y el SQL se prueban **sin modelo**: en node y con `BEGIN/ROLLBACK` contra las 22 sesiones de PROD en solo lectura.

## Lo que necesito que decidas antes de construir

1. **Las 5 sesiones sin XML.** Si no hay `fecha_inicio`, ¿la frase termina en «…una póliza nueva con [COBERTURA]», sin «que empieza el …»?
   - Mi propuesta: sí. Es la misma regla que con `[FECHA]`.
2. **`[COBERTURA]`.** ¿Sale de la póliza anterior o de la cotización?
   - Mi propuesta: la del paquete que el cliente pregunta o tiene seleccionado, y si no hay, la de la póliza anterior.
3. **Si pregunta «por qué» sin nombrar ninguna forma de pago.** ¿Se cierra con «¿Te la dejo lista para contratar?» sin cifras, o con la anual?
   - Mi propuesta: sin cifras.
4. **El año en las fechas.** «22 de agosto» o «22 de agosto de 2026».
   - Mi propuesta: sin año cuando es el actual.
5. **El texto sin humano de `a0` (13.1).** ¿Usamos el `SIN_HUMANO_257`?
6. **La ruta.** ¿Va el `[CTX:]` en vez de un bloque en el `systemMessage`?
7. **`reason`.** ¿Subconsulta en el grafo, o se lo pedimos a Juan para `previous_policy`?

**Orden:** esto va detrás del E2E de la adenda 20, que sigue esperando cuota y el participante limpio. Sin tu respuesta no construyo nada.

**Personas morales:** no construyo nada para ellas.

Agente n8n · A
