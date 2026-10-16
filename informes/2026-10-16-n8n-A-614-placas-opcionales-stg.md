# Informe — SESIÓN A · `#614`: placas opcionales en STG

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-placas-opcionales.md` + adendas 1 (P1 y P2 firmados) y 2 (`dio_vin`, opción a).
**PROD:** nada. Va con orden aparte y junto al cambio del Dashboard.

## Imports (dos, en este orden)

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Issue Policy Guard `PuogahK4qv9YOiF4` | `b46c8d48` → **`350fa223`** | `Check Placas`, `Build Placas Error` |
| Bot `dNqtM20ij6ecZYAX` | `119ea850` → **`b321eb6c`** | `Validate Personal Data`, `Save Group2 Progress`, `Merge Session Data`, `Validate Recovery Envelope`, `AI Agent` (systemMessage) |

- **Verificación:** hojas y `connections` iguales al candidato; activos; exports sincronizados a `stg`.
- **Respaldos:** `backups/614/`.
- **Código:** `scripts/614/cambio_614.py`, rama `fix/firmas-paquete-prompt-stg`.

## Medido antes de construir

- **Django acepta emitir sin placas:** `qualitas/forms.py:95`, `placas = forms.CharField(… required=False)`.
- **El XML de emisión a Quálitas no las lleva:** `qualitas/services.py`, `<DatosVehiculo>` con `<Serie>`. Las placas solo se guardan en la póliza.
- **El `RAG IA Agent` no tiene ninguna regla de placas.** Su única mención es «solo para actualizar placas», sobre la cobertura.
- **El checkpoint (`derivarCheckpoint`) no depende de las placas:** `vin_plates_captured` sale con que exista `grupo2`, igual que en Django. No se toca.
- **`Rebuild Summary From Record` y `Rebuild Recovery Summary` ya omiten «Placas:» si no hay.** El dato les llega limpio de `Build Emission Record`, donde las placas ya eran opcionales. No se tocan.
- **`dio_vin` del Dashboard** pedía «Placas» Y «Serie:». Te lo avisé antes de importar; tu adenda 2 lo resuelve en el Dashboard.

## Delta por nodo

**Guard**
- **`Check Placas`:** `placasVacias` = vacía o un marcador (`n/a`, `pendiente`, `sin placas`, `no tengo`…) → **`placasValid = true`**, y se emite sin placas. Con valor, el regex de siempre, `^[A-Z0-9]{6,7}$` sobre la forma normalizada.
- **`Build Placas Error`:** solo llega con placas con valor e inválidas. El `msg` ahora ofrece **corregirlas o emitir sin placas (no son obligatorias)**, con `reason: placas_invalidas`.

**Bot**
- **`Validate Personal Data`:** sin placas, o con un marcador, no es error. El formato solo se valida si vienen.
- **`Save Group2 Progress`:** un marcador ya no se guarda como placas. Antes, `COALESCE(…, $1::text)` guardaba el texto `'N/A'`; ahora queda en NULL, o se toman las de la precarga del Recovery. Además, `'sin placas'`, `'no tengo'`, `'no las tengo'` y `'no tiene'` entran en la lista de marcadores.
- **`Merge Session Data`:**
  - `pendiente` de `personal_data_captured` = **«número de serie»** (antes «placas y número de serie»);
  - en `estadoRecovery`, unas placas vacías no faltan.
- **`Validate Recovery Envelope`:** la misma línea de `estadoRecovery`, porque es una copia literal.
  - Su fuente, `scripts/551p/precarga.js`, está en la rama `feature/551-recovery-precarga`, la del `#551`, que está parado. **Queda por sincronizar**; no la toco aquí.

**`AI Agent` · systemMessage: 15 hunks, todos del `#614`**

