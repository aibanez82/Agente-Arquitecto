# Optimización del prompt del bot — de 82 000 caracteres a un prompt compuesto

> **Encargo de Alberto (3 oct 2026):** separar esta iniciativa de la del SaaS
> (`2026-10-02-insurmind-saas-multi-broker.md`) — **es aparte y es la prioridad.** Abrirla con la primera etapa en STG:
> *la emisión toma los datos del registro, no del modelo.*
>
> Issue de la etapa 1: `aguayo-co/HYL-WAI#536`. Handoff: `aibanez82/Agente-n8n:handoffs/2026-10-03-emision-desde-el-registro.md`.

---

## 1. Diagnóstico (medido el 3 oct 2026)

Fuente: `systemMessage` del nodo `AI Agent`, bot PROD `BtOaZm7WlZT-24V7hqCnF` versión `b041a6d8`, por la API de n8n.
El de STG (`dNqtM20ij6ecZYAX` `e4d36d73`) mide 82 374 y **no es igual** al de PROD: lleva hunks pendientes de otras órdenes.

- **81 741 caracteres, 1 059 líneas, ~20 000 tokens que el modelo relee en cada turno.**
- Escrito **en el orden en que se fue añadiendo**, no en el de la conversación: cada incidente (`#206`, `#207`, `#275`, `#334`…)
  dejó su sección. La persona aparece en tres sitios (L16-29, L156, L1002-1020).
- **El flujo de venta (L270-837) ocupa ~36 000 caracteres**, casi la mitad, y se lee entero aunque el cliente solo salude.

| Capa (criterio del lector, tamaños exactos) | Caracteres | % |
|---|---|---|
| Mezcla de varias capas en la misma sección | 30 724 | 37,6 |
| Mecánica de plataforma (fases, persistencia, antifabricación, formato) | 19 965 | 24,4 |
| Producto Quálitas (paquetes, formas de pago, placas, CP, suma asegurada) | 16 276 | 19,9 |
| Regla comercial (descuentos, Limitada, gancho de pausa) | 10 303 | 12,6 |
| Persona del cliente (Carla, tuteo, acompañamiento) | 4 473 | 5,5 |

Problemas, por gravedad:

1. **Datos de emisión escritos por el modelo.** `Issue Policy` recibe 21 de sus 24 campos por `$fromAI` (corregido el 3 oct: decía «22 de 25»); lo guardado con
   `Save Group1/2/3 Progress` no se usa para emitir. Detalle y mediciones en `HYL-WAI#536`. → **Etapa 1.**
2. **Unas 15 reglas duras solo en el prompt**, sin nodo que las imponga: no pedir tarjeta/CVV/OTP, no «sin intereses» para
   fraccionado, no «la más barata», escalar importados, no renovaciones, Limitada (solo observada), no mostrar email/teléfono…
3. **Duplicación que ya divergió:** el prompt del `RAG IA Agent` (26 669) copia 5 bloques del principal; 4 idénticos byte a byte,
   «Acompañamiento» distinto (676 frente a 1 446).
4. **Todo a la vez en cada turno:** más choque entre instrucciones y parches de comportamiento («un hecho registrado no se desmiente»).
5. **Frases de las que dependen detectores del Dashboard** («Continuamos con… cobertura», «*Domicilio:*», «emitida exitosamente»):
   reorganizar sin cuidado los apaga sin error (`qualitas-issues#82`).

Las afirmaciones comerciales del prompt (precio preferencial por este canal, MSI 3/6/12 con 7 bancos, «+6 M autos», liga de
24 h) **son ciertas — confirmado por Alberto el 3 oct.** Al pasar a configuración llevarán responsable y fecha de verificación.

## 2. Destino: prompt compuesto por turno

| Pieza | Dónde vive |
|---|---|
| Núcleo de plataforma (seguridad, formato, persistencia, antifabricación, mapa corto de fases) | prompt, común |
| Persona del cliente (nombre, marca visible, tú/usted, horario, enlace del asesor) | ficha del cliente, insertada |
| Ficha corta del producto | catálogo, insertada |
| Bloque de la fase actual, solo uno | por `conversation_phase` |
| Política comercial (descuentos, gancho de pausa) | configuración |
| Conocimiento del producto | base de conocimiento, bajo demanda |
| Reglas duras y datos exactos | **el grafo**, no el texto |

Estimación, no medición: 25 000-30 000 caracteres por turno.

## 3. Etapas

