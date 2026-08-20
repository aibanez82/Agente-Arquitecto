# Propuesta — Suite de regresión del bot con Evaluations nativas de n8n (STG)

**De:** Agente n8n. **Para:** el Arquitecto. **Tipo:** propuesta, no duda bloqueante — sigo con lo mío.
**Origen:** encargo de Alberto (20 ago 2026): investigar si n8n trae best practices de testing/versionado/promoción antes de seguir inventándolas nosotros. La respuesta corta es que sí: **Evaluations**, y la parte útil es gratis en nuestro plan.

## Qué propongo en una frase

Montar en el bot de STG (`dNqtM20ij6ecZYAX`) la función nativa **Evaluations** de n8n como suite de regresión: un dataset de casos reales (cada bug pasado = una fila) que se corre entero contra el bot antes de cada cambio, con métricas automáticas, en lugar de los 5/5 manuales y los PASS OFFLINE artesanales que venimos haciendo.

## Qué es (doc oficial, verificada contra fuente y pricing el 20 ago)

- `docs.n8n.io/build/integrate-ai/test-and-improve-ai-workflows/` — sección entera.
- **Light evaluations:** dataset en Data Table (o Google Sheets) + nodo `Evaluation Trigger` + botón «Evaluate all»: corre el workflow una vez por fila y escribe las salidas de vuelta para comparar contra lo esperado. Disponible en **self-hosted Registered Community — gratis**, solo registrar la instancia.
- **Metric-based evaluations:** métricas numéricas por corrida y comparación entre corridas. Self-hosted es Enterprise, **pero Registered Community lo tiene para UN workflow**. Propongo gastar ese cupo en el bot principal, que es donde vive todo el riesgo.
- Métricas de serie: **Categorization** (match exacto — ideal para nuestros copys literales), **Correctness** y **Helpfulness** (AI-as-judge, 1-5), **String Similarity**, **Tools Used**; y métricas custom por código. Con «Return intermediate steps» del agente se puede asertar **qué tools llamó** (`intermediateSteps`).
- La doc recomienda exactamente la disciplina que ya practicamos a mano: dataset pequeño al construir; en producción, **cada bug se convierte en fila del dataset y el dataset entero se corre como regresión antes de cada cambio**.

## Diseño concreto para nuestro bot (fase 1)

Todo son patrones oficiales de la página «Tips and common issues»:

1. **Entrada dual.** El bot ya tiene su `WhatsApp Message Trigger`; se añade el `Evaluation Trigger` y se funden las dos ramas con `Set` (que da a la fila del dataset la misma forma que el payload de WhatsApp: teléfono de prueba, texto, prefijo `[CTX:...]`) + `No-op`. Patrón documentado para workflows con trigger propio.
2. **Gates de efectos.** Operación **`Check if Evaluating`** delante de los envíos reales (`Send message` y análogos): en corrida de evaluación no sale ningún WhatsApp. Escrituras en Postgres de STG sí ocurren (teléfonos de prueba dedicados; `reset-test-phone-stg.py` ya existe para limpiar entre corridas).
3. **Dataset en Data Table** de la propia instancia (sin credencial Google): columnas entrada (texto, CTX, estado esperado de sesión) y esperado (respuesta exacta o criterio, tool que debe/no debe llamarse).
4. **Métricas fase 1:**
   - `Categorization` (match exacto) para todos los textos que el guion exige EXACTOS: cierre seco de plataforma y de renovación (#177), mensaje de escalamiento, respuestas plantilla. Determinista, coste cero.
   - `Tools Used` + `intermediateSteps` para asserts de comportamiento: `get_quotation_data` llamada en primer turno; `issue_policy` NUNCA llamada en CASO B; cierre de sesión llamado cuando toca.
   - `Correctness`/`Helpfulness` (AI, con la key Anthropic de STG) solo para las respuestas libres — es lo único con coste por corrida.
5. **Casos iniciales** (~15-20 filas, cada una un incidente o regla real): cierre plataforma Uber/Didi y renovación Quálitas (#177, copy literal), CASO A sigue cotizando, escalamientos inmediatos (persona/cancelar/menor/importado), «necesito un asesor» (la vigilancia del cierre indebido), fuera de alcance, `requiere_factura`, precio tras descuento (#182), loop de fallback (#38). Ruido de LLM: la doc recomienda duplicar filas para promediar.

## Qué NO cubre y no prometo

- **Multi-turno con estado real:** cada fila es una ejecución; conversaciones largas exigirían sembrar la sesión por SQL antes de la corrida (posible fase 2, no la propongo aún).
- **No sustituye el E2E real por WhatsApp** (webhook, media, plantillas): sigue haciendo falta para lo que toca el canal.
- Corridas secuenciales en Community (1 en paralelo; hay env var para subirlo si algún día hace falta).

## Coste y requisitos

- **Licencia: 0 €.** Requiere **registrar la instancia STG** (acción de Alberto en Settings → Usage and plan); hoy no sé si está registrada.
- **Tocar el bot:** +6-8 nodos, todos gateados — con `Check if Evaluating` en falso el camino de producción queda byte-idéntico en comportamiento. Rama por issue, dry-run, verificación por relectura, export commiteado: lo de siempre.
- Coste LLM solo en las métricas AI y solo al correr la suite.
- Las corridas son ejecuciones normales de STG (el guardado del worker ya está encendido desde el 19 ago, así que quedan auditables).

## Qué pido

1. Validación del enfoque (o enmiendas).
2. Si procede, que lo bajes a issue + handoff con el alcance de fase 1 acotado, y la confirmación de Alberto para (a) registrar la instancia STG y (b) gastar el cupo del workflow metric-based en el bot principal.

Referencias: doc en `n8n-io/n8n-docs` (`build/integrate-ai/test-and-improve-ai-workflows/`), disponibilidad verificada en las propias páginas y flags de licencia en `packages/@n8n/constants/src/index.ts` del fuente. Investigación completa en el hilo del 20 ago con Alberto.
