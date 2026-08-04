# Origen de las convenciones de CLAUDE.md (historias e incidentes)

> Este doc guarda el CONTEXTO de por qué existe cada convención — los incidentes y decisiones que
> las originaron — para que CLAUDE.md pueda quedarse solo con la regla. Extraído el 4 ago 2026 en
> la optimización de tamaño. Si una convención cambia, actualizar aquí su historia.

## Convención de handoffs (6 jul; endurecida 1 ago)

- **Por qué "siempre en `main` y verificar rama antes":** incidente doble 31 jul–1 ago — dos
  handoffs se commitearon en la rama candidata C1 del ejecutor (los clones son compartidos y
  estaban en rama candidata bajo auditoría del monitor de Juan), contaminándola.
- **Por qué "detección por fichero sin informe, NO por rango/HEAD de commits":** bug de loop del
  Agente-n8n — un `git pull` hecho para su propio push arrastraba handoffs por delante del
  marcador de HEAD y los marcaba "vistos" sin leerlos. Cerrado en `Agente-n8n@5470933b`. De ahí:
  dropear un handoff debe ser idempotente a pulls.
- **4 ago:** confirmado que el Agente-n8n tiene monitor propio sobre `handoffs/` de `origin/main`
  — basta el push, sin mensaje manual (primer uso real: handoff S2 `5cc2d07` → entrega `b104b1f`
  el mismo día).

## Verificar contra la fuente antes de publicar (reforzada 1 ago)

Raíz de los fallos por iteración. Fallos reales que la motivaron:
- un checkpoint publicado citó un instalador que no existía en la entrega del ejecutor;
- un orden de PUT publicado a Juan estaba invertido respecto al runbook real.
Lección adicional: verificar el código sin leer el **doc de entrega** del ejecutor deja fuera
contratos de API y contradicciones de gobernanza. Caso positivo (4 ago): el inventario S2 del
ejecutor se verificó contra los JSON antes de integrarlo — y eso destapó que el fix del #69
existía solo en STG mientras PROD seguía aceptando `completed`.

## Cambiar una convención = actualizar su herramienta en el acto (1 ago)

Fallo real: al mover las entregas de ejecutores a `main`, el monitor de vigilancia seguía mirando
solo ramas candidatas → las entregas a `main` eran invisibles. Un canal nuevo sin monitor es un
punto ciego.

## Backup de workflows n8n

El backup automático se descontinuó por decisión de Alberto el 29 jul (la `N8N_API_KEY` se rotó
ese día). La política vigente es export manual + commit en `docs/n8n-workflows/` de este repo
cada vez que se toque un workflow en producción. Detalle: `docs/architecture/backup-policy-n8n.md`.

## Alertar conflictos con el plan de Juan (31 jul)

Nació bajo la gobernanza `#140`/`#132` del plan C (freeze Dual, fases C con GO del monitor,
monitor `oilycoyote` vigilando nuestros repos por API). El 4 ago el plan C fue sustituido por
Contract-First S1–S5 (`#140 c.5174994247`); la convención sigue igual con la gobernanza vigente:
stand-down por etapa hasta contrato congelado + handoff.

## Recortes de estado trasladados desde CLAUDE.md (4 ago, verbatim)

Estos párrafos de estado vivían en CLAUDE.md; su hogar es el doc de cada iniciativa y el tablero.
Se conservan aquí tal cual estaban por si el doc de iniciativa no los tuviera aún:

- **Seguimiento leads estancados:** "✅ ENVIANDO EN REAL en PROD desde el 20 jul (171 envíos al
  30 jul; verificado en `n8n_chat_histories`, `metadata.source='django_checkpoint_followup'`). El
  filtro de horario 9am-8pm sigue SIN construir; decisión de Alberto (30 jul): se acepta el envío
  sin filtro (residuo fuera de horario ~1-3/día en los bordes) — el filtro pasa de bloqueante a
  mejora deseable. En STG están apagados/dry-run por la contención del port #132."
- **Conversation ID (Issue #21):** "Ya desplegado en PROD en modo shadow (Django
  `WHATSAPP_CONVERSATION_ID_MODE=shadow`, nodos `Resolve Session`/`Session Router` en n8n PROD).
  Pendiente: mergear a `main` la rama del Dashboard (`fix/conversation-id-whatsapp-n8n`) y decidir
  con Juan el paso a `dual`."
- **Recordatorios por fecha mencionada:** "handoff a Juan 16 jul; cliente da fecha para no
  contratar todavía → Haiku extrae, Python calcula, se envía vía el webhook proactivo existente.
  Bloqueante: plantilla de Meta para re-enganche fuera de ventana 24h."
- **Tabla BD, fila retirada:** "`NumeroPruebaWhatsapp` — no existe en producción y ya no importa:
  `normalize_whatsapp_phone` cae siempre a `52`. Bug #2 cerrado
  (`docs/bugs/bug-02-prefijo-57.md`)."
- **Pendiente fecha_inicio #114 (texto largo):** "✅ Django en PROD 27 jul (PR #125, v331). E2E
  n8n STG validado 28 jul (pólizas reales, +0 y +30 exacto). Falta: fix prompt límite 30d
  (`qualitas-issues#66`, definía SHA de freeze de #132) y promoción n8n a PROD. Desbloquea
  M47/M48."
- **Monitor JUAN (detalle):** "rutina cloud `trig_013gQWu8gqfDh5c8QQWzTAbM`, 6-23h CDMX → issue
  `JUAN:` en qualitas-issues. Creado 29 jul pero CIEGO: el entorno cloud no tiene credencial
  GitHub (la corrida de prueba no creó el issue de control 'JUAN-monitor activo')."
- **Issue #119 (contexto):** "rider aceptado en la autorización de B3, 29 jul." — y 4 ago:
  hallazgo nuestro publicado en #119 `c.5183416152` (endpoint acepta POST sin credencial).
