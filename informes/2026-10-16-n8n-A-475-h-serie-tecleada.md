# Informe — SESIÓN A · (h) `#475`: la serie tecleada (O→0, I→1 con confirmación; longitud; motivo real)

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila h + adenda 11, punto 3.
**Textos:** el de la O, aprobado por Alberto (14 oct), y el de la longitud. **PROD:** nada.

## Import

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Bot `dNqtM20ij6ecZYAX` | `4b1ebf3b` → **`f0b69aee`** | `Detect Typed VIN`, `Check Typed VIN`, `Inject Serie Note`, `Save Group2 Progress` (query), `AI Agent` (systemMessage) |

- **Verificación:** hojas y `connections` iguales al candidato; activo; export sincronizado a `stg`.
- **Respaldo:** `backups/475/`.
- **Código:** `scripts/475/` (`c5e67e9d`). Fuente única: `serie475.js`, batería 24/24.

## El caso

PROD `waq_4395` (14973-14986):
1. El cliente teclea una serie de 17 caracteres con una **O**.
2. `Detect Typed VIN` no la reconoce: su regex excluye I/O/Q.
3. El bot contesta «¡Gracias! Ya tengo tu número de serie» **sin guardar nada**.
4. `Save Group2` la rechaza «sin procedencia», con un `aviso_serie` que da otro motivo.
5. Se vuelve a pedir la serie dos veces, hasta que el modelo nota la O.

## Delta por hunk

| # | Nodo | Hunk | Comportamiento |
|---|---|---|---|
| 1 | `Detect Typed VIN` | lógica nueva, `detectaSerie475` (copia literal) | ver las tres reglas debajo de la tabla |
| 2 | `Check Typed VIN` | el *patch* | si la serie viene normalizada, guarda `serie_normalizada_pendiente` y **no** `serie_tecleada`, así que `Save Group2` la sigue rechazando. Si había una pendiente y llega una serie, se borra. En el turno de la normalización se anula la nota de sospecha |
| 3 | `Inject Serie Note` | marcador `[SERIE_475]` | lleva el texto aprobado («copiado exacto; no guardes ninguna serie») o, al confirmar, la serie que hay que guardar |
| 4 | `Save Group2 Progress` (query) | `aviso_serie` con el motivo real | ver los tres casos debajo de la tabla |
| 5 | `AI Agent` · systemMessage | junto a la regla de `[SERIE_SOSPECHOSA]` | la tercera excepción, `[SERIE_475]`, y la prohibición de decir «ya tengo tu número de serie», «ya guardé tu serie» o algo equivalente sin `grupo2.serie` guardado y sin `aviso_serie` |

**Hunk 1, las tres reglas de `detectaSerie475`:**
- **17 caracteres válidos:** igual que antes.
- **17 caracteres con O o I** (sin Q y con dígitos): se normaliza (O→0, I→1) y queda **pendiente**. Un «sí» corto (≤ 6 palabras, sin «no», sin otra serie) **la confirma**, y pasa a ser la `typedVin` del camino de siempre.
- **15, 16, 18 o 19 caracteres** con letras **y** dígitos: la nota de longitud.

**Hunk 4, los motivos de `aviso_serie`:**
- lleva una letra **I/O/Q** → «lleva la letra X…»;
- **longitud distinta de 17** → «tiene N caracteres y debe tener 17»;
- si no, el motivo de procedencia de siempre.

**Textos que he derivado yo del aprobado (para que los revises):**
- el aprobado cubre **una O**;
- he derivado **una I** («la he cambiado por un uno»);
- he derivado **varias** («tenía 2 letras **O**… las he cambiado por ceros», «una letra **O** y una letra **I**… por un cero y un uno»).

**Falsos positivos de la nota de longitud, medidos en el corpus de PROD** (`n8n_chat_histories`, mensajes `human`):
- los **9** tokens de 15, 16, 18 o 19 caracteres con letras y dígitos llegan, **los 9**, justo después de que el bot pidiera la serie;
- **0 CURP**;
- **3** series de 17 con O o I, en 2 sesiones.

## Aceptación (arnés, series sintéticas, sin envíos)

Script: `scripts/475/aceptacion-475-stg.py`.

| Caso | Cambio, N=3 | Vivo `f0b69aee`, N=1 | Control, N=1 |
|---|---|---|---|
| Serie con O → el texto aprobado, literal; pendiente; **nada guardado** → «Sí, es correcto» → `serie_tecleada` = normalizada, `grupo2.serie` = normalizada, `serie_source = tecleada`, pendiente borrada | 3/3 | 1/1 | 0/1 (genérico «no me quedó guardado»; el «sí» no guarda nada) |
| 16 caracteres → texto de longitud, literal; nada guardado | 3/3 | 1/1 | 0/1 |
| Con Q (no se normaliza) → el bot da **la letra Q** como motivo; sin «ya tengo…» | 3/3 | 1/1 | 0/1 (motivo genérico) |
| Regresión: serie válida → tecleada como antes, sin `[SERIE_475]` | 3/3 | 1/1 | 1/1 |

**Nota del arnés:** `aviso_serie` no se lee bien del nodo tool en el `runData`. El motivo real se comprueba **en el texto al cliente**.

**Regresión de la foto** sobre el vivo: `#609` 5/5 (recibos, pago y tarjeta).

## No ejercitado
- La confirmación con un «sí» **largo** o ambiguo. El detector exige como mucho 6 palabras y ningún «no»; si no confirma, la pendiente se queda y la atiende el modelo.
- Q→? Ninguna normalización (no la pide la orden).

Agente: Agente n8n · A
