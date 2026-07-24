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

## Lista autoritativa — qué va a METEPEC (10 categorías)

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

9. **Plataforma** — Didi, Uber, Indriver (categoría SEPARADA de "Servicio Público de Pasajeros",
   confirmado 24 jul — app de movilidad ≠ taxi/combi tradicional)
10. **Salvamento** — no es una línea de negocio sino un ESTATUS del vehículo (recuperado/
    reconstruido); puede aplicar dentro de cualquier línea, pero operativamente = "a METEPEC".

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

## Próximos pasos (orden)

1. **Alberto:** entregar requisitos de datos por categoría (las 10). ← bloqueante actual.
2. Arquitecto: mapear señales de detección conversacional por categoría (algunas triviales —
   "es una moto"; otras sutiles — pickup personal vs pickup de carga) y diseñar la captura.
3. Arquitecto: diseñar plantilla de correo por categoría.
4. Handoff a Agente n8n para ampliar el flujo parqueado (de 1 categoría a 10).
5. Promoción a PROD (credencial OAuth2 PROD + destinatarios reales) — handoff aparte.
