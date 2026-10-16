# Informe — SESIÓN A · (g) `#593`: la serie de la foto que no cuadra con el vehículo cotizado

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila g.
**Texto:** el aprobado por Alberto el 14 oct.
**PROD:** nada.

## Import

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Bot `dNqtM20ij6ecZYAX` | `f0b69aee` → **`676069a3`** | `Parse VIN Extraction`, `AI Agent` (systemMessage) |

- **Verificación:** hojas y `connections` iguales al candidato; activo; export sincronizado a `stg`.
- **Respaldo:** `backups/593/`.
- **Código:** `scripts/593/` (`51f50f32` y anteriores). Fuente única: `nota593.js`, batería 9/9.

## Delta por hunk

| # | Nodo | Hunk | Comportamiento |
|---|---|---|---|
| 1 | `Parse VIN Extraction` | al principio, la copia literal de `nota593.js` | la fuente única |
| 2 | `Parse VIN Extraction` | antes del `return`: se añade al `chatInput` de la tarjeta la nota `[SERIE_FOTO_NO_CUADRA] marca=…, año=…`, con el texto aprobado y la orden de copiarlo exacto y no guardar la serie | las condiciones, debajo de la tabla. `vinValid` **no cambia**: la serie no se propone (`serie_foto` sin tocar) ni se guarda |
| 3 | `AI Agent` · systemMessage, bloque `[FOTO_VIN]` | una viñeta: el marcador es interno; se responde con el texto que trae, copiado exacto; y NO se guarda esa serie ni se dice que se tiene | |

**Hunk 2, cuándo se añade la nota.** Tienen que cumplirse todas:
- es una tarjeta y no se ha llegado al tope;
- formato OK, pero `vinValid = false`;
- confianza **alta**;
- el año **o** el WMI en `fail`;
- la **marca del WMI conocida**.

**Qué va en la nota:** «[MARCA AÑO del VIN]», donde el año es el más reciente de los plausibles que no pase de año en curso + 1, y el vehículo es el `vehiculo` de la cotización.

**Lo que se queda como hoy:** sin marca conocida, o con solo el dígito verificador en `fail` (que apunta a una lectura mala, no a otro auto), no hay nota.

## Aceptación

**Montaje:** visión real e imagen embebida, la tarjeta **sintética** del `#581`, de un NISSAN. Sin Meta ni envíos. Script: `scripts/593/aceptacion-593-stg.py`, sobre las piezas del arnés del `#609`.

| Caso | Cambio, N=3 | Vivo `676069a3`, N=1 | Control, N=1 |
|---|---|---|---|
| **NO-CUADRA:** cotización 2345, CHEVROLET TAHOE 2020, con la tarjeta Nissan (WMI `fail`, confianza alta) → «…es de un **NISSAN 2020**, y estamos cotizando un **CHEVROLET TAHOE 2020**…», literal; sin `serie_foto` ni `grupo2.serie` | 3/3 | 1/1 | **0/1**: «No logré leer el número de serie (NIV/VIN)…» (el defecto del `#593`) |
| **REG-CUADRA:** cotización 5467, Nissan Versa 2020 (todo `ok`) → sin nota; la serie se propone como siempre | 3/3 | 1/1 | 1/1 |

**Una lectura mía corregida en el arnés.** Primero usé la 5540 (Versa **2024**) como «cuadra». Ahí la nota sale **con razón**: el año del VIN es 2020. La cambié por una 2020.

**Regresiones sobre el vivo:**
- `#609` 5/5;
- `#475` 4/4 (sobre `f0b69aee`, que no toca este nodo).

## Observación, no defecto
En el turno NO-CUADRA el texto aprobado sustituye a toda la respuesta. Las **placas** que se leyeron en la foto no se le proponen al cliente en ese turno: el texto aprobado no las menciona. Se piden después, en la captura normal. Si quieres que el texto las incluya, es otra firma.

Agente: Agente n8n · A
