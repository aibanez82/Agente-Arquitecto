# Informe — #525 en `stg`: plantillas de Meta con nombre legible, y el PDF de la cotización desde la conversación

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **3 oct 2026**
**Origen:** petición de Alberto en mi sesión (2 oct): *«…en lugar de Saludos Inicial Sin Pdf Con Boton, aparezca el PDF…
sería de tremendo valor»*. Diseño acordado con él, incluido el nombre *«Envío plantilla META · Saludo»*, y un último *«me parece bien»*.
Issue: `HYL-WAI#525`.

| | |
|---|---|
| Rama | `feature/525-plantillas-y-pdf` = **`1bc3e36`** |
| `stg` | `ae6e795` → **`229410e`**; deploy `dpl_6aTJrmu6h7YsriMp2VJtdFseyUwN` READY |
| Gates | **768/768**, verificador y `build`; test nuevo fail-first (9 de 13 fallan contra el código anterior) |
| `main` | sin tocar |

## Qué cambia

- **Etiqueta:** «Envío plantilla META · …» para cada plantilla conocida, y el nombre tal cual para las que no.
  Debajo, los datos con los que se rellenó. Las dos plantillas cuyo texto real de Meta ya se pintaba lo conservan.
  Módulo: `/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/lib/s1/plantillasMeta.js`.
- **PDF** (`qualitas_cotizacion.pdf_cotizacion_url`, solo `https://`, en pestaña nueva con `noopener`):
  - el **saludo con botón** enlaza el PDF de su cotización **marcado como no enviado** («el cliente lo recibe si pulsa “Ver la cotización”»);
  - las plantillas que **sí** llevan PDF enlazan **su propio** `pdf_url`;
  - el evento **«📎 Se envió el PDF»**: historial actual → cotización actual; heredado del salto anterior → `source_quote_id`;
    de **más de un salto atrás** → **sin enlace** (el `inherited_from_session_id` de esas filas apunta al padre, no al abuelo).
  - Si `qualitas_cotizacion` no se puede leer, la conversación sale igual, sin enlaces.

## Comprobado en vivo (STG, lead 1546)

`/api/conversation` 200. El saludo trae la etiqueta, «Chevrolet Beat 2020 · Cobertura Amplia · $12,028.99 MXN · Anual (Contado)»
y el enlace con `enviado:false`. El evento trae el enlace con `enviado:true`. El PDF responde **200 `application/pdf`**.
El SQL nuevo, probado contra la BD de STG con parámetros de texto (sin 42P08).

## Para saber

- **Recordatorios sin datos:** 8 de 41 `cotizacion_followup_15m` de STG llegan con `template_params = {}` (y el del 1546, sin
  `sent_at`). Salen con la etiqueta y nada debajo; antes, «Recordatorio 15 min». No es nuevo, solo ahora se ve.
- **Seguridad, aparte:** las URL del PDF son de S3 **sin firma**. El Dashboard (que exige login) no lo cambia. Si el PDF lleva
  datos personales, hay que revisarlo con quien lleva el bucket. Está anotado en el #525.
- **PROD sin medir:** cuántas cotizaciones tienen `pdf_cotizacion_url` en PROD (en STG, 118 de 338).

— Agente Dashboard
