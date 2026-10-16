# Informe — SESIÓN A · `#551 (ii)` en STG: el nombre sin partir se deduce y lo confirma el resumen

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md`, adenda 15 (Alberto).

**STG:** bot `575da028` → **`e8695148-4a16-459a-a58f-244471977184`**. Hojas y connections iguales al candidato; activo.
- Respaldo: `backups/551nom/…`.
- Repo: rama `feature/551-nombre-se-deduce`, mergeada a `stg` (`7d901621`).

## Dónde vivía la regla, y el delta

**El «pídeselos por separado» vive SOLO en `pendienteRecovery`** (`scripts/551p/precarga.js`). Esa función va copiada literal en `Merge Session Data` y en `Validate Recovery Envelope`.
- Barrí `por separado | no lo partas | nombre_sin_partir | nombre_completo` en todos los nodos del STG vivo.
- **El systemMessage no tiene nada de este caso.** Las apariciones de «por separado» que hay en él son del pago y del número de la calle.

**El delta:** 1 línea, la misma en los 2 nodos y en `precarga.js` (las dos copias siguen siendo literales, comprobado).

| | Texto que llega al `[CTX:]` como `pendiente=` |
|---|---|
| **Antes** | `nombre por separado: … (tenemos «X»; pídeselos por separado, no lo partas tú)` |
| **Después** | `nombre por separado: … (tenemos «X». NO lo partas tú: pide sus apellidos, paterno y materno. En cuanto los dé, si «X» termina con esos dos apellidos, su nombre(s) es lo que queda delante: guárdalo con los apellidos SIN preguntárselo y sigue con lo que falte; lo confirma el resumen. Si no casan o falta alguno, pídele su nombre(s) y sus apellidos por separado)` |

**Cuándo cambia el texto:** solo cuando falta alguna parte del nombre **y** hay `nombre_completo`. En cualquier otro caso esa rama no se ejecuta.

**Es instrucción en el `[CTX:]`, así que para PROD cuenta como prompt.** Va con la orden de Alberto. En PROD existen las 2 copias (viajes A y B).

## Aceptación (arnés sin envíos, ×3; nombre completo «María José de la Fuente Ruiz»)

| Caso | Resultado |
|---|---|
| (ii) «Mi apellido paterno es de la Fuente y el materno Ruiz» → «No, no requiero factura» | **3/3**: con los apellidos guarda `María José` / `de la Fuente` / `Ruiz`, sin ninguna pregunta sobre el nombre, y en el turno siguiente llega al resumen («María, ¿está todo correcto? …» con «María José de la Fuente Ruiz») |
| Control: «Mi apellido paterno es Gómez y el materno Ruiz» (no casan) | **3/3**: no guarda nada y pregunta («no coinciden con el nombre que tengo registrado…») |
| Apellidos y factura en el MISMO mensaje: «Mis apellidos son de la Fuente y Ruiz, y no necesito factura» | **2/3** van directos al resumen. **#2 pide el RFC.** |
| Regresión (i) S2 | **3/3** al resumen |
| Regresión (iii) S1 | **3/3** |
| Regresión (iv) S5, uno a uno | **3/3** |
| Regresión (iv) S5m, mezclado | **2/3**. #2 repregunta la dirección precargada. |

**Por qué falla el #2 del mismo mensaje.** Es la misma raíz que tenía el caso (i).
- `rfcBase` se calcula al empezar el turno, y en ese momento todavía no hay nombre: la precarga solo trae el nombre completo, y el arreglo del (i) solo rescata la fecha del turno.
- Así que en ese turno no llega `rfc_base`, y el prompt manda pedir el RFC completo.
- 2 de 3 no lo piden y emiten con la base del turno siguiente.
- **No propongo arreglo.** El nombre no se puede sacar del mensaje con fiabilidad, como sí la fecha. Lo dejo medido para que lo juzgues.

**Por qué el S5m #2 no viene de este cambio.**
- La línea nueva no se ejecuta en S5m, porque no falta ninguna parte del nombre (`nom.length = 0`): el `[CTX:]` es idéntico por construcción.
- La repregunta es por la dirección: la semilla del arnés tiene un domicilio de Campeche con un CP de CDMX.
- En la tanda anterior, sin el cambio, S5m dio 3/3.

Agente: Agente n8n · A
