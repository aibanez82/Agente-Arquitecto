# Plan de pruebas E2E — Descuentos en STG (`#161` / `#163` / `#156`)

> **Ejecuta Alberto** (landing, WhatsApp real, Dashboard). **Verifica el Arquitecto** por SQL y API.
> Estado del entorno al escribir: SQL `#161` y `#163` aplicados, workflow actualizado y verificado,
> **worker `DeCguAaVtCuW2CUj` APAGADO**. Nada de esto toca PROD.
>
> Este plan **no sustituye** el E2E que Juan se reserva en el paso 6 de `#161`. Es nuestro, para
> encontrar errores antes y llegar a su prueba con el terreno despejado.

---

## 0. Antes de gastar una prueba: la contradicción del porcentaje

Medido hoy en la BD de STG:

| dónde | valor |
|---|---|
| `qualitas_discountsettings.default_qualitas_percentage` | **20** |
| Único trigger activo (`quote_sent`, `attempt=2`) | apunta al programa **`CHECKPOINT_INTRO_35`** |
| `CHECKPOINT_INTRO_35.qualitas_percentage` | **35** |
| `POR_PRECIO_ALTO_PARA_IA_30` | 30, y **no** disponible para checkpoint |
| Aplicaciones existentes | `1`, `34`, `67` — **las tres en `uncertain`** |

Y un sondeo nuestro del 31 jul contra QA y PROD concluyó que el campo de descuento de Quálitas
**solo admite 0 o 20**: 21, 25, 35, 40, 50 y 100 devolvían *«Descuento fuera de Rango, rango válido
20 a 20»*.

**Si eso sigue vigente, cualquier prueba con el trigger tal como está acabará en fallo**, porque
pediría un 35 %. Eso explicaría por qué las tres aplicaciones existentes están en `uncertain`.

De ahí las dos rutas. **La A es gratis y confirma o descarta la hipótesis; la B requiere tocar
configuración.** Recomiendo A primero.

---

## Ruta A — diagnóstica, sin tocar nada (recomendada para empezar)

Se prueba con la configuración actual (35 %). El resultado esperado es un **fallo controlado**, y eso
ya vale: confirma la causa raíz de los `uncertain`, y de paso ejercita justo lo que reportamos como
hueco — `qualitas-issues#81` y `HYL-WAI#164`.

### A.1 · Preparación (yo)

1. Registro el estado inicial: filas de `n8n_discount_application_poll`, `qualitas_discountoffer`,
   `qualitas_discountapplication` y `whatsapp_sessions` del teléfono de prueba.
2. **Reactivo el worker** (`active=true`). Hoy es inocuo: 0 aplicaciones reclamables.
3. Dejo un reloj: apunto la hora UTC de arranque para acotar la evidencia.

### A.2 · Cotización desde la landing (Alberto)

1. Entra en la landing de **STG** y cotiza con **tu teléfono real**.
2. Anota: marca/modelo/año, CP y la hora.
3. Debes recibir el **primer WhatsApp** con la cotización.

> **Verifico yo:** `qualitas_lead` + `qualitas_cotizacion` creados, `whatsapp_sessions` con sesión
> nueva `waq_<qid>_<hex>` y una sola `active` para tu teléfono.

### A.3 · Provocar el checkpoint `quote_sent`, intento 2 (Alberto + yo)

El trigger dispara en el **segundo seguimiento** tras enviar la cotización, no en el primero.

1. **No respondas todavía** al WhatsApp inicial: el seguimiento es lo que arrastra la oferta.
2. Avísame y **compruebo cuándo está programado el intento 2**; si el tiempo es largo, te digo si
   conviene esperar o si hay que forzarlo desde el Scheduler (eso lo decides tú, es acción viva).

> **Verifico yo:** creación de `qualitas_discountoffer` con su `offered_copy`, y que el programa
> asociado es el del trigger.

### A.4 · Recibir y aceptar la oferta (Alberto)

1. Debes recibir un WhatsApp ofreciendo el descuento. **Cópiame el texto literal** — sirve para
   comprobar si el copy administrable de Wagtail (`#161`) se está usando de verdad.
2. **Acéptala** como lo haría un cliente.
3. Debes recibir *«Estamos preparando la nueva cotización. Espera un momento.»*

> **Verifico yo:** `qualitas_discountapplication` creada, y la entrada en
> `n8n_discount_application_poll` con su `poll_key`.

### A.5 · Observar el desenlace (yo, y aquí está lo que buscamos)

Con el 35 %, lo esperable es que Quálitas rechace y la aplicación termine en `failed` o `uncertain`.
Lo que hay que mirar, en este orden:

