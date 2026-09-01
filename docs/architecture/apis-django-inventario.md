# Inventario de las APIs de Django (HYL-WAI)

> **Medido el 1 sep 2026** contra `aguayo-co/HYL-WAI`, rama `origin/main` (lo que corre en PROD),
> ficheros `qualitas/urls.py`, `qualitas/discount_api.py`, `qualitas/payment_reminder_api.py`.
> **Ámbito de la medición:** solo `qualitas/urls.py`. No cubre rutas de Wagtail ni el admin.
>
> **Para qué existe este documento:** fase 1 del desacople del Dashboard — que deje de leer y escribir
> tablas de Django y pase a consumir API. Aquí está lo que **ya existe**; lo que falte se pide a Juan
> con issues `API-XXX`.

---

## 1 · Las tres familias, y no se parecen en nada

Lo primero que hay que entender es que «la API de Django» no es una cosa: son **tres superficies con
propósitos, autenticación y garantías distintas**. Mezclarlas es el error que hay que evitar al
desacoplar.

### A · Contrato v1 — descuentos (`/api/v1/...`)

La única familia con **contrato versionado, esquemas cerrados y hashes de petición/respuesta**. Es la
que nació del `#156` y la que marca el estándar de cómo debería ser todo lo demás.

| Método | Ruta | Para qué | Principal |
|---|---|---|---|
| `GET` | `/api/v1/discounts/ai-use-cases` | Catálogo de casos de uso | n8n |
| `POST` | `/api/v1/discounts/availability` | ¿Hay descuento para esta cotización? | n8n |
| `POST` | `/api/v1/discount-offers` | Crear oferta | n8n |
| `POST` | `/api/v1/discount-offers/<offer_id>/resolution` | Aceptar/rechazar | n8n |
| `GET` | `/api/v1/discount-applications/<id>` | Estado de la aplicación | n8n |
| `GET` | `/api/v1/discount-applications/<id>/document` | Documento asociado | n8n |
| `POST` | `/api/v1/discount-applications/<id>/conversation` | Traza conversacional | n8n |
| `POST` | `/api/v1/discount-applications/<id>/delivery` | Entrega del documento | n8n |
| `POST` | `/api/v1/discount-applications/<id>/reconciliation` | Reconciliación | **dashboard** |
| `POST` | `/api/v1/discount-applications` | Aplicación directa (`#273`) | n8n · **solo en `stg`** |

### B · Operativas de n8n (`/api/n8n/...`)

Sin versionar. Sirven al bot, no al negocio.

| Método | Ruta | Para qué |
|---|---|---|
| `POST` | `/api/n8n/payment-link/ensure/` | Asegurar liga de pago |
| `POST` | `/api/n8n/payment-reminders/context/resolve/` | Contexto de recordatorio (`#144`) |
| `POST` | `/api/n8n/payment-reminders/opt-out/` | Baja de recordatorios (`#144`) |

### C · Landing y utilidades (`/api/...` sin versionar)

Nacieron para el formulario web, no como interfaz de integración. **Son las más frágiles como
dependencia**: no tienen contrato, y su forma puede cambiar con el rediseño de la landing.

`/api/cotizacion/detalle/` · `/api/cotizacion/seleccion/` · `/api/vehiculos/` · `/api/validar-serie/` ·
`/api/emitir-externo/` · `/api/enviar-ayuda-requisitos/` · `/api/analytics/web-event/`

---

## 2 · Autenticación: ya existe un principal «dashboard»

Es el hallazgo que más simplifica la fase 1. En `discount_api.py` conviven **dos autenticadores**:

- `_authenticate(request)` → token `DISCOUNTS_API_BEARER_TOKEN`, con caída a `N8N_TOKEN`. Principal
  por defecto: **`n8n`**.
- `_authenticate_dashboard(request)` → token **`DISCOUNTS_DASHBOARD_API_BEARER_TOKEN`**, sin caída.

Los dos usan `Bearer` y `secrets.compare_digest`, y **deniegan en positivo**: sin token configurado,
rechazan.

**Consecuencia para el desacople: no hay que inventar un modelo de identidad para el Dashboard.** Ya
existe, ya está en producción y ya lo usa una ruta (`/reconciliation`). Toda API nueva para el
Dashboard debería colgar de ese mismo principal.

---

## 3 · Lo que hoy NO pasa por API, que es el problema

El Dashboard **no consume estas APIs para lo que enseña**: se conecta a la misma base de datos de
Django y lee tablas y vistas directamente. Eso produce, ya medido:

- **Acoplamiento a la forma interna:** una vista que Django recree sin `GRANT` deja el Dashboard
  roto sin que nadie lo note hasta que un usuario pulsa un botón. Ocurrió hoy: `conversation_control_v1`
  sin permisos → «Tomar conversación» caído en producción (`HYL-WAI#284`).
- **Cero contrato:** ningún esquema, ninguna versión, ningún error tipado. Un `rename` de columna en
  Django es un incidente en el Dashboard.
- **Reglas de negocio duplicadas:** el criterio de «póliza pagada» vive hoy en el Dashboard como
  workaround (`bug-07`), no en Django.

El inventario exacto de esas consultas está encargado al Agente Dashboard; **este documento se
completa cuando llegue**.

---

## 4 · Cómo se pedirán las APIs que falten

Un issue por API en `aguayo-co/HYL-WAI`, con el código **`API-XXX`** en el título, y dentro:

1. **Qué compra el negocio** con esa API — la pantalla o la decisión que habilita, no la tabla.
2. **Quién la consume** y con qué principal.
3. **Forma propuesta**: método, ruta, petición, respuesta y **errores tipados**.
4. **Qué consulta directa retira** — el acoplamiento concreto que muere al nacer la API.
5. **Cómo se verifica** que el Dashboard dejó de tocar esa tabla.

El punto 4 es el que evita la trampa clásica: **añadir una API y dejar la consulta directa viva**. Una
API que no retira un acoplamiento no ha desacoplado nada.

---

## 5 · Principios para la fase 1

- **Las escrituras primero.** Que el Dashboard escriba en tablas de Django es más grave que leerlas: un
  lector desactualizado enseña un dato viejo; un escritor se salta las reglas de negocio.
- **No convertir la familia C en dependencia.** Antes de apoyar el Dashboard en un endpoint de la
  landing, pedir uno propio: esas rutas van a cambiar con el rediseño.
- **Una API por función de negocio, no por tabla.** Si acabamos con `/api/leads`, `/api/cotizaciones` y
  `/api/polizas`, habremos movido el acoplamiento de SQL a HTTP sin ganar nada.
- **Fecha en cada afirmación de este documento.** Se midió el 1 sep 2026; `origin/stg` ya tiene una
  ruta más que `origin/main`.
