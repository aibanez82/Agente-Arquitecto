# OPL (Operadora en Línea) — webservice de pago de Quálitas

> Fuente: `OPL-Servicios-Web-v1.3.2.pdf` (en esta carpeta, v1.3.2, nov 2021) + exploración en vivo del WSDL PROD (29 jul 2026).
> Este servicio NO está cubierto por la doc estructurada de `aguayo-co/HYL-WAI:docs/qualitas-documentacion-webservices/` — este archivo es la referencia local.

## Endpoints

| Ambiente | URL |
|---|---|
| Pruebas | `http://pagosqa.qualitas.com.mx/ws/wsCollection.php?WSDL` (⚠️ http, sin TLS — no meter datos reales) |
| Producción | `https://pagos.qualitas.com.mx/ws/wsCollection.php?WSDL` |
| REST auxiliar | `https://pagos.qualitas.com.mx/api.php` — lo usa Django (`generar_link_pasarela`) con métodos `m=genWebPay` y `m=fareceipt`. **Desde el 31 jul tenemos su spec oficial** (8 métodos, incl. `listrecs` = status de recibos): `api-rest-link-de-pago.md` en esta carpeta |

## Operaciones

Documentadas en el PDF:

| Operación | Qué hace |
|---|---|
| `oplCollection` | Instala la cobranza de una póliza: domiciliación (D débito CLABE / C crédito / A AMEX), cargo en línea (CL Visa-MC / AL AMEX), tokenización (T), nómina (N). Respuesta incluye los recibos generados (estatus, vigencias, montos) |
| `oplCancelation` | Cancela póliza (inmediata o programada a fecha futura) |
| `oplEdition` | Edita datos de cobranza (cambiar tarjeta/método) |
| `getRefOpl` | URL del PDF de la ficha de pago referenciado |
| `oplListReceipts` | Lista recibos vencidos/disponibles a cobro (por póliza o global). Solo lectura |

**Confirmadas en el WSDL PROD pero NO documentadas en el PDF** (29 jul 2026): `oplListPols`, `oplConciliation`, `domiOpl`, `cancelOplInt`. La existencia de `oplConciliation` es especialmente relevante para el Agente Conciliación — pedir documentación a Quálitas.

## Autenticación — dos juegos de credenciales distintos

1. **`wpuid` + `wptoken`** (atributos del XML interno): es lo que Django ya tiene en Heroku (`QUALITAS_WPUID`, `QUALITAS_WPTOKEN`) y funciona para `oplCollection` (tipo CL, con `NoNegocio` = `QUALITAS_NO_NEGOCIO` = negocio SISE `08545`) y para `api.php` (`wptoken` solo).
2. **`pid` + `token`** (atributos `<ListReceipts pid= token=>`): "Número de Negocio proporcionado por **OPL**" — credencial distinta que **no tenemos**. Verificado en vivo 29 jul 2026: `oplListReceipts` en PROD rechaza tanto `wpuid/wptoken` como `08545/wptoken` con `Negocio Inexsistente o Token Invalido!!`. Pista (correo alta de negocio, nov 2025): **las llaves OPL de QA y de encriptación se enviaron a `janderson.gomez@aguayo.co`** — preguntar primero a Juan/Janderson antes que a Quálitas. Detalle: `api-rest-link-de-pago.md`.

Encriptación de datos sensibles (tarjetas): tag `<crypto>` + RC4 con llave compartida (⚠️ RC4 = criptografía obsoleta; Django hoy manda `crypto>0` sin cifrar en `derivar_poliza_opl` porque no envía datos de tarjeta). Solo aplica a cobranza, no a los servicios de lectura.

## Lo que Django (HYL-WAI) ya usa hoy

- `qualitas/services.py` → `derivar_poliza_opl()`: `oplCollection` tipo `CL` tras emitir, para instalar la cobranza.
- `qualitas/services.py` → `generar_link_pasarela()`: `api.php` `m=genWebPay` (genera `urlwbpy` con redirects `usucces`/`ufail`) con fallback `m=fareceipt` (devuelve el `rid` del recibo cobrable de una póliza).
- ⚠️ Los defaults hardcodeados en ese archivo son credenciales del ambiente QA de Quálitas; las de PROD viven en las config vars de Heroku `hyl-wai-production`.

## Semántica de `oplListReceipts` (del PDF)

- Devuelve **solo** recibos vencidos y disponibles a cobro (id de recibo, fecha de cobro, monto).
- Póliza pagada **o** cancelada → no devuelve recibos. **No distingue entre ambas** — por sí solo confirma "sigue debiendo", no "pagó".
- `poliza` y `fcr` (fecha de salida a cobro) son opcionales: sin ellos lista todo lo del día.

## Valor identificado para nuestra operativa (análisis 29 jul 2026)

1. **Cruce con el Agente Conciliación** (en exploración — ver `docs/architecture/estatus-pago-qualitas.md`): `fareceipt`/`oplListReceipts` como verificación API del resultado del scraping de Q360, y `oplConciliation` como posible sustituto formal.
2. **Cargo en línea (CL) server-side**: cobraría con respuesta síncrona y eliminaría de raíz la fragilidad del redirect `usucces`/`ufail` — pero mete a Django en alcance PCI-DSS (decisión Juan/Hylant).
3. **Pago referenciado (`getRefOpl`)**: ficha de pago en efectivo enviable por WhatsApp — canal de cierre para clientes sin tarjeta.
4. **Domiciliación con plazos M/Q/B/W**: pago fraccionado recurrente — decisión de producto.

## Scripts de exploración

En `scripts/` de esta carpeta (leen el token de Heroku en runtime, no contienen secretos):

- `test-opl-list-receipts.sh` — SOAP `oplListReceipts` PROD (hoy devuelve error de auth; sirve para revalidar cuando Quálitas dé el Pid OPL).
- `test-fareceipt.cjs` — `api.php m=fareceipt` para 4 pólizas con estado conocido en `conciliacion_pagos` (PAGADO/PENDIENTE/VENCIDO/CANCELADO). Pendiente de ejecutar (bloqueado por permisos del entorno del agente — correrlo a mano).