| # | qué compruebo | por qué importa |
|---|---|---|
| 1 | El `error_code` exacto que devuelve Quálitas | **Confirma o refuta el rango 20-20.** Es el dato que llevamos semanas suponiendo |
| 2 | Si te llega el **aviso terminal** por WhatsApp | Es lo que `#161` §4 promete y lo que cerraba el silencio de `#81` |
| 3 | Si el `attempt` llegó a **9** | La constraint nueva lo permite; antes reventaba en 8 |
| 4 | Que el `poll_key` casa con `\.poll\.[1-9]$` | Valida la constraint de `#161` con datos reales |

### A.6 · Los dos huecos abiertos (Alberto)

**Este es el valor añadido de tener a un humano en el bucle.** Con la aplicación ya en terminal:

1. **`qualitas-issues#81`** — escribe *«Continuemos»* por WhatsApp. **¿El bot sigue vendiendo la
   cotización anterior y te pide datos para emitir?** Si sí, queda confirmado con evidencia nueva.
2. **`HYL-WAI#164`** — si el bot te pide los datos, **dáselos** y llega hasta donde te deje.
   **¿Te emite póliza con el precio antiguo?** Eso es lo que el guard que pedí debería impedir.
   **Para justo antes del pago**: no completes ningún cobro.
3. **`#163`** — comprueba conmigo si **dejas de recibir seguimientos** de la cotización origen. Es
   la decisión de producto de Juan funcionando: silencio deliberado, no avería.

> **Verifico yo:** `qualitas_polizaemitida` (si llega a crearse), `estatus_pago`, y si la cotización
> origen queda excluida por `discount_handoff`.

### A.7 · Dashboard (Alberto)

1. Abre la conversación en el Dashboard de STG.
2. **¿Aparece el panel de descuentos** con el estado `uncertain` → *«Requiere conciliación manual»*?
3. **¿Ves la línea `Descuento autorizado X %` · `Cotización actual: …`?**
4. **No pulses ninguna acción de reconciliación**: las aplicaciones `1`/`34` están vetadas por Juan,
   y la nueva conviene dejarla intacta como evidencia.

> Esto además ejercita `qualitas-issues#83`: comprobar si desde el Dashboard **hay forma de saber que
> hay una aplicación esperando** sin abrir esa conversación concreta.

---

## Ruta B — camino feliz (requiere decisión previa)

Solo tiene sentido si la Ruta A confirma que el 35 % es el problema. Para que un descuento **funcione
de verdad** hay que ofrecer un porcentaje que Quálitas acepte:

- **Opción 1:** poner el trigger a un programa con `qualitas_percentage = 20`. Es configuración de
  negocio, la decides tú (o Juan), no yo.
- **Opción 2:** gestión comercial con Quálitas para ampliar el rango del negocio 08545. No es un
  cambio de código y no depende de nosotros.

Con eso resuelto, se repite A.2–A.5 y **entonces sí** se puede validar lo que `#161` promete:

| condición de aceptación de Juan | cómo la compruebo |
|---|---|
| **Dos corridas** del worker | ejecuciones del workflow: la primera termina en `Discount Poll Terminal` |
| **Segunda descarga exacta** | segundo `Fetch Private Discount Document` con hash/length idénticos |
| **Un solo handoff** | una fila en `n8n_discount_conversation_handoff` |
| **Un solo delivery** | un envío, sin segundo `Send Discount PDF WhatsApp` |
| **Cero llamada nueva a Quálitas** | ninguna recotización adicional tras el PDF |
| **Cero follow-up source competidor** | la cotización origen no genera seguimientos |

---

## Qué NO se hace, en ninguna ruta

- **Nada en PROD.**
- **No se reconcilian las aplicaciones `1`, `34` ni `67`** — Juan lo prohíbe expresamente.
- **No se completa ningún pago.**
- No se importan ni editan otros workflows, ni se tocan `C1`/`S1`.
- Si algo se desvía de lo previsto, **se para y se anota**; no se improvisa sobre datos vivos.

## Rollback

- **Workflow:** `~/Desktop/161-backup/worker-VIVO-antes-20260817T221109Z.json` (204 KB).
- **Funciones SQL:** `~/Desktop/161-backup/funciones-previas.sql` (4 definiciones, 586 líneas).
- **Worker:** se puede desactivar en cualquier momento por API; es lo primero que haría ante
  cualquier comportamiento inesperado.
- Los leads y aplicaciones que cree la prueba **no se borran**: quedan como evidencia, anotados aquí
  con su `id` y hora.

## Anotación pendiente para Juan

- Aparece una aplicación **`67`** en `uncertain` por `document_binary_invalid` que él no menciona
  —su veto nombra solo la `1` y la `34`—. Conviene preguntarle si la conoce.
- En su comentario dice que el copy se edita en `DiscountTrigger.offered_copy`; el campo vive en
  realidad en **`DiscountProgram.offered_copy`**. No es un fallo funcional, pero el panel está donde
  está y conviene saberlo antes de buscarlo en Wagtail.
