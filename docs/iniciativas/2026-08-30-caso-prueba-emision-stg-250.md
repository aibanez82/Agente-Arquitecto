# Caso de prueba E2E en STG — la emisión vuelve a funcionar (`#250`) y todo lo de estos dos días

**Pedido por Alberto, 30 ago 2026**, tras confirmar que Juan desplegó el adaptador de catálogos.
Un solo hilo de conversación, de la cotización a la póliza.

---

## 0 · Por qué esta prueba se puede hacer HOY y ayer no

| Hecho | Verificado por mí contra la fuente |
|---|---|
| El arreglo de Juan **existe** | `qualitas/external_emission_contract.py` + `views.py`, commit `4d0d661e`, merge `8f4973d8` |
| **Está desplegado en STG** | Heroku `hyl-wai-stg` **v260 «Deploy 8f4973d8» succeeded, 15:57 CDMX** — el entorno, no la rama |
| La **liga de pago** ya es ejercitable en STG | `QUALITAS_DUE_PAYMENT_LINKS_ENABLED=true` y `DRY_RUN=false` (v259, 29 ago). `_issuance_enabled()` lee **esas mismas dos**, así que el `#207` deja de estar bloqueado |
| PROD **no** lo tiene | `hyl-wai-production` sigue en `80d4a9cf` (29 ago): **la emisión por WhatsApp sigue rota en producción** |

## 1 · Antes de empezar

- **Cotización NUEVA desde la landing de STG.** No reutilizar el hilo de esta mañana: arrastra 11
  apariciones de «ya está al mejor precio disponible» en su historial, y el historial **es la memoria
  del modelo** — contamina el paso E10.
- **Todo desde el teléfono de Alberto `5551074144`**, al número STG **+52 1 56 3030 5518**.
- **Datos a mano** para no cortar el hilo: nombre completo, fecha de nacimiento, RFC, número de
  identificación, domicilio, VIN (17 caracteres) y placas.
- **La póliza que salga es real contra el entorno QA de Quálitas** (`qa.qualitas.com.mx`), no contra
  producción. La liga de pago **no se paga**: basta con ver que llega y a qué host apunta.

## 2 · Los once pasos

| # | Qué escribe Alberto | Qué prueba | Aprobado si |
|---|---|---|---|
| **E1** | **Tres mensajes en menos de 5 s**: «Hola» · «quiero cotizar» · «es para mi coche» | `#232` amortiguador | **Una sola respuesta**, no tres |
| **E2** | Datos del auto hasta recibir la cotización | carril normal + documento | Llega cotización **con su PDF** |
| **E3** | **«está caro»** | `#239 A` (comas) · `#252` (no improvisar) | Oferta de descuento **con botones**; o, si no hay, el copy determinista **sin causa inventada** |
| **E4** | **Pulsa «Aceptar»** | aplicación del descuento | **Llega la cotización nueva con su PDF, sola.** Ayer esto se rompió por un nodo puesto en serie: es el paso que lo vigila |
| **E5** | Da el **VIN** cuando lo pida el descuento | `#255` | Más adelante, en la captura, **pide solo placas** y no vuelve a pedir el número de serie |
| **E6** | Domicilio **con comas a propósito**: «Av. Juárez, 123, interior 4B, Col. Centro» | `#239 A` en `Save Group3` | Campo a campo en su sitio: calle, número, colonia, CP. **Cero corrimiento** |
| **E7** | Datos de emisión con **género «M»** y **tipo de identificación «INE»** | **`#250`, el corazón de la prueba** | El bot los acepta y avanza. Son **exactamente** los dos valores que devolvían `400 invalid_emission_data` |
| **E8** | **«confirmo»** | `#250` de punta a punta | **Póliza emitida**, con su número. Si vuelve «no pude completar la emisión por un problema técnico», el arreglo no llegó o hay un tercer campo |
| **E9** | **«mándame la liga de pago»** | `#207` | Llega **una liga y solo la liga**, sin inventarse nada. **No pagar**: comprobar que el host es el de QA |
| **E10** | **«¿qué es el parámetro Quálitas?»** | `#249 B` en sesión limpia | **No nombra el parámetro ni da su cifra**, y **no dice «ya está al mejor precio disponible»** |
| **E11** | **Pulsa un botón de un mensaje antiguo** del hilo | `#240` | Contesta **en la conversación de ahora**, sin quedarse mudo y sin decir que «venció» |

## 3 · Los tres pasos que de verdad deciden

- **E8** es el objetivo: sin póliza no hay negocio por este canal, y lleva roto desde el viernes.
- **E10** es el único que aún no sabemos: la prohibición de la frase falló esta mañana **en un hilo
  contaminado**. En sesión limpia decide si el arreglo basta o hay que cambiar el enfoque —darle la
  frase que debe decir en vez de la que no—.
- **E4** es el que ya se rompió una vez sin dar error. Se mira aunque parezca rutina.

## 4 · Qué comprueba el Arquitecto después, sin que Alberto haga nada

- **`#220`**: si `lead.estado` avanzó a `POLIZA_EMITIDA` o se quedó atrás — **subcuenta el canal ~4x**
  en todo informe basado en el estado.
- **`whatsapp_sessions.captured_data`**: `grupo3` campo a campo tras E6.
- **La ejecución de cada paso**, con su id, para cerrar o abrir issues con evidencia.
- **`conciliacion_pagos`** no se toca: la liga no se paga.

## 5 · Qué se hace con el resultado

Cada paso acaba en una de tres: **cierra** un issue con su id de ejecución, **abre** uno nuevo, o
**declara un hueco** por escrito. Ningún paso acaba en «parecía que iba bien».

Si **E8 pasa**, el `#250` queda demostrado en STG y lo único que falta es que Juan lo promueva a
`main` — porque **en producción sigue roto**, y ahí es donde están los clientes.

— Arquitecto-IA-Quálitas
