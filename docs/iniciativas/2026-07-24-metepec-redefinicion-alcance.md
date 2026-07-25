# METEPEC — redefinición de alcance (24 jul 2026)

> Autor: Arquitecto-IA-Qualitas · 24 jul 2026, con Alberto.
> **Supersede** el alcance estrecho "solo plataforma digital" de
> [2026-07-20-agente-mtp-correo-metepec.md](2026-07-20-agente-mtp-correo-metepec.md).
> La tabla `leads_metepec` y el flujo n8n parqueado (`feature/metepec-plataforma-digital`)
> siguen siendo la base — se amplía el alcance, no se reemplaza la arquitectura.

## Regla de negocio, en una frase

**A METEPEC va TODO vehículo/caso que la landing no cotiza. La landing/bot solo cierra la
línea "Autos y Pickups Personales" de Quálitas.** El resto se entrega a METEPEC (contact center
de Hylant) para que ellos coticen/emitan por su cuenta, e InsureMind registra el lead para
negociar comisión con Hylant por haber participado.

## Lista autoritativa — qué va a METEPEC (11 categorías)

Base: taxonomía de líneas de negocio de Quálitas (captura del portal, 24 jul) + casos extra que
no son línea de negocio sino uso/estatus del vehículo.

De las líneas de negocio de Quálitas (todas MENOS "Autos y Pickups Personales"):

1. **Pickups de Carga**
2. **Camiones**
3. **Servicio Público de Pasajeros** (taxi/combi/bus tradicional)
4. **Fronterizos y Regularizados** (= lo que Alberto llama "legalizados"; auto de
   importación/frontera regularizado — una sola categoría, confirmado 24 jul)
5. **Turistas**
6. **Motocicletas**
7. **Seguro Básico Estandarizado**
8. **Seguro de Responsabilidad Civil Profesional para Agentes de Seguros**

Categorías extra (no son línea de negocio de la imagen, se agregan aparte):

9. **Plataforma** — Didi, Uber, Indriver. **Solo pasajeros** (NO reparto/Uber Eats/Rappi/Didi
   Food — confirmado 24 jul). Categoría SEPARADA de "Servicio Público de Pasajeros" (app de
   movilidad ≠ taxi/combi tradicional).
10. **Salvamento** — no es una línea de negocio sino un ESTATUS del vehículo (recuperado/
    reconstruido); puede aplicar dentro de cualquier línea, pero operativamente = "a METEPEC".
11. **Flotillas** — arreglo comercial de varios vehículos (confirmado 24 jul como categoría
    propia, no se dobla en ninguna otra).

**Se queda con el bot (único):** Autos y Pickups Personales (uso personal).

## Hallazgo arquitectónico clave: detección 100% conversacional

La landing **siempre entrega una cotización** — no bloquea ninguno de estos casos. El cliente
mete un auto cualquiera para pasar el formulario (un Versa, un Yaris) y la verdad solo aparece
en WhatsApp:

- "coticé un Versa pero **es salvamento / es legalizado**" → mismo vehículo, distinto estatus.
- "coticé un Yaris pero **en realidad es una Tacoma / un camión / una moto**" → el vehículo
  cotizado es un **señuelo**, el real es otro.

Consecuencia: **no hay nada que detectar del lado de landing/Django.** Toda la detección de las
10 categorías ocurre en la conversación del bot (n8n/Sonnet) — mismo mecanismo que el flujo de
plataforma ya parqueado, solo que el disparador se amplía de "Uber/Didi/taxi/flotilla" a las 10
categorías.

### Sub-tipo con matiz de datos (importante para el bot)

- **Tipo 1 — mismo vehículo, distinto uso/estatus:** Plataforma, Servicio Público, Salvamento,
  Fronterizos/Regularizados. El vehículo cotizado ES el real → `get_quotation_data` (marca/
  modelo/año de la landing) sirve tal cual.
- **Tipo 2 — vehículo cotizado = señuelo:** Camiones, Pickups de Carga, Motocicletas, Turistas
  (y a veces otros). El vehículo real ≠ lo cotizado → el bot **NO puede confiar** en
  `get_quotation_data`; tiene que **capturar el vehículo real** del cliente antes de mandar a
  METEPEC. Si no, el correo dice "Yaris" cuando es una Tacoma.