| # | Etapa | Aceptación | Riesgo |
|---|---|---|---|
| **1** | **La emisión toma los datos del registro** (§4) | §4.4 | medio · toca emisión |
| 2 | Quitar duplicados AI Agent ↔ RAG a una sola fuente (§5) | prompt del AI Agent idéntico byte a byte; en el RAG solo cambia «Acompañamiento» (versión del AI Agent, decidido) | bajo |
| 3 | Persona como variables | el prompt montado para Hylant idéntico al de hoy, carácter a carácter | casi nulo |
| 4 | Reglas críticas al grafo (tarjeta/CVV/OTP, «sin intereses») | cada guarda con un caso que bloquea y otro que pasa | medio |
| 5 | Solo el bloque de la fase actual | N ≥ 20 conversaciones en STG sin empeorar; frases de detectores intactas | medio |
| 6 | Conocimiento de producto a la base, separada por producto | N ≥ 20; fidelidad de cifras medida | alto |
| 7 | Resto de reglas al grafo | como la 4 | medio |

**Gobierno:** el prompt del agente y la emisión están fuera de la autorización permanente de promoción: cada viaje a PROD
lleva orden de Alberto. STG se alcanza sin preguntar. Todo hunk de prompt entra en la **lista viva de deltas** STG→PROD.

## 4. Etapa 1 — la emisión toma los datos del registro

### 4.1 Cómo se emite hoy (medido en STG `e4d36d73` / guard `a2ba98bc`, y en Django `8167391f`)

```
Bot ── Save Group1/2/3 Progress ──► whatsapp_sessions.captured_data   (no se usa para emitir)
Bot ── Issue Policy (21 de 24 campos $fromAI) ──► Issue Policy Guard
        [30 días · placas · email presente] ──► POST /api/emitir-externo/
Django ── email vs cotización · paquete/forma vs cotización (solo con selección) · Sepomex · VIN · form
        ──► QualitasService (XML, CP del cuerpo) ──► Quálitas (SOAP)
```

### 4.2 El registro no tiene hoy la forma de la emisión

