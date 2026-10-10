# Duda de diseño (Dashboard): `#590` — el hito `dio_datos_personales`, de un LIKE muerto a una señal de dato

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde al handoff** `Dashboard_SeguroAuto:handoffs/2026-10-10-590-hito-datos-personales.md`. Sin código.

## 1. Inventario (medido en `origin/stg`)

| Dónde | Qué hace con el hito |
|---|---|
| `apps/operacion/pages/api/db-leads.js:192` y `:233` (sesión viva y archivada) | Lo **calcula**: `BOOL_OR` sobre las filas `ai` sin `source` con `LIKE '%tengo%' AND LIKE '%Nombre:%'` |
| `apps/operacion/pages/api/db-leads.js:74` | Lo expone como `dio_datos_personales` (vivo, si no, archivado) |
| `apps/operacion/pages/api/db-leads.js:81` | **Suma 1** a `nivel_compromiso` (0–6) |
| `apps/operacion/lib/embudoFuga.js:97` | Etapa «Datos de emisión»: `dio_datos_personales OR asegurado_nombre`. El asegurado ya la sostiene hoy |
| `apps/operacion/components/LeadModal.js:233` | El icono 👤 «Datos personales» en la fila del lead |
| `apps/operacion/lib/s1/vinVigilancia.js:254` | **No es consumidor:** cuenta las filas **de sistema** que casan con el mismo LIKE, como vigilancia de la frontera agente/sistema |
| `apps/operacion/lib/canalDatosEmision.js:17` | Solo un comentario: lo cita como señal que no sirve |

## 2. Medido: la señal de dato frente al LIKE

**PROD, últimos 21 días** (`/api/db-leads` con la sesión de Alberto; `captured_data` **no lo expone ningún endpoint**, así que en PROD no
se puede medir sin código):

| | Leads |
|---|---|
| leads creados | 811 (297 con sesión de WhatsApp) |
| **LIKE** (`dio_datos_personales`) | **0** |
| **asegurado** (`qualitas_asegurado` de su cotización) | **23**: 13 dados por WhatsApp y 7 en la web según el ledger de Django (`datos_emision_canal`), 3 sin canal |
| de ellos, con descuento | 7 de 136 leads de descuento |
| `captured_data.grupo1` | **sin medir en PROD** |

**STG, sesiones creadas en los últimos 21 días** (BD de solo lectura):

| | Sesiones |
|---|---|
| sesiones | 27 |
| `captured_data->'grupo1'->>'nombre'` no vacío | 3 |
| asegurado de su cotización | 8 |
| **LIKE** | **0** |
| `grupo1` **o** asegurado | 10 (7 solo asegurado, 2 solo `grupo1`, 1 ambos) |
| **nacidas de un descuento** (`proposed_conversation_id`) | 5, **ninguna** con `grupo1` ni con asegurado |

**Lo que dice:** ninguna de las dos señales basta sola. El asegurado se escribe al validar los datos de emisión (también los de la web);
`grupo1` es lo que el bot captura en la conversación, a veces antes. Y **la sesión nacida de un descuento llega vacía** (como
`waq_4385` en el `#585`): los datos se dieron en la sesión de origen.

## 3. Propuesta: una sola fuente, en un solo sitio

`datos_personales_guardados` se calcula **en `db-leads.js`, en SQL**, y es lo único que leen todos:

- **verdadero** si existe `qualitas_asegurado` de su cotización, **o** si `captured_data->'grupo1'->>'nombre'` no está vacío en su sesión
  viva o archivada;
- **en una cadena de descuento, se hereda** del lead de origen. Es el mismo principio de `leadsPorRootConfirmado` («se hereda la
  evidencia, no se añaden filas», `#304`), así que la sesión nueva vacía no hace que el cliente «olvide» que ya dio sus datos;
- sustituye a `dio_datos_personales` en `nivel_compromiso`, en `embudoFuga.js` (que pasa a leer solo este campo) y en `LeadModal.js`;
- **se retira el LIKE** de `db-leads.js`, y en `vinVigilancia.js` se quita esa línea: deja de ser una regla, así que ya no hay frontera
  que vigilar para ella;
- tests: el control positivo (sesión con `grupo1` → `true`), el negativo (sin él ni asegurado → `false`), solo asegurado → `true`, la
  herencia en una cadena de descuento y que ningún consumidor siga leyendo `dio_datos_personales`.

## Lo que te pido

1. ¿Vale la fuente (asegurado **o** `grupo1`, heredada en la cadena)?
2. **`grupo1` en PROD está sin medir.** ¿Lo mides tú, si tienes lectura, o añado al `resumen` de `db-leads` un recuento sin PII
   (`sesiones con grupo1`) para medirlo después del despliegue a `stg`/PROD? Lo segundo es código, así que lo pregunto.
3. El nombre del campo nuevo: propongo `datos_personales_guardados` y mantener `dio_datos_personales` como alias durante un viaje,
   por si algo externo lo lee. ¿O lo cambio de golpe?

Agente: Dashboard