## `motivo_entrega` = la categoría

El campo `motivo_entrega` de `leads_metepec` pasa a ser un enum de estas 10 categorías (texto
libre por ahora, sin CHECK, igual que hoy). Beneficio directo: permite reportar a Hylant "les
entregué X de plataforma, Y camiones, Z salvamento…" con números reales para la negociación de
comisión.

## PENDIENTE DE ALBERTO — requisitos de datos por categoría

**Cada categoría necesita datos distintos** para que Hylant/METEPEC pueda trabajar la cotización
(confirmado 24 jul). El correo a METEPEC NO es uno solo — cada categoría captura sus propios
campos. Alberto va a pasar, por cada una de las 10 categorías, **qué datos necesita Hylant** para
trabajarla.

Eso define directamente:
- Qué tiene que **preguntar el bot** en cada caso (además de lo que ya tiene del lead: nombre,
  teléfono, email; y el VIN que ya pide el flujo actual).
- El **cuerpo/plantilla del correo** a METEPEC por categoría (hoy solo existe la de plataforma
  digital — ver doc del 20 jul).

Hasta tener esto, no se puede cerrar el diseño de captura conversacional ni las plantillas.

## Estado del build (recordatorio)

- Flujo n8n de **plataforma digital** construido y **parqueado** en `feature/metepec-plataforma-digital`
  (sacado de `stg` el 20 jul). Sub-workflow STG `liBCn3yBegedmYuR` desactivado, no borrado.
- Tabla `leads_metepec` intacta en STG.
- Nunca llegó a PROD (falta credencial OAuth2 propia de PROD + destinatario real
  `metepecaten@qualitas.com.mx` con CC Laura/Rafael).

## Arquitectura decidida (24 jul): carril METEPEC dedicado (Forma 2)

Alberto planteó el riesgo correcto: meter las 10 categorías (detección + captura + plantilla
cada una) dentro de `AI Agent`/`RAG IA Agent` intoxica el prompt del flujo por donde pasa el
**90% del negocio** (cotización de auto particular). Con 1 categoría (plataforma) el enfoque
parqueado era tolerable; con 10 no.

**Decisión: NO meter las 10 categorías en el flujo principal. Se crea un carril METEPEC
dedicado**, reusando el router que ya existe:

1. **Haiku Intent Router** gana **un solo** intent nuevo, GRUESO: `no_cotizable` = "no es auto
   particular estándar" (uso plataforma, carga, transporte público, moto, salvamento,
   fronterizo/regularizado, turista, o pide un producto especial). Haiku **solo levanta la
   bandera** — NO carga la taxonomía de 10, eso lo hace el agente especialista. Barato y aislado.
2. **Route by Intent** enruta `no_cotizable` a un **nodo nuevo `METEPEC Agent`** (hermano de
   `AI Agent` / `RAG IA Agent`), con su propio `systemMessage`.
3. El `METEPEC Agent` es el **único** que carga: la clasificación fina en las 10 categorías, la
   captura por categoría y las plantillas. Tools que necesita: `get_quotation_data` (nombre/
   teléfono/email/vehículo cotizado) y `registrar_lead_metepec` (sub-workflow INSERT + correo,
   **ya construido**, se amplía para recibir `motivo_entrega` como parámetro y elegir plantilla).
4. **Bandera de sesión pegajosa** (`whatsapp_sessions`, p.ej. en `captured_data` o columna
   propia): una vez en el carril METEPEC, la conversación se queda ahí turno a turno hasta
   terminar la captura (o abortar), para que el "mi VIN es…" del cliente no se re-clasifique de
   vuelta a `contracting`. Detalle de implementación para Agente n8n.

**Consecuencia buena:** el flujo del 90% queda **más limpio que hoy** — se le *quita* del prompt
la regla de escalamiento de vehículo comercial. La complejidad de las 10 categorías vive en un
agente que el auto normal nunca toca. Mismo principio de aislamiento que el sub-workflow y las
tablas standalone.

