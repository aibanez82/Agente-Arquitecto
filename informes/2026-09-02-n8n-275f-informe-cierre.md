# Informe `#275f` v3 — cierre: carril 6/6 y los bloqueantes repetidos en sesión sana. La 2316 congelada e intacta (123 → 123 en todos los pasos)

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
Handoff `59e9d87` + respuestas `154b377` (repetir en sesión sana) y la aprobación de la (i).

## 1 · Estado del vivo

Bot STG **`b29bdf71`**, 307 nodos; solo `Parse Router Output` cambió (+3 patrones, los 20 de la v2
intactos, factura fuera, `Intent Router` byte a byte). Offline 12/12 con el ancla ratificada.

## 2 · La (i), ejecutada con tu condición de método

| paso | filas de la 2316 |
|---|---|
| antes del `UPDATE` | **123** |
| tras `status: active → open` (un campo, nada más) | **123** |
| tras la desambiguación y la elección | **123** |
| tras la batería 4-6 completa | **123** |

Doble cerrojo verificado de propina: la 2316 en `open` **con póliza emitida** queda además excluida
del filtro de candidatas (`sin_poliza`) — la resolución por teléfono ya ni la ve; nada le escribirá.

## 3 · El camino a la sesión sana — y funcionó como flujo real de cliente

- «hola» → **`Format Disambiguation Message`** (carril determinista): «Encontré 5 cotizaciones
  activas… 1. #2322 … Responde con el número de la lista (1, 2, 3…)».
- «1» → **93 nodos, camino completo normal**, la 2322 queda `active` por afinidad y el bot responde
  con su Honda Odyssey 2026 y mejor precio. **Nota alegre: el mismo «1» que en la exec 28224 moría en
  el error fallback** (sesión clavada) **aquí corre entero** — coherente con que aquello fuera el
  defecto del `#297` y no otra cosa.

## 4 · Los casos 4-6 en sesión sana (waq_2322, Honda Odyssey 2026), literales

| # | Frase | Intent → quién | Literal | PASS |
|---|---|---|---|---|
| 4 | «mi factura ya está lista?» | `kb_query` → RAG | «Esta pregunta parece referirse a tu factura del seguro (no del vehículo). Para aclarar: ¿te refieres a la factura fiscal de tu póliza de Quálitas, o a algo relacionado con tu cotización HONDA ODYSSEY 2026? Cuéntame un poco más…» — al modelo, sin carril, sin desmentir nada | ✅ |
| 5 | «quiero cotizar un seguro» | `contracting` → AI Agent | «¡Con gusto! Justo tengo lista tu cotización para tu *HONDA ODYSSEY 2026* con *Cobertura Amplia, pago anual* en *$16,582.37 MXN*…» — **NO entró al carril**, conversación normal | ✅ **bloqueante** |
| 6 | «cuánto cuesta mi cotización?» | `contracting` → AI Agent | «Tu cotización para el *HONDA ODYSSEY 2026*… *$16,582.37 MXN*…» — **NO entró al carril**; el precio real que pediste: **$16,582.37**, céntimo a céntimo de `opciones_cotizacion` (los top-level de la 2322 van a NULL sin hoja seleccionada, como documenta la propia toolDescription) | ✅ **bloqueante** |

Con los 1-3 del turno anterior (`Emitted Reply` con «Sí, tu póliza 7620101919 está emitida…»
literal): **6/6, bloqueantes incluidos.**

## 5 · Dos hallazgos de regalo

- **El payload de STG ya trae `coberturas_detalle`** (con `vigencia` por opción) — la forma del
  `#194` asomando. Para la 2322 viene **vacío** (`[]`): desplegada la forma, no poblada aquí. Te lo
  dejo para tu seguimiento del despliegue con Juan — el día que venga poblado, las copys honestas del
  `#292`/`#293` tienen relevo natural (otro viaje, no lo toco).
- La desambiguación del dual funcionó de punta a punta como flujo real — primera vez que la ejercito.

## 6 · Qué queda

El `#275f` v3 cerrado por mi lado; PROD del paquete `#275f` completo lo pide Alberto (§8 del
handoff). La 2316 queda como ejemplar del `#297`: `open`, 123 filas, corte en la 6071, sin que nada
la toque.

— Agente n8n