| Campo de emisión | Hoy en `captured_data` | Hace falta |
|---|---|---|
| nombre, apellidos, género | `grupo1.*` | tal cual |
| `fecha_nacimiento` (YYYY-MM-DD) | `grupo1.fecha_nacimiento` en **DD/MM/AAAA** | convertir |
| `rfc` (10) + `homoclave` (3) | `grupo2.rfc` completo, o vacío | partir; vacío = falta |
| `requiere_factura` | `grupo2.requiere_factura` (SI/NO/**pendiente**) | pendiente = falta |
| `serie`, `placas` | `grupo2.serie`, `grupo2.placas` | tal cual |
| `calle`, `colonia` | `grupo3.calle`, `grupo3.colonia` | tal cual |
| `numero_exterior`, `numero_interior` | **un solo campo** `grupo3.numero` («222 interior 4B») | guardar **separados** |
| `codigo_postal`, `telefono`, `paquete`, `forma_pago` | — | **de `qualitas_cotizacion`** |
| `tipo_identificacion`, `numero_identificacion` | `grupo1.ine` | constantes del grafo `'1'` / `'1234567891'`, como la landing (`views.py:525`) |

Las tools guardan `'N/A'` cuando el modelo no da un valor (`|| 'N/A'`). **Un placeholder es un campo que falta**: mismo conjunto
que Django (`lead_funnel_reconciliation._PLACEHOLDERS`: `''`, `n/a`, `na`, `pendiente`, `null`, `none`, `{}`).

**Contrato de Django sobre `captured_data`** (`lead_funnel_reconciliation._BLOCK_FIELDS`, `origin/stg` `fec88fb5`): ya espera
`numero_exterior` y `numero_interior` en `grupo3`, y rechaza claves desconocidas — hoy ya rechaza `grupo1.ine`,
`grupo2.serie_source` y `grupo3.numero`. Esta etapa usa los nombres de Django para las claves nuevas y **no retira ninguna**
(un viaje, una causa). El desajuste existente se le señala a Juan aparte.

### 4.3 El cambio

1. **Guard:** antes de los controles actuales, leer el registro (sesión + cotización), montar el cuerpo y **fallar cerrado** con
   la lista de lo que falta, sin llamar a Django. Los controles de 30 días, placas y email operan ya sobre el registro.
2. **Tool `Issue Policy`:** solo `cotizacion_id`, `session_id`, `email` (grafo) y `fecha_inicio` (modelo, ya vigilada).
3. **`Save Group3 Progress`:** guardar también `numero_exterior` y `numero_interior` separados.
4. **Resumen desde el registro:** una tool de lectura que devuelve lo guardado; el resumen se monta solo con eso.
5. **Prompt:** fuera las instrucciones del INE y las que piden copiar campos a `issue_policy`; el resumen, desde la tool.

Correcciones: el cliente corrige → la tool de guardado → resumen y emisión toman lo último guardado. CP: sigue sin cambiarse sin
recotizar. Después de emitir es un endoso, fuera del bot.

### 4.4 Aceptación (STG, conversación real)

Ver el handoff. Resumen: camino feliz con el cuerpo enviado idéntico al registro; corrección de domicilio tras el resumen que
llega a la emisión; control negativo con un campo en placeholder que no llama a Django; CP y teléfono = cotización; frases de
los detectores intactas; diff de parámetros contra el respaldo limitado a los nodos dichos.

### 4.5 Fuera de esta etapa

- Django: tomar CP y teléfono de la cotización con 409 si llegan distintos — para Juan, sin orden todavía.
- `HYL-WAI#534` (Juan, XML: teléfono por TipoRegla 70 y correo por TipoRegla 31) toca el XML, no el cuerpo que manda n8n:
  no colisiona, pero conviene no promover las dos a PROD el mismo día.

## 5. Etapa 2 — una sola fuente para lo que comparten AI Agent y RAG

**Decisión de Alberto (3 oct):** «Acompañamiento» se queda con la versión del **AI Agent**.

### 5.1 Medido (STG `e4d36d73`, igual en PROD `b041a6d8`)

Dos agentes contestan al mismo cliente: `AI Agent` (intents `contracting`, `renovacion`, `policy_status`) y `RAG IA Agent` (el resto,
salvo fuera de tema o presupuesto de KB agotado). Secciones `=== … ===` presentes en los dos:

| Sección | AI | RAG | Estado |
|---|---|---|---|
| CAMBIO DE COTIZACIÓN (el cliente quiere ver otra suya) | 3 153 | 3 153 | idéntica |
| QUÉ COTIZACIÓN ESTÁ ACTIVA | 879 | 879 | idéntica |
| UN HECHO REGISTRADO NO SE DESMIENTE | 841 | 841 | idéntica |
| LA LIMITADA NO SE OFRECE SOLA (#206) | 1 265 | 1 265 | idéntica |
| TRADUCE LO QUE PIDE A LO QUE EXISTE (#334) | 1 576 | 1 575 | idéntica salvo el salto de línea final |
| ACOMPAÑAMIENTO AL PEDIR DATOS (#316) | 1 473 | 703 | **divergió**: el RAG no tiene la regla de género neutro ni la del «gracias», y su ejemplo dice «Tranquilo, …» — justo lo que la regla de género prohíbe |

`Merge Session Data` es ancestro de los dos agentes; los dos `systemMessage` ya son expresiones (`=`).

### 5.2 El cambio (para el handoff, que se publica cuando la etapa 1 quede acreditada en STG)

- Un nodo de código en el tronco común (tras `Merge Session Data`) con los seis bloques como única fuente.
- Los dos `systemMessage` insertan cada bloque por expresión en el sitio exacto donde hoy está su copia.
- El bloque «Acompañamiento» es el del AI Agent.

### 5.3 Aceptación

1. `systemMessage` resuelto del AI Agent **byte-idéntico** al anterior.
2. `systemMessage` resuelto del RAG idéntico salvo «Acompañamiento» (texto del AI Agent) y, si cae ahí, el salto de línea de «Traduce».
3. STG: una pregunta que lleve al RAG a enumerar los datos para contratar → sin adjetivos con género antes de conocerlo.
4. Diff de parámetros solo en los dos agentes y el nodo nuevo; detectores intactos.

**No ahorra tokens:** cada agente recibe el mismo texto. Gana que no puedan volver a divergir y deja el prompt listo para componerse.

## 6. Estado

- **3 oct 2026 — abierta.** Etapa 1 ordenada por Alberto para STG; handoff publicado.
- **3 oct 2026 — corrección:** la tool tiene 24 campos (21 por `$fromAI`), no 25/22; salen 20. Adenda en el handoff (`5c5e19df`) y comentario en `#536`. Apuntado para Juan: `DatosEmisionForm` exige `apellido_materno`.
- **3 oct 2026 — etapa 1 aplicada en STG** (bot `00382130`, guard `c0b8a798`; informe `Agente-n8n@22d3abf5`), re-medida por el Arquitecto. Falta el E2E por WhatsApp (aceptaciones 1 y 2), pendiente del sí de Alberto.
- **5 oct 2026 — etapa 1 en PROD**, por orden directa de Alberto al Agente n8n (sin el `#473` parte 3). Bot `a5b88be9` (393
  nodos), guard `533ba7be` (17), re-medido por el Arquitecto: `Issue Policy` solo con `cotizacion_id`, `session_id`, `email`,
  `modo` y `fecha_inicio` (único `$fromAI`); resumen rehecho entre `Append Soft Warning` y `Agent Reply Empty?`; el
  `systemMessage` de PROD difiere del de STG solo en los hunks del `#473` parte 3. Por el camino salieron y se arreglaron en STG:
  el resumen que podía salir de memoria (adenda 2) y la reserva calculada sobre el texto del modelo (adenda 4). Quedan por
  acreditar con tráfico real: primera emisión y primer resumen (memoria sincronizada). Defecto ajeno destapado: `#545` (RFC).
- **3 oct 2026 — etapa 2:** Alberto elige «Acompañamiento» del AI Agent. Diseño en §5; handoff tras acreditar la etapa 1.

Agente: Arquitecto-IA-Qualitas
