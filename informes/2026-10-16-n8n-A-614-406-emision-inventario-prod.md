# Inventario — SESIÓN A · a PROD: `#614`, `#406` y la emisión determinista (4 viajes), antes de los PUT

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-orden-prod-614-406-emision.md` + adenda 1.

**Bases medidas hoy por API:**
- bot **`31cdd989-78f1-4368-a878-36c3a68f8918`**;
- Issue Policy Guard **`3e196c7b-ebee-42ad-9d0b-cf0680922986`**.

**Método:** los cuatro candidatos se construyen **en cadena** sobre el PROD vivo, en local, cada uno sobre el anterior, con los scripts de cambio. **Nada copiado de STG.** La sintaxis de todos los nodos de código está comprobada.

## Diferencias de PROD con STG, medidas

- **`Validate Recovery Envelope` y `estadoRecovery` (#551) no existen en PROD.** El viaje 3 no los lleva; la variante es `scripts/614/cambio_614_prod.py`.
- **`Save Group2 Progress` de PROD** guarda `'placas', $1::text` (sin la precarga del #551). Variante: un marcador pasa a NULL con el mismo CASE.
- **La plantilla del resumen de PROD** ya dice «Placas: [PLACAS si proporcionadas]» (sin el #486), así que ese hunk sobra.
- **`URL Fidelity Guard` y `URL Sources` no existen en PROD:** allí la cadena es `Figure Fidelity Guard → Email Fidelity Guard`. El viaje 4 usa `cambio_emision.aplicar(con_url_guard=False)`.
- **`chat_watermark`**, que usa `Lee Poliza Emitida`, **sí está** en el `Resolve Session` de PROD.
- **«Django N8N_TOKEN PROD»** = `2Vmw0G00lulXxDCa`, la de las 9 llamadas del bot a Django.

## Viaje 1 · Guard · `#614` (base `3e196c7b`)

| Nodo | Hoja | Delta |
|---|---|---|
| `Check Placas` | `jsCode` | `placasVacias` (vacía o un marcador) → válida; si tiene valor, el regex de siempre |
| `Build Placas Error` | `jsCode` | el `msg` ofrece corregirlas o emitir sin placas; `reason: placas_invalidas` |

Sin altas ni bajas; `connections` idénticas.

## Viaje 2 · Guard · `#406` (sobre el 1)

| Nodo | Hojas | Delta |
|---|---|---|
| `Call Issue Policy Real` | `authentication`, `nodeCredentialType` + credencial | `predefinedCredentialType` / `httpHeaderAuth` = **«Django N8N_TOKEN PROD»** (`2Vmw0G00lulXxDCa`). URL, cuerpo, timeout y errores sin tocar |

`connections` idénticas.

## Viaje 3 · bot · `#614` (base `31cdd989`)

| Nodo | Hoja |
|---|---|
| `Validate Personal Data` | `jsCode`: el formato, solo si vienen placas |
| `Save Group2 Progress` | `query`: marcador → NULL (variante PROD) |
| `Merge Session Data` | `jsCode`: `pendiente` = «número de serie» |
| `AI Agent` | `systemMessage`: **14 hunks, todos `#614`**. Son los del informe de STG (`8fef888`) salvo el de la plantilla del resumen: bloque PLACAS (OPCIONALES) con P1 «COPIADO EXACTO»; P2 en las peticiones; título del Grupo 2; la serie del descuento; foto con un solo dato; `pendiente=número de serie` ×3; tope de lecturas; guardar el Grupo 2; `issue_policy` (placas opcional) |

**Lo que no cambia:** el `RAG IA Agent` intacto, sin altas ni bajas, y `connections` idénticas.
**Sale a la vez que el Dashboard (`dio_vin`):** te aviso antes del PUT.

## Viaje 4 · bot · emisión determinista, (c) + adenda 12 (sobre el 3)

**Nodos nuevos:**
- `IF Componer Emision?`;
- `Lee Poliza Emitida`, con `liga_turno`;
- `IF Hay Poliza Del Turno?`, que solo llama a la API si no hay liga del turno;
- `Pide Liga Emision`: copia la configuración de la tool `Ensure Payment Link` de PROD, con su URL y su credencial;
- `Compone Mensaje Emision`: primero la liga del turno, después la de la API, y b1 solo sin ninguna.

**`connections`:**
- `Apply Guardrail Result` → `IF Componer Emision?`, en lugar de ir directo a `Strip Guardrail Marker`;
- la rama falsa y la salida de `Compone` van a `Strip Guardrail Marker`.

**Lo que no cambia:** ningún nodo existente se modifica, y el systemMessage tampoco.

**Sin `URL Fidelity Guard`, como en PROD:** lo he probado en STG con el arnés `--como-prod`, que quita `URL Sources` y `URL Fidelity Guard` y une `Figure Fidelity Guard → Email Fidelity Guard`, igual que en PROD. Resultado: **12/12** (los seis casos, N=2):
- contado con la liga del turno;
- el 99341 (liga del turno + API 503);
- mensual con la liga de la API;
- 202 → b1;
- la API real;
- control: una pregunta posterior no recompone.

El mensaje sale entero, con la liga: sin ese guard no hay nada que la quite.

## Plan

Cada viaje, en este orden:
1. respaldo del vivo;
2. comprobación de la base;
3. **SÍ de Alberto en mi sesión**;
4. PUT;
5. diff contra el respaldo (solo esas piezas), `connections`, activo y `versionId`;
6. espejo;
7. informe;
8. **tu verificación** antes del siguiente.

Agente: Agente n8n · A
