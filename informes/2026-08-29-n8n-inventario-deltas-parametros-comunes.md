# Inventario — los cuatro deltas de parámetros sin reconciliar (STG `ecab128b` ↔ PROD `1f24d35f`)

**De:** Agente n8n · **Fecha:** 2026-08-29 · **Responde a:** dictamen `cdfdd2f` §3.
Método: diff campo a campo de `parameters` en los cuatro nodos, y `git log -S` sobre el export `_stg` para la procedencia. Nada promovido: inventario, como pediste.

| Nodo (delta) | Qué es, exactamente | Iniciativa (commit) | ¿Cambia lo que recibe un cliente? |
|---|---|---|---|
| `AI Agent` (−1.377 en PROD) | Bloque «ASEGURAR LIGA DE PAGO — HYL-WAI #207» del systemMessage: cuándo llamar a `Ensure Payment Link` (solo petición explícita, una vez por turno), de dónde sale `cotizacion_id`, qué compartir por estado | **#207** (`7e130aa feat(#207): asegurar liga de pago bajo demanda`) | **SÍ** — sin él, el agente de PROD no tiene la instrucción de consultar la tool |
| `Parse Router Output` (−1.112) | Override determinista: petición explícita de liga propia → carril operacional (`contracting`), porque el clasificador probabilístico puede leer «pago» como FAQ | **#207** (mismo linaje, `b643eba`/`7e130aa`) | **SÍ** — en PROD la petición de liga puede irse a `kb_query` |
| `Intent Router` (−159) | «REGLA #207 — liga propia»: toda petición explícita de la liga de SU cotización/póliza es `contracting`, nunca `kb_query` | **#207** | **SÍ** — mismo efecto de ruteo |
| `Session Context Builder` (−99) | Anexa al contexto el texto que acompaña a una imagen: «El cliente escribió junto a la imagen: …» | **#232** (`0b38848 fix(#232): amortiguador…`) — la pieza que casa con el `Buffer Compose` («el texto viaja con ella») | **SÍ** — en PROD, un cliente que manda imagen con texto **pierde el texto** |

## La consecuencia ya observada: los tres primeros SON la causa del hallazgo de la liga

Exec `17444` de esta mañana («quiero mi liga de pago» → el bot no llamó a la tool): **la promoción del #207 llevó la tool («un nodo y una arista», tal como se definió el paquete) y dejó atrás su capa conversacional entera** — ruteo (Intent Router + Parse Router Output) e instrucción del agente. La tool está en el grafo de PROD y nadie le dice al agente cuándo usarla. Es el mismo patrón del #244 pieza 1, tres veces más, y de la misma noche. Anotado en `HYL-WAI#207`.

## El cuarto es del paquete de anoche

El anexo de imagen del `Session Context Builder` era parte funcional del amortiguador (#232) y se quedó fuera por la misma ceguera del censo de nodos. Efecto real: en PROD, ráfaga con imagen+texto entrega la imagen sin su caption al agente.

## Recomendación (tuya la decisión)

Los cuatro son candidatos a UN mini-paquete de parámetros comunes (mismo molde que el del #244 pieza 1, que espera la orden de Alberto): copiar los cuatro campos de STG tal cual — ninguno necesita traducción de entorno. Aceptación conversacional: «quiero mi liga de pago» sin póliza → llama a la tool y responde el copy de `not_available` (cierra el hallazgo del #207); imagen con texto → el agente ve el caption. Si prefieres viajes separados (#207 ×3 y #232 ×1), los números no cambian.

Y la regla de tu §5 queda incorporada a mi método: todo paquete futuro lleva diff de parámetros de nodos comunes, con lo que se lleva y lo que se queda dicho por nombre.

— Agente n8n
