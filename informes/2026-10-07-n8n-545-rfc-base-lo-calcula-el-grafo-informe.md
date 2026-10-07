# Informe #545 — la base del RFC la calcula el grafo con el algoritmo del SAT (STG)

**De:** Agente n8n · **Para:** Arquitecto · **7 oct 2026**
**Responde a:** `Agente-n8n:handoffs/2026-10-07-545-rfc-base-lo-calcula-el-grafo.md`.
**Estado:** aplicado en STG.
- Corpus real: 81/88, con 0 fallos del algoritmo.
- Casos de borde: 9/9.
- En vivo: el grafo pone la base calculada en el registro de emisión y en el resumen.
- El resumen visible para el cliente no llegó a salir (detalle abajo).

**PROD no está tocado.**

## Dónde y por qué

- **Workflow:** `Issue Policy Guard` (STG `PuogahK4qv9YOiF4`). **`86086e91` → `ef5c76c5`.** Respaldo:
  `backups/545/ipg-stg-86086e91-20261007T234254Z.json`.
- **Nodo nuevo `Calcular Base RFC`** (Code), entre `Read Emission Record` y `Build Emission Record`.
- **Por qué ahí:**
  - `Build Emission Record` (#536) es el **único productor** de las dos cosas que importan: el cuerpo de emisión, que va a
    Django, y los `_datos` que pinta el resumen, que sale en modo `resumen`.
  - Lee `$input.all()`, y nadie más lee `Read Emission Record` por nombre (medido). Con un solo nodo, emisión y resumen
    usan la calculada.
- **Qué hace:**
  - Calcula la base con el `grupo1` del registro (nombre, paterno, materno y fecha).
  - Sustituye los 10 primeros caracteres de `grupo2.rfc` y **conserva la homoclave del cliente**.
  - Si difiere de la del modelo, gana la calculada y queda anotado en `_rfc_545` (`calculada`, `modelo`,
    `desacuerdo`), más un `console.log`.
  - Sin nombre, paterno o fecha no toca nada (`faltan_datos_grupo1`). Si no hay RFC en el registro, tampoco lo inventa
    (`sin_rfc_en_registro`): el flujo de factura sigue pidiéndolo como hoy.
- **Un solo sitio:**
  - El algoritmo vive en `Agente-n8n:scripts/545/rfc-base.js`.
  - El builder lo inyecta **verbatim** en el nodo y comprueba después del PUT que el código desplegado es exactamente ese
    fichero más el envoltorio.
  - El arnés ejecuta el mismo fichero.
- **Lo que el nodo no hace:** no reescribe `whatsapp_sessions.captured_data` en la BD. El registro persistido conserva la
  base del modelo; lo que **lee** la emisión y el resumen es la calculada. Persistirla exigiría un segundo nodo
  (escritor), y el handoff pedía un diff de un solo nodo. Si la quieres también en la BD, es un nodo Postgres lateral; dime.
- **Diff contra el respaldo:**
  - hojas: solo `Calcular Base RFC/jsCode`;
  - connections: `Read Emission Record` → `Calcular Base RFC` → `Build Emission Record`;
  - el resto idéntico y el workflow activo.
- **El bot no se toca.**
- **Código:** rama `fix/545-rfc-base-calculada` (`e212c1bd`), `scripts/545/`.

## Algoritmo (SAT, persona física)

- 1.ª letra del paterno + 1.ª vocal interna del paterno + 1.ª letra del materno + 1.ª letra del nombre, y fecha `AAMMDD`.
- Nombre compuesto: JOSÉ/J./MARÍA/MA./M. con segundo nombre → se usa el segundo.
- Partículas: DE, DEL, LA, LAS, LOS, Y, MC, MAC, VON, VAN, DA, DAS, DI, DIE, DD y MI se saltan.
- Ñ → X; sin acentos ni diéresis.
- Paterno de 1 o 2 letras: paterno + materno + 2 letras del nombre.
- Palabras inconvenientes de la lista oficial: la última letra pasa a `X`.

**Un punto que te paso:** **sin apellido materno**, el handoff dice «`X` en la 3.ª letra». El instructivo del SAT para
el RFC dice «primeras dos letras del apellido + primeras dos del nombre»; la `X` es la regla del CURP.
- Lo dejé **parametrizado**, con `X` por defecto, como pide el handoff.
- El corpus no lo decide: **ninguno** de los 88 asegurados carece de materno, y las dos variantes dan 81/88.
- Si quieres la del SAT, es cambiar el valor por defecto en `rfc-base.js`.

## Aceptación

| # | Resultado | Evidencia |
|---|---|---|
| 1 | **81/88**; los 7 desacuerdos son **RFC mal guardados, ninguno es fallo del algoritmo** (detalle abajo) | `qualitas_asegurado` de PROD, solo `SELECT`: 88 con RFC, 84 de ellos con póliza emitida. Comparación con los 10 primeros caracteres del `rfc` guardado. |
| 2 | **PASS 9/9** | «Ana Prueba Quality» 01/01/1990 → `PUQA900101`. Pérez Gómez Juan → `PEGJ…` (el ejemplo del prompt). José Luis → usa Luis. María Fernanda → usa Fernanda. «de la Cruz» → `CU…`. Sin materno → `X`. Ñ → `X`. Palabra inconveniente `PUTO` → `PUTX`. Paterno de 2 letras («Ek») → `ECJU`. |
| 3 | **Grafo PASS / resumen visible no alcanzado** | Teléfono de Alberto, sesión sembrada con datos **ficticios** («Ana Prueba Quality» y la base mala del modelo, `PRUQ900101`). Ejecución del bot 80960 → `Get Emission Record` → **IPG 80962**: `Calcular Base RFC` = `{calculada: PUQA900101, modelo: PRUQ900101, desacuerdo: true}`; `Build Emission Record`: `rfc` y `_datos.rfc` = **`PUQA900101`**. El modelo no pintó el resumen porque faltaba la selección de cotización (`_faltan: paquete, forma_pago`): antes pidió confirmar la cobertura. |
| 4 | **PASS** | Diff: arriba. |

**Evidencia del defecto original en STG:** la ejecución 78237 de IPG (6 oct) **emitió** con `PEQA900101` para «Ana Prueba
Quality»; lo correcto era `PUQA900101`.

**Sesión de la prueba:** `waq_2678_8b1ecc292c44`. Su fila previa está en `backups/545/`; le devolví la captura y la fase y
**la cerré**.

### Los 7 desacuerdos del corpus (solo ids)

| id asegurado | Póliza | Clase |
|---|---|---|
| 1868 | emitida | 3.ª letra `X` aunque había materno (el modelo) |
| 1877 | emitida | No se saltó la partícula «Del» del paterno |
| 1889 | emitida | 4.ª letra equivocada |
| 1893 | emitida | Tres letras del paterno en vez de letra + vocal interna |
| 1896 | emitida | El RFC guardado es de **otra persona y otra fecha**: ¿factura a nombre de un tercero? |
| 1900 | emitida | Base partida: 8 caracteres en `rfc` y 2 en `homoclave`. La base real coincide con la calculada |
| 1914 | emitida | Registro sintético de prueba |

Quálitas aceptó esas emisiones aunque la base estuviera mal; el rechazo 239 del 4 oct en STG no es sistemático.

## Pendientes que anoto

- **Línea contradictoria del `systemMessage`** («[2 letras apellido paterno][vocal interna]…»): **no se ha tocado**. Se
  corrige aparte, con la firma de Alberto.
- **Resumen visible con la base calculada:** se acredita en la próxima conversación de STG que llegue al resumen completo.
- **El caso 1896** (RFC de un tercero): si la factura a nombre de otra persona es un flujo legítimo, la base calculada
  **lo pisaría**. Hoy la sustitución no distingue titular de facturación. **Decide tú** si hace falta una excepción.

— Agente n8n

---

## Adenda (7 oct): solo se sustituye la base cuando es del titular (handoff `66358c27`)

**STG `Issue Policy Guard`:** `ef5c76c5` → **`b431ad23`**. Respaldo: `backups/545/ipg-stg-adenda-ef5c76c5-20261007T234746Z.json`.

**Diff contra el respaldo:**
- solo `Calcular Base RFC/jsCode`;
- el builder exige de nuevo que el código desplegado sea `rfc-base.js` + el nodo, verbatim;
- connections idénticas; el workflow activo.

**Qué cambia:** antes de sustituir, dos guardas nuevas. En los dos casos no se toca nada y se anota el motivo en `_rfc_545`:
- **sin apellido materno** → `sin_materno_no_se_toca`: gana lo que haya;
- **la fecha `AAMMDD` del RFC del registro no coincide con la del titular** → `fecha_distinta_no_es_titular`.

Solo se sustituye con materno y misma fecha, cuando difieren las 4 letras.

**Bordes del nodo: 6/6.**
- `PRUQ900101AB1` → `PUQA900101AB1`, sigue sustituyendo y conserva la homoclave.
- Base ya correcta → sin cambio.
- Sin RFC → no se toca.
- Faltan datos → no se toca.
- Sin materno → no se toca.
- Fecha distinta (`AUCL901022…`) → no se toca.

**Corpus de PROD (88) con la lógica completa del nodo:**
- **82 coinciden.**
- **4 se sustituyen** (1868, 1877, 1889, 1893): los errores de letras del modelo.
- **2 no se tocan por fecha distinta:**
  - **1896**: el RFC de un tercero; queda **no se toca**, como pedías;
  - **1914**: el registro sintético.
- El **1900** pasa a coincidir: en el registro, la base partida en `rfc` + `homoclave` se lee junta.

— Agente n8n
