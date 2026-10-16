# Informe — SESIÓN A · (f) `#596`: la pausa con el texto 3 y sin «solo hoy» en el prompt

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`: adenda 10 (solo fuera del carril de descuentos) y adenda 11, punto 2.
**Textos:**
- bandeja `textos-montserrat-596`, texto 3, con y sin descuento;
- `urgencia-hoy-596` (H).

**PROD:** nada.

## Import

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Bot `dNqtM20ij6ecZYAX` | `820c08d4` → **`c39407d1`** | `Merge Session Data`, `AI Agent` (systemMessage) |

- **Verificación:** hojas y `connections` iguales al candidato; activo; export sincronizado a `stg`.
- **Respaldo:** `backups/596/`.
- **Código:** `scripts/596/` (rama `fix/firmas-paquete-prompt-stg`, `0d1766fa`). Fuente única: `pausa596.js`, batería 8/8.

## Delta por hunk

| # | Nodo | Hunk | Por qué |
|---|---|---|---|
| 1 | `Merge Session Data` | al principio, la copia literal de `pausa596.js` | la fuente única del texto 3 |
| 2 | `Merge Session Data` | después del bloque `despedidaFija`: **si la despedida elegida es D2**, su `copy` pasa a ser el texto 3 | ver las dos variantes debajo de la tabla |
| 3 | `AI Agent` · systemMessage, MANEJO DE PAUSA | el gancho literal de D2 se sustituye por el texto 3 **sin descuento** (sin 12 MSI) | ver el detalle debajo de la tabla |

**Hunk 2, las dos variantes:**
- **Con descuento y cifra:** con `descuento_comunicado = true` (d156 enviado) y `prima_anual_vigente`, va la cifra.
- **Sin descuento, sin 12 MSI:** en cualquier otro caso, incluido «con descuento pero sin precio». Así nunca hay una cifra inventada.
- **Lo que no cambia:** `texto` sigue siendo `D2`, así que la regla de «una vez por sesión» (`gancho_pausa_usado`) y el motivo `despedida_D2` no cambian.

**Hunk 3, detalle:**
- Era **la única promesa de «hoy» del prompt** («tu cotización con Quálitas hoy tiene precio preferencial…»), medida con un barrido de `solo hoy|vence hoy|para hoy|únicamente hoy|válido hoy|hoy tiene|hoy mismo` sobre todo el bot.
- **El «vence hoy» del `#567` no está en el prompt** (es de Django / el poller).
- Las otras coincidencias son legítimas: «30 días a partir de hoy», el Intent Router y comentarios de código.
- **El `RAG IA Agent` no lleva el gancho:** medido, no se toca.

**Lo que NO toqué, y por qué:**
- `despedida.js` queda intacto. Su copia literal vive también en `Parse Discount Classification` y en `Message Budget Guard`. El primero es un **nodo de la sesión B**; ahí D2 no se usa para responder (solo `clasificaDespedida`).
- Por eso el texto 3 entra como **sustitución en `Merge Session Data`** y no editando `TEXTOS_418`.
- El texto 2 y la pausa que ofrece el descuento: aparcados para B (adenda 10).

**Los 12 MSI:**
- **Lo que cambié:** el texto 3 sin descuento firmado dice «3, 6 o 12 meses»; por la adenda 10 queda **«a 3 o 6 meses sin intereses»** hasta el `#592`. Es el único cambio sobre el literal firmado.
- **Lo que no he tocado:** los 12 MSI que quedan en otras partes del prompt y del grafo (L266, L348, L353; FFG; `Parse Discount Classification`). Es el punto 17 del `#486`.

## Aceptación (arnés, sin envíos)

Script: `scripts/596/aceptacion-596-stg.py`.

**Cotizaciones elegidas por lo que hay en STG:**
- **3005: sin d156 enviado.** La 2345, que usaba antes, sí lo tiene; medido.
- **5540: con d156 enviado.** No se siembra nada en tablas de descuentos.

| Caso | Cambio, N=3 | Vivo `c39407d1`, N=1 | Control sin cambio, N=1 |
|---|---|---|---|
| «Lo voy a pensar», sin descuento → texto 3 sin descuento, literal | 3/3 | 1/1 | 0/1 (sale D2 con «hoy tiene precio preferencial» y 12 MSI) |
| «Lo voy a pensar», con descuento → texto 3 con `*$14,943.77 MXN*` = `prima_anual_vigente` | 3/3 | 1/1 | 0/1 |
| Una vez: la 2.ª pausa → D1 | 3/3 | 1/1 | 1/1 |
| Regresión: «Gracias» → D1, sin cambios | 3/3 | 1/1 | 1/1 |

**Regresión del `#418` completo sobre el vivo:**
- **Lo que pasa igual:** D1, D3, D4, D5, D2bis, `reg` y `neg`, como antes.
- **D2, 10/10 «fallos», esperados:** el arnés comprueba el D2 viejo literal, y ahora sale el texto 3.
- **Los dos `N-captura`, aparte:** su fallo era el `#612`, que no tiene que ver con esto. Ya está arreglado: el grupo `neg` da 36/36.

## No ejercitado
- La pausa cuando el turno lo atiende el **modelo** (hunk 3) y no el carril: el carril la intercepta antes en todos los casos del arnés.

Agente: Agente n8n · A
