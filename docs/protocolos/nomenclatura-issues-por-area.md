# Nomenclatura de issues por área funcional

> Propuesta del Arquitecto · 4 sep 2026 · **pendiente de aprobación de Alberto y de aviso a Juan**
> Ámbito: `aguayo-co/HYL-WAI`, los **71 issues abiertos** el 4 sep 2026. Los cerrados no se tocan.

## La regla

1. **El número nunca cambia.** `#270` es `#270` para siempre: es la referencia canónica y ninguna cita de documentos, commits o handoffs se rompe.
2. **El prefijo va en el título y como label `area:*`.** El título es para leer de un vistazo; **la label es para filtrar** — GitHub filtra por label, no por prefijo de texto.
3. **Un solo prefijo por issue**, elegido por el **efecto sobre el cliente**, no por el sistema donde vive el código. Si de verdad hacen falta dos, el issue está mal cortado y se parte.
4. **`INFRA_` no es el cajón de descarte.** Un issue va ahí porque *es* de plataforma, no porque no encajara en otro sitio.
5. **Los nuevos nacen con prefijo y label.**

Formato: `DCTO_ [n8n][crítico] Texto del issue`
Al renombrar se **elimina el tag redundante** (`[Descuentos]` sobra si el prefijo ya es `DCTO_`).

## Catálogo

| Prefijo | Área | Abiertos |
|---|---|---|
| `DCTO_` | Descuentos, ofertas, recotización comercial | 17 |
| `INFRA_` | Plataforma, seguridad, esquema, testabilidad, trazabilidad, docs | 15 |
| `CONV_` | Conversación: copy, guardrails, seguimientos que interrumpen | 13 |
| `PAY_` | Pagos, ligas, recibos, cobranza, recordatorios de pago | 8 |
| `EMIS_` | Emisión y estado de póliza | 7 |
| `WA_` | Canal WhatsApp: entrega, plantillas, control de sesión | 4 |
| `DASH_` | Dashboard | 4 |
| `DATA_` | Contenido del producto: coberturas, sumas, deducibles, vigencia | 3 |

## Clasificación

### `DCTO_` (17)
315 · 313 · 305 · 304 · 303 · 301 · 288 · 270 · 266 · 259 · 248 · 243 · 233 · 205 · 196 · 190 · 161

### `INFRA_` (15)
312 · 276 · 257 · 238 · 224 · 183 · 178 · 157 · 147 · 146 · 134 · 131 · 130 · 122 · 78

### `CONV_` (13)
306 · 297 · 296 · 285 · 262 · 261 · 256 · 245 · 227 · 223 · 204 · 163 · 124

### `PAY_` (8)
289 · 281 · 272 · 241 · 231 · 207 · 160 · 144

### `EMIS_` (7)
307 · 280 · 279 · 277 · 275 · 220 · 119

### `WA_` (4)
159 · 128 · 127 · 126

### `DASH_` (4)
290 · 287 · 286 · 284

### `DATA_` (3)
194 · 206 · 271

## Los seis que decidí con criterio, y que conviene revisar

| Issue | Va a | Por qué, y qué se discute |
|---|---|---|
| **304** adquisición genera varios Lead | `DCTO_` | Nace del carril de descuentos, pero su efecto es sobre reportes y funnel. Cabría en `DASH_` |
| **312** el carril no se puede ejercitar | `INFRA_` | Es testabilidad, pero solo afecta a descuentos. Pierde la asociación con `DCTO_` |
| **183** la emisión no queda en el historial | `INFRA_` | Es trazabilidad; el efecto sobre el cliente es nulo, sobre nuestra capacidad de auditar es total |
| **204 · 227 · 163 · 124** seguimientos | `CONV_` | Van juntos con el `306` porque comparten defecto: **interrumpen la conversación**. El `124` podría ser `PAY_` si se considera recordatorio de cobro |
| **206** ofrece Limitada por iniciativa propia | `DATA_` | Es conducta conversacional sobre el producto. Cabría en `CONV_` |
| **78** leads duplicados en el formulario | `INFRA_` | Es idempotencia de captación; no hay prefijo de captación en el catálogo |

## Aplicación

1. Aviso a Juan **antes** de la tanda: renombrar 71 issues genera 71 eventos en su repo.
2. Título + label `area:*` en una sola pasada. GitHub registra el cambio de título en el historial de cada issue.
3. Este documento queda como índice `número → prefijo` en el momento del cambio.
4. Los cerrados no se tocan.

Agente: Arquitecto-IA-Qualitas
