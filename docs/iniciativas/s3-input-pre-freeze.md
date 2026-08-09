# S3 — input pre-freeze para el contrato (listo para publicar en `#128`)

Preparado el 8 ago 2026. **No publicado todavía**: la decisión de cuándo es de Alberto (ver §0).
Fuente de los hechos: `docs/iniciativas/s3-prep-offline.md`, verificado contra código, no de memoria.

## 0. Por qué antes del freeze, y por qué esto no es adelantarse

En C1 se perdieron rondas por **dos ambigüedades que hubo que resolver por enmienda contractual a
mitad de implementación**: `initially open` (→ `1.0.1`) y la identidad de instancia que la API
pública 2.28.7 no expone (→ `1.0.2`). Ninguna era un defecto de código: eran preguntas que nadie
había hecho a tiempo.

El método Contract-First congela el contrato **antes** de implementar. Ese es exactamente el momento
en que estas ocho preguntas cuestan una frase; después cuestan una enmienda.

Riesgo de oportunidad, declarado: S3 va después de S2 y liderazgo está hoy en S1. Publicar esto
ahora puede leerse como abrir un frente. **Recomendación: publicar al arrancar S2**, salvo decisión
en contra.

## 1. Las ocho ambigüedades

### A1 — Identidad del control
Fijar que es **`session_id` + `control_id` + `epoch`**, la semántica ya acreditada en el ciclo S1, y
**no** el `lead_id` del diseño de julio.

El caso que fuerza la definición es justo el que S1 materializa: **A/B con el mismo teléfono**. Tomar
por lead debe resolver **LA** sesión exacta. Falta definir qué ocurre si un lead tiene **dos sesiones
vivas** — proponemos el mismo tratamiento de cardinalidad que S1 (`400`/`409`), no elegir una.

**Actualización (9 ago) — esto ya no es hipotético, hay evidencia en vivo.** S1 materializó el par A/B
**compartiendo teléfono** y el Dashboard lo acreditó por comportamiento en `#132 c.5228667583`:
cada registro aparece **una sola vez**, con lead, cotización, `session_id` y `conversation_id`
**distintos**, `identity_mode=v2`, el `conversation_id` embebiendo la cotización de **su propia** fila
y **sin fallback telefónico**; `conversation?lead_id=<A|B>` abre **su sesión exacta** sin cruce, e
`inbox` devuelve una entrada por cada uno.

O sea: **la resolución por identidad ya funciona con teléfono compartido**, que era el supuesto de
riesgo. Lo que S3 tiene que fijar no es si se puede, sino **qué responde cuando hay dos sesiones vivas
para el mismo lead** — el único caso que la evidencia todavía no cubre.

### A2 — Fuente del gate
¿Consulta canónica de S2 o `EXISTS` ad-hoc?

**Nuestra posición: la canónica.** Un solo texto contractual, versionado por hash, consumido igual
por el bot, por Retomar y por la UI. Tres implementaciones del mismo predicado son tres sitios donde
divergir.

### A3 — Envío humano frente a los modos runtime de S1
El estado final de S1 deja `read_only` con POST proactivo en `403`. S3 necesita **habilitar el envío
humano**, así que hay que definir el modo nuevo (¿`take_send`?) y su tabla de códigos, manteniendo
**fail-closed por defecto** y destino allowlisted.

Esto no es cosmético: el resolutor actual es fail-closed porque solo un literal exacto levanta el
bloqueo. El modo nuevo debe conservar esa propiedad, no añadir una rama permisiva.

### A4 — Ventana de 24 h de Meta
Riesgo arrastrado desde `#128`: si el humano toma **fuera de la ventana**, el envío fallará. La
plantilla de re-enganche sigue bloqueada.

El contrato debe definir el comportamiento **sin esperar a la plantilla**: error claro al operador,
**nunca reintento silencioso**. Un reintento que no se ve es peor que un fallo que se ve.

### A5 — Migración del escritor del espejo
Confirmar que S3 ordena que la toma/liberación escriba **solo claims**, y que el workflow ON/OFF
pasa a derivado o se retira en S5. Coherente con nuestra propuesta A5 de S2, ya publicada en
`#135 c.5187242434`.

### A6 — Auto-release por inactividad
¿Dentro de la versión «básica» o diferido?

**Nuestra posición: diferirlo.** Un claim olvidado se libera a mano; automatizarlo añade superficie
de contrato —y una fuente de liberaciones no pedidas— a cambio de poca cosa.

### A7 — `sent_by: human_agent`
¿Entra en el contrato de datos de S3 (`additional_kwargs` en `n8n_chat_histories`) o queda como
convención no contractual? Si no entra, nadie puede apoyarse en él después sin renegociar.

### A8 — Persistencia de inbound bajo control humano
El diseño de julio dice **persistir sí, responder no** —la IA retoma luego con la transcripción
completa—. Debe quedar como **cláusula observable**: conteo de historial `+1` y `outbound = 0`.

Observable importa: es la diferencia entre una promesa y una postcondición que una suite puede
ejercitar.

## 2. Lo que ya está verificado y no debería re-discutirse

Para ahorrar ronda, tres hechos comprobados contra el código y no contra el diseño de julio:

- los claims **keyean por `session_id`** (`uq_claims_active_session WHERE state='active'`), con
  `lead_id`/`quotation_id` como metadata; la toma por `lead_id` se resuelve server-side
  lead→cotización→sesión;
- liberar exige **el par `control_id`+`epoch` exacto más el agente** — nunca por teléfono ni por lead
  a secas;
- **el espejo existe**: el workflow «Atención Humana ON/OFF» escribe `whatsapp_sessions.human_takeover`
  y dos guards del bot lo leen. El contrato S2 ya lo degrada a no-fuente-de-autoridad.

Y un dato de entorno que conviene fijar antes de escribir la suite: **ese espejo existe en STG (24
columnas) y no en PROD (17)**. Cualquier cláusula que lo asuma presente en ambos nacería falsa.

## 3. Qué pedimos del freeze

Que las ocho queden resueltas **en el texto**, no en la implementación. Con A1, A2 y A3 cerradas, la
suite de conformidad se puede escribir antes de tener código, que es el patrón que funcionó en S1.
