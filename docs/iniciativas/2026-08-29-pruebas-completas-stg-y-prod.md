# Dos pruebas completas, una por entorno — guion ejecutable

**Pedido por Alberto, 28 ago 2026 (noche):** «desde el lunes hemos hecho muchos cambios en STG y
PROD; lanzamos dos pruebas completas, una en cada entorno, para ir cerrando o abriendo issues».

**Números a los que se escribe** (verificados contra la Graph API y contra la ejecución `16503`):

| Entorno | Número | Nombre verificado |
|---|---|---|
| **STG** | **+52 1 56 3030 5518** | STG Hylant Qualitas Tel Mexico |
| **PROD** | **+52 1 55 1246 5773** | el de producción (`phone_number_id` `1028815256982638`) |

**Regla que no se salta en ningún paso:** todo desde el teléfono de Alberto **`5551074144`**. Ningún
mensaje de prueba a un teléfono de cliente, por ningún motivo.

---

## 1 · El orden importa más que las pruebas

**PROD no se prueba todavía.** Hay dos paquetes ordenados y sin importar —el arreglo de las comas
(`#239 A`) y el amortiguador de ráfaga (`#232`)—. Probar antes es medir un grafo que va a cambiar dos
veces: el resultado no acreditaría nada y habría que repetirlo entero.

**Secuencia:**

1. **Caso A en STG, ya.** STG va por delante y la prueba es gratis: lo que se rompa ahí no lo sufre
   nadie.
2. Aterrizan en PROD los dos paquetes, cada uno con su verificación.
3. **Caso B en PROD**, sobre el grafo definitivo.

## 2 · Lo que conviene resolver ANTES, o la prueba nace coja

- **La config de pago de STG (de Juan).** Medido en las config vars: PROD tiene
  `QUALITAS_DUE_PAYMENT_LINKS_ENABLED=true`, `DRY_RUN=false`, endpoint y token de la pasarela;
  **STG no tiene ninguna de esas variables**. Consecuencia dura: **el Caso A no puede llegar a
  `available`** — muere en `not_available` haga lo que haga. Si Juan las configura antes, el Caso A
  cierra el `#207` sin tocar producción; si no, ese paso queda declarado como no ejercitable.
- **`#239 B` (el sumidero mudo) está en cola para STG.** Si entra antes del Caso A, el paso A11
  cambia de «silencio esperado» a «responde algo». Cualquiera de los dos órdenes vale; lo que no vale
  es no saber cuál se probó.

## 3 · Caso A — STG, hilo único, de principio a fin

Objetivo: ejercitar en una sola conversación todo lo que entró en STG desde el lunes.

**Antes de empezar (Agente n8n, no Alberto):** anotar `versionId` vivo, hora de inicio y sesión de
partida. Todo paso lleva **id de ejecución**; sin id no hay evidencia.

| # | Qué escribe Alberto | Qué prueba | Aprobado si |
|---|---|---|---|
| **A1** | **Tres mensajes seguidos en menos de 5 s**: «Hola» · «quiero cotizar» · «es para mi coche» | `#232` amortiguador de ráfaga | **Una sola respuesta**, no tres. Las 3 filas en `inbound_message_buffer` y una sola composición |
| **A2** | Datos del auto hasta recibir cotización | carril normal + entrega de documento | Llega cotización con su PDF |
| **A3** | **Pulsa el botón** de la cotización | `#135` relevo del clic | El bot **no se queda mudo**. Hoy Django responde `503 quote_interaction_disabled` (flag apagado): eso es lo esperado, el silencio no |
| **A4** | **«Lo veo un poco caro»** | **`#239 A`, el corazón de la prueba** | Django ofrece descuento. Si sale **`POR_VIN_40`** (el copy con 2 comas): `Persist` da `aplicado: true` y **la oferta llega al teléfono** |
| **A5** | Durante la espera del descuento: **«¿entonces en cuánto queda?»** | `#243` | **Fallo conocido**: responderá con la cotización vieja. Documentar con hora y ejecución — es la evidencia para pedirle a Juan la señal in-flight |
| **A6** | Pulsa **aceptar** la oferta | aplicación de descuento | Nueva cotización con precio menor y PDF |
| **A7** | Domicilio **con comas a propósito**: «Av. Juárez, 123, interior 4B» | `#239 A` en `Save Group3` | En `whatsapp_sessions`, **campo a campo en su sitio**: calle, número, colonia, CP. Cero corrimiento |
| **A8** | Completar hasta **emitir póliza** | carril de emisión | Póliza emitida. **Comprobar de paso el `#220`**: si `lead.estado` no avanza a `POLIZA_EMITIDA`, queda acreditado |
| **A9** | **«Mándame la liga de pago»** | `#207` | Con la config de Juan: `available` y **solo** la URL. Sin ella: `not_available` **sin inventarse ninguna** — y el hueco se declara |
| **A10** | «¿De dónde sale ese precio? dame el desglose técnico» | `#228` guarda de salida | **No aparece el «Parámetro Quálitas»** ni ningún valor interno |
| **A11** | **Pulsa un botón de un mensaje antiguo** del hilo | `#240` / `#239 B` | Si `B` no ha entrado: silencio, **fallo conocido**, documentar. Si ha entrado: responde algo |

## 4 · Caso B — PROD, después de los dos imports

Mismo esqueleto, con tres diferencias que importan:

- **A3 (clic):** en PROD los seis `LEAD_FUNNEL_*` **no están definidos**. Anotar qué hace: es dato
  nuevo, nadie lo ha visto.
- **A4 (objeción de precio):** es **el calco exacto del incidente de las 17:29 del 28 ago**. Si la
  oferta `POR_VIN_40` llega al teléfono, el `#239` se cierra con la prueba en el entorno donde
  ocurrió.
- **A8–A9 (emitir y pedir liga): decisión de Alberto, no técnica.** Llegar hasta el final en PROD
  significa **emitir una póliza real** y generar una **liga de pago viva contra
  `pagos.qualitas.com.mx`** — un instrumento al portador, y un registro que verán Laura y el Agente
  Conciliación. Si se decide que no, la prueba **para en A7** y `available` sigue sin ejercitarse en
  producción.

## 5 · Qué se hace con el resultado

Cada paso termina en una de tres: **cierra** un issue (con su id de ejecución), **abre** uno nuevo, o
**confirma un fallo conocido** con evidencia fresca. Lo que no vale es «funcionó bien» sin id.

Candidatos a cerrar si el Caso A sale limpio: `#239` (con B dentro), `#232`, `#228`, `#207` (si Juan
configura STG). Candidatos a abrir: lo que aparezca en A3 y A11, y la señal in-flight del `#243`.

— Arquitecto-IA-Quálitas
