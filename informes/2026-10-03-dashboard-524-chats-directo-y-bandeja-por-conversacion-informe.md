# Informe — #524: el icono de WhatsApp abre Chats, y la bandeja lista toda conversación

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Responde a:** `handoffs/2026-10-03-524-chats-directo-y-bandeja-por-conversacion.md` (Dashboard, `origin/main`)

| | |
|---|---|
| Rama | `feature/524-chats-directo` = **`5c9b0c5`** |
| `stg` | `5a75c2b` → **`ae6e795`** (merge `--no-ff`) |
| Deploy STG | `dpl_48Y398Dswjjgk1homP4bz5XvvSjB` **READY** |
| Gates | **755/755**, verificador y `build` en verde; **`s1-conformidad` verde** sobre `ae6e795` (run 37070665615) |
| `main` | sin tocar. Necesita promoción aparte |

## Parte A — el icono

- `FunnelV2` (tabla del funnel **y** modal de escalón, que comparten `openChat`) y `LeadModal` navegan a
  `/?tab=inbox&lead=<id>` sin abrir `ConversationModal`. La URL la construye un solo helper,
  `/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/lib/abrirEnChats.js`.
- **Sin sesión de WhatsApp, el icono no se pinta.** `FunnelV2` ya lo hacía; `LeadModal` pintaba el 💬 siempre (en gris si no
  había contestado) y ahora lo oculta.
- **El lead pedido entra siempre.** El servidor ya lo mandaba con `?lead=`, pero el navegador lo recortaba por periodo y el
  foco no llegaba a abrirlo. Ahora `inboxDelPeriodo` lo deja pasar. Además el lead pedido se guarda aparte del foco y viaja
  **en cada recarga**: si no, a los 30 s, al limpiarse el foco, la petición salía sin `?lead=` y la conversación se caía.
- `LeadModal` se cierra al navegar (vive en `index.js` y quedaría encima de Chats).
- **Código muerto:** `ConversationModal.js` ya no lo importa nadie. No lo he borrado; si quieres, va con su orden.

## Parte B — la bandeja por conversación

- `/api/inbox` deja de cortar por **póliza, etapa (`l.estado`) y fase**. Entra todo lead con sesión, viva o archivada.
- **El periodo va al SQL** (`desde`/`hasta` como días de CDMX, o `ventana=24h`), con el mismo ancla que
  `ultimoMovimiento()`: `GREATEST(last_activity, último mensaje, fecha_creacion)`. Las cuatro columnas son `timestamptz`
  (medido en `pg_attribute`), así que `AT TIME ZONE 'America/Mexico_City'` da el mismo día que `toMXDateStr`. Las tomas
  activas y el deep link quedan **fuera** del recorte. El navegador sigue filtrando con su regla: si discreparan, gana la más
  estricta. Un periodo mal formado es **400**, nunca «todo el histórico» (lo cazó el propio test: `2026-13-45` hacía
  reventar el handler antes del arreglo).
- Comentarios de 23/24 jul y del `#493` en `api/inbox.js`: sustituidos por la decisión de hoy.

### Cambios que no pedía el handoff y que la lista nueva hacía necesarios

1. **Orden por último movimiento**, no por fecha del lead. Con la regla nueva, el lead de Alberto (21 sep, pagó el 2 oct)
   saldría con «Hoy»… al final de la lista. «Recientes» ahora significa conversación reciente.
2. **«N pendientes» → «N conversaciones»**, y el vacío dice «No hay conversaciones de WhatsApp en este periodo».
3. **Una póliza sin movimiento en 48 h ya no es «abandonada»**: es una conversación terminada. Antes no podía pasar
   (las pólizas no entraban); ahora sí, y habría pintado de rojo las ventas cerradas.

## Cifras (STG; PROD no lo puedo medir)

**`/api/inbox` en vivo**, sesión de pruebas, mediana de 3–5 llamadas:

| | Antes (`5a75c2b`) | Después (`ae6e795`) |
|---|---|---|
| Sin periodo | 77 leads · 366 kB · 700 ms | 155 leads · 703 kB · 622 ms |
| **«Hoy»** (lo que pide la pantalla) | (el navegador recibía los 77 y se quedaba con 2) | **9 leads · 37 kB · 534 ms** |
| «24h» | ídem | 9 · 37 kB · 438 ms |
| **«Este mes»** | ídem | **9 · 37 kB · 432 ms** |

La pantalla ya no pide nunca la respuesta sin periodo. En SQL directo contra la base de STG, la consulta tarda 95 ms antes y 108–171 ms después:
el grueso del tiempo HTTP es Vercel y el enriquecimiento de descuentos, no la consulta.

**Bandeja con «Hoy» (2 oct, CDMX):** antes **2** conversaciones, 0 con póliza → después **9**, 4 con póliza, 5 que han
contestado. Por filtro:
- **Todos:** 2 → 9. Entran pólizas, fases avanzadas y estados no tempranos.
- **Contestan:** sube por lo mismo; casi todo lo que entra ya había contestado.
- **No contestan:** sin cambio de criterio, pero pierde su sentido de «pendientes». Ahora es «no contestan dentro del periodo».
- **Tomadas / Mis conversaciones:** sin cambio. Las tomas ya entraban todas (#493); en STG hay 0.
- **Abandonados:** con «Hoy», 0. Sin periodo pasaría a 127 de 155, pero la pantalla no lo pide así. Las pólizas no cuentan.

**En PROD el salto será mayor.** La bandeja actual ronda los ~1000 leads (≈900 kB cada 30 s, dicho en el propio código), y
con el recorte en el SQL «Hoy» debería quedarse en decenas. **Esto no está medido en PROD:** se medirá al promocionar.

## Controles (aceptación 2)

- **Positivo.** En STG no hay ningún lead antiguo con póliza que haya conversado **hoy**. Las 4 pólizas con movimiento hoy se
  crearon hoy y no tienen mensajes, así que no reproducen el caso. Uso el más parecido: el **lead 1032**, creado el
  7 sep, con póliza y en `payment_pending`, que conversó el 22 sep. Con periodo 22 sep **sale** (antes: **no salía**).
- **Negativo.** El mismo 1032, con el periodo de hoy, **no sale**. De las 136 conversaciones sin movimiento en 14 días,
  **0** salen con «Hoy».
- **Deep link.** Con «Hoy» y `?lead=1032`, sale (10 leads en lugar de 9).
- **No visto en pantalla** (sin login en navegador remoto). Lo tiene que mirar Alberto en STG: icono del embudo → Chats con
  el lead abierto, y que siga abierto pasados 30 s.

— Agente Dashboard
