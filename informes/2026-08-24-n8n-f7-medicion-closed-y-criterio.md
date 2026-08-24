# Informe F7 — la respuesta del `closed`, el criterio discutido y las 826 filas (sin tocar ninguna)

> Agente n8n · 24 ago 2026 · Handoff `2026-08-24-f7-f8-limpieza-y-espejo.md` (GO `8a460f5`), parte F7.
> **Cero escrituras.** Medición por el grafo del bot vivo (export espejo verificado por hash).

## La pregunta que decide la fase: ¿qué le pasa a un cliente con sesión `closed` que vuelve a escribir?

**Le responde el bot. Cerrar NO silencia.** La cadena, leída del grafo vivo nodo a nodo:

1. `Resolve Session` (`phone_open_sessions`): allowlist **fail-closed** — solo `status IN
   ('open','active')` con fase de la allowlist son candidatas. Una `closed` **no es candidata**
   (Fase 6.8.1/B1; antes era blocklist fail-open y producía las conversaciones zombis).
2. Cero candidatas → `Session Resolution` deja `sessionResolved=false` → **`Fallback Flag`**:
   `conversationPhase='fallback'`, `isNewSession=true`, `quotationId=null`.
3. `Phase Guard` solo desvía a la respuesta enlatada cuando la FASE es `completed` — `fallback` no
   lo es → sigue por `Human Takeover Guard` → **el agente responde en modo contacto nuevo** (guía a
   cotizar en el sitio web; al crear cotización, Django crea sesión nueva).

**El coste real de cerrar no es el silencio: es el contexto.** El que vuelve empieza de cero (su
historial queda bajo el session_id viejo). Para sesiones sin actividad en 30 días, ese contexto ya
está frío; y las que tienen póliza el criterio las excluye, que es donde el contexto sí vale.

Matiz que conviene dejar escrito: `status='closed'` y `conversation_phase='completed'` son ejes
distintos — el enlatado de «conversación terminada» sale por la FASE, no por el status. Cerrar por
status no activa ese enlatado.

## El criterio: de acuerdo, con los números y dos matices

Medido hoy (solo lectura), sobre `status IN ('open','active')`:

| Recuento | Filas |
|---|---|
| **Cerrables por tu criterio** (>30 días sin actividad **y** sin póliza emitida **y** sin chat en 30 días) | **826** |
| Excluidas por póliza emitida (`qualitas_polizaemitida` vía cotización) | 29 |
| Excluidas por chat reciente pese a `last_activity` vieja | **1** |

Matices:

1. **Esa 1 fila excluida por chat es un hallazgo en sí**: alguien escribió historial sin actualizar
   `last_activity` — un writer con la actualización a medias. El criterio la protege (por eso la
   tercera condición no es redundante), y merece identificar el writer antes de abrir issue.
2. **La escritura que propongo cuando la autorices** (no ejecutada): `status='closed'`,
   `closed_at=now()`, **sin tocar `conversation_phase`** (los dos ejes separados), con el WHERE
   recalculado en el momento de ejecutar — no con la lista de hoy — y en lotes con recuento antes/después.

Si quieres el cinturón empírico además del grafo: la prueba del `closed` en STG (marcar una sesión
de prueba y que Alberto escriba) está disponible — el handoff la permite; no la hice porque la
lectura del grafo es concluyente y quería cero escrituras también en STG hasta tu palabra.

## Lo que NO entra (confirmado sin tocar)

`#130` resuelto en código (queda la rotación del valor, de Alberto). Variables de plantilla de
PROD: inertes, anotadas. Ninguna variable de entorno tocada; nada del bot; F6 intacta.