**Costo asumido:** un 3er agente + su ruteo que mantener, manejo de la bandera de sesión, y más
superficie de prueba — pero es complejidad *aislada*, no *encima del 90%*.

### Hallazgo al aterrizar la Forma 2: escalamientos que hoy ya son METEPEC "muertos"

La lista de "ESCALAMIENTO INMEDIATO" del `AI Agent` en PROD ya contiene varios de los 10 casos
(vehículo de uso comercial, **auto importado**), hoy resueltos con un **link fijo sin captura**
(`wa.me/525634352430`) — o sea leads que se pierden. La Forma 2 convierte esos casos de
"escalamiento a callejón sin salida" en **leads METEPEC capturados**. Al mover cada categoría al
carril nuevo, hay que **sacarla de esa lista de escalamiento** (las que NO son categoría METEPEC
—quiere hablar con humano, cancelar, menor de edad— se quedan igual).

## Diseño de referencia — categoría PLATAFORMA (molde para las otras 9)

Primera categoría, es **Tipo 1** (mismo vehículo, distinto uso → `get_quotation_data` sirve).

**Detección (en el carril METEPEC, no en el flujo principal):**
- Haiku levanta `no_cotizable` cuando el mensaje menciona Uber / Didi / Indriver / "plataforma" /
  "hago viajes" / "aplicación".
- Ya dentro del `METEPEC Agent`, la clasificación fina la marca como `plataforma` (distinta de
  `servicio_publico` = taxi/combi/bus tradicional).

**Captura conversacional** (el vehículo cotizado ES el real, solo falta VIN):
1. `METEPEC Agent` confirma el caso plataforma.
2. Si no hay VIN: *"En ese caso necesitaría por favor que me des tu VIN y así ofrecerte una
   cotización especial."*
3. Cliente da VIN → llama `registrar_lead_metepec(motivo_entrega='plataforma', …)`.
4. Éxito: *"Perfecto, ya tengo tus datos registrados. Uno de nuestros asesores especializados te
   va a contactar directamente para darte seguimiento a tu cotización."*
5. Fallback si la tool falla: escalar con el link fijo (no perder el lead).

**Decisiones cerradas (24 jul) — plataforma 100% definida:**
- Plataforma = **solo pasajeros** (reparto/Uber Eats/Rappi/Didi Food NO entra aquí).
- **No** se necesita saber cuál app (Uber/Didi/Indriver) — no se pregunta ni se manda.
- **El bot solo pide VIN** (Opción B). METEPEC toma el resto de los datos por teléfono. Esto
  coincide exactamente con el build parqueado — plataforma no requiere captura nueva, solo
  moverla al carril `METEPEC Agent`.

**Datos a METEPEC** — de `get_quotation_data`: nombre, teléfono, email, CP, `vehiculo_descripcion`;
del cliente: `vin`; fijos: `cotizacion_id`, `motivo_entrega='plataforma'`.

**Correo:** STG `acer3500@gmail.com` · PROD `metepecaten@qualitas.com.mx` +CC Laura/Rafael.
Asunto `27614 Cotización Plataforma Digital`. Cuerpo: plantilla existente del 20 jul (sin cambios).

## Próximos pasos (orden)

1. **Alberto:** entregar requisitos de datos por categoría para las **10 restantes** (plataforma
   ya cerrada). ← bloqueante actual.
2. Arquitecto: mapear señales de detección por categoría para el `METEPEC Agent` (fina) y la
   bandera gruesa de Haiku; diseñar la captura Tipo 1 vs Tipo 2 por categoría.
3. Arquitecto: diseñar plantilla de correo por categoría (parametrizar el sub-workflow por
   `motivo_entrega`).
4. Verificar el JSON real parqueado (repo Agente-n8n, rama `feature/metepec-plataforma-digital`)
   contra este diseño antes del handoff.
5. Handoff a Agente n8n: construir el carril METEPEC (intent `no_cotizable`, ruteo, `METEPEC
   Agent`, bandera de sesión, sub-workflow parametrizado) — STG primero, empezando por plataforma.
6. Promoción a PROD (credencial OAuth2 PROD + destinatarios reales) — handoff aparte.