| # | Dónde | Cambio |
|---|---|---|
| 1 | bloque «PLACAS DEL VEHÍCULO (OBLIGATORIAS)» | → «(OPCIONALES)»: se piden «si las tienes a la mano»; nunca obligatorias, nunca bloquear ni insistir; **P1, COPIADO EXACTO**, si no las tiene, y `placas=""`; ante `invalid_placas`, corregir o emitir sin ellas. **Fuera** «Un vehículo 0 km también necesita placas» y «no llames a issue_policy sin ellas» |
| 2-3 | las dos peticiones del Grupo 2 (cierre del Grupo 1 y ejemplo) | «- Placas del vehículo» → **P2** |
| 4 | título del Grupo 2 | «(placas + serie…)» → «(serie obligatoria + placas si las tiene…)» |
| 5-7 | serie que viene del descuento | se piden las placas «si las tiene a la mano (son opcionales)»; el ejemplo, sin «solo me faltan las placas»; al guardar, «o te diga que no las tiene: placas=""» |
| 8 | petición del Grupo 2 | «Placas del vehículo (6 a 7 caracteres)» → P2 |
| 9 | foto con un solo dato | solo serie → se confirma y se ofrecen las placas con P2, **nunca como pendiente**; solo placas → se pide la serie |
| 10-12 | `pendiente=placas y número de serie` (imagen ilegible, foto de otra cosa, foto del auto) | → `pendiente=número de serie` (el literal nuevo del grafo), «y las placas, si las tiene» |
| 13 | tope de lecturas | el número de serie (y las placas, si las tiene) |
| 14 | guardar el Grupo 2 | «cuando dé el número de serie (y las placas si las tiene)… placas ("" si no las tiene)» |
| 15 | notas de `issue_policy` | «**placas**: Obligatorio… NO llames a issue_policy» → «Opcional… "" si no las dio. NUNCA dejes de llamar a issue_policy por no tenerlas» |
| 16 | plantilla del resumen | «Placas: [PLACAS]» → «… (omite esta línea si no las dio)» |

## Aceptación

Arnés `scripts/614/aceptacion-614-stg.py`.
- **Montaje:** Guard temporal con el cambio y la emisión **simulada**, con la póliza que ya existe en la 3005. Bot temporal con la imagen embebida (la tarjeta sintética del `#581`). Sin envíos.
- **Una corrección por el camino:** en la primera pasada, el (a) fallaba porque el modelo **parafraseaba P1** («No te preocupes **por las placas**…»). Endurecí la instrucción a «COPIADO EXACTO, y el siguiente paso en un párrafo aparte», y la comprobación pasó a exigir P1 completo y literal.

| Caso | Cambio, N=3 | Vivo, N=1 | Control (sin el cambio), N=1 |
|---|---|---|---|
| (a) «las placas todavía no me las dan» → **P1 literal**; se guarda la serie, placas = NULL | 3/3 | 1/1 | 0/1 |
| (a2) registro sin placas → **emite** | 3/3 | 1/1 | 0/1 |
| (b) placas de la foto (5467 Versa 2020) → se proponen; con el «sí», `placas=ABC123D` | 3/3 | 1/1 | 1/1 |
| (c) placas a mano → `ABC1234` guardadas | 3/3 | 1/1 | 1/1 |
| (d) placas `AB1` → el bot pide corregirlas o seguir sin ellas; «No las tengo, emítela sin placas» → placas NULL y **emite** | 3/3 | 1/1 | 0/1 |
| (e) sin serie → **no** emite | 3/3 | 1/1 | 1/1 |

**Regresiones sobre los vivos (bot `b321eb6c`, guard `350fa223`):**
- `#475`: 4/4;
- `#593`: 2/2;
- `#609`: 5/5, que incluye la tarjeta del `#472`/`#581`.

## Para PROD (cuando haya orden)

- Los mismos dos viajes: el Guard primero, luego el bot. Se construyen con `cambio_614` sobre el vivo, y antes van el inventario y el delta por hunk contra PROD.
- Viaja **junto al cambio del Dashboard** (`dio_vin` solo con «Serie:»).
- **Pendiente:** la conversación real de Alberto en STG.

Agente: Agente n8n · A
