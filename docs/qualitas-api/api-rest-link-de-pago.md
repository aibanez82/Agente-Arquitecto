# API REST — Link de Pago / Servicios en Línea (Quálitas)

> Fuente: `Api-REST-Link-de-Pago-v1.4.pdf` (en esta carpeta, v1.4, 04 ene 2022). Llegó con el paquete de alta del negocio 08545/clave 27614 (correo "27614_ALTA DE NEGOCIO", nov 2025) que Alberto recuperó el 31 jul 2026.
> Es la **documentación oficial de `pagos.qualitas.com.mx/api.php`** — el endpoint que Django ya usaba sin spec (`generar_link_pasarela`). Complementa a `opl-servicios-web.md` (SOAP OPL).

## Endpoints y autenticación

| Ambiente | URL |
|---|---|
| QA | `http://pagosqa.qualitas.com.mx/api.php` |
| Producción | `https://pagos.qualitas.com.mx/api.php` |

- POST con body JSON; toda petición lleva `wptoken` + `m` (método). **Es el mismo `wptoken` que Django ya tiene en Heroku (`QUALITAS_WPTOKEN`)** — no requiere el "Pid OPL" que nos falta para los servicios SOAP de lectura.
- Credenciales por ambiente: `merchant`, `wptoken`, `privatekey` (RC4, solo si se trasladan datos bancarios — ver `rc4/`), `email`. Constantes mientras dure la relación comercial.
- El documento existe "para dar cumplimiento con PCI-DSS": el link/pasarela evita que el broker toque datos de tarjeta.

## Métodos (los 8 documentados)

| Método | Qué hace | Parámetros | ¿Lo usamos hoy? |
|---|---|---|---|
| `genlink` | Genera Link de Pago y **Quálitas lo envía por email** al asegurado | `poliza`, `email` | No |
| `tarjeta` | Valuación de tarjeta | `tarjeta` | No |
| `listlinks` | Lista los últimos 25 links de pago del negocio | — | No |
| `searchlink` | Busca el link de pago de una póliza específica | `poliza` | No |
| `cancellink` | Cancela un link de pago | `poliza`, `email` | No |
| `genWebPay` | Genera pasarela de pagos → devuelve `urlwbpy` con redirects `usucces`/`ufail` | `poliza`, `email`, `usucces`, `ufail` | ✅ `generar_link_pasarela()` |
| `fareceipt` | Primer recibo disponible a cobro (`rid`, `np/nps`, `fcr`, `monto`) | `poliza` | ✅ fallback en `generar_link_pasarela()` + verificación cruzada Conciliación (29 jul) |
| `listrecs` | **Status de TODOS los recibos de la póliza** | `poliza` | 🔴 No — es la joya, ver abajo |

## `m=listrecs` — consulta de status de recibos (añadido en v1.4)

Respuesta por recibo (ejemplo del PDF):

```json
{
  "idrecibo": "96244517", "poliza": "6550020395",
  "plazo": "mensual", "npago": "1", "totalpagos": "12",
  "status_rec": "pagado",
  "fcobro": "2020-11-27", "fpago": "2020-11-04",
  "referencia": "6550020395 OPL: 1604519742",
  "monto": "449.73", "terminación": "1070",
  "banco": "DEBITO/HSBC/VISA", "autoriza": "099102", "ftrans": "957248694"
}
```

El PDF también muestra `status_rec: "rechazado"` con la causa en `referencia` ("Cuenta con insuficiencia de fondos").

**Por qué importa:** es confirmación de pago positiva por API — `status_rec=pagado` + `fpago` + `banco` + `autoriza`. Resuelve la ambigüedad que `fareceipt`/`oplListReceipts` no resuelven (póliza pagada y póliza cancelada responden igual: sin recibos a cobro). Candidato directo a segunda fuente del Agente Conciliación junto al scraping de Q360.

### ✅ Validado en vivo (31 jul 2026, Alberto ejecutó `scripts/test-listrecs.sh` contra PROD)

`listrecs` **acepta nuestro `wptoken` actual** (sin Pid OPL) y cubre pagos hechos por la pasarela web. Estados observados: `pagado`, `por cobrar`, `rechazado`, `cancelado`. Mapeo contra `conciliacion_pagos`:

| Estado en `conciliacion_pagos` | Póliza | Señal en `listrecs` |
|---|---|---|
| PAGADO (fraccionada 12) | 7620099601 | recibo 1 `pagado` con `fpago`, `monto`, `banco`, `autoriza`; recibos 2–12 `por cobrar` |
| PENDIENTE | 7620099716 | `por cobrar` (fcr = hoy), sin `pagado` |
| VENCIDO | 7620098627 | igual que PENDIENTE — **no distingue vencido de pendiente** (la fecha rueda a hoy); esa distinción sigue viniendo del scraping / de nuestro control del link |
| CANCELADO | 7620098974 | recibo `cancelado` — **sí distingue cancelada de pagada** 🎯 |

Gotchas para el consumidor:
- Puede haber **más de una fila por `npago`**: los intentos declinados aparecen como filas `rechazado` (`referencia:"declinada"`, `monto:0.00`) junto al recibo real. Filtrar por `status_rec`, no asumir 1 fila = 1 recibo.
- Regla de decisión: `pagado` en algún recibo ⇒ pagó (ese recibo); `cancelado` ⇒ póliza cancelada; solo `por cobrar`/`rechazado` ⇒ sigue debiendo.

`searchlink` también validado: devuelve el ciclo de vida del link (`genlink`, `openlink`, `cancellink`, `paylink`, `savelink` con timestamps), email destino y terminación de tarjeta. Observación: los links caducan ~24h después de generarse (aparece `cancellink` al día siguiente en las pólizas no pagadas) — con `paylink` poblado tienes el instante exacto del pago vía link.

## Respuestas que este doc da a las preguntas de Juan a Laura (23 jul)

Juan pidió a Quálitas: (1) regenerar un enlace de pago vencido, (2) consultar pólizas pagadas mediante otros enlaces.

1. **Regenerar enlace:** `searchlink` (ver el existente) + `cancellink` (cancelarlo) + `genlink`/`genWebPay` (generar de nuevo). Django ya regenera pasarelas con `genWebPay`; `genlink` además delega el envío del email a Quálitas.
2. **Consultar pólizas pagadas:** `listrecs` — exactamente eso, con fecha, banco y autorización.

## MSI — Información de bancos (Informacion-Bancos-MSI.xlsx)

Del mismo paquete de alta. Contiene: catálogo de códigos de banco (2=BANAMEX, 12=BBVA, 14=SANTANDER, 21=HSBC, 72=BANORTE…), bancos participantes a 3 y 6 MSI (vigencia abr–jun 2023, ojo: desactualizado) y códigos de tipo de cobranza: `CL` (cargo en línea), `3MSI`, `6MSI`, `6AMSI` (AMEX). Relevante solo si algún día ofrecemos meses sin intereses vía `oplCollection`.

## Cifrado RC4 (`rc4/`)

Ejemplos oficiales de Quálitas (PHP, Java, VB.NET, C#) para encriptar datos bancarios (`number`, `expmonth`, `expyear`, `cvv-csc`) con la `privatekey`. Solo aplica si trasladáramos datos de tarjeta por WS — hoy NO lo hacemos (la pasarela los captura). ⚠️ RC4 es criptografía obsoleta; si algún día se considera cargo en línea server-side, esto además mete alcance PCI-DSS (ver `opl-servicios-web.md`).

## Contexto del alta del negocio (correo "27614_ALTA DE NEGOCIO", nov 2025)

- Negocio **08545 HYLANT_MEXICO**, clave de agente **27614**. Alta de cobranza implementada primero en QA como `SWC08545` (25 nov 2025).
- **Las llaves del ambiente QA y las llaves de encriptación se enviaron a `janderson.gomez@aguayo.co`** (desarrollador de aguayo-co) — si falta alguna credencial OPL (p. ej. el Pid de los servicios SOAP de lectura), el primer sitio donde preguntar es Janderson/Juan, no Quálitas.
- Portal de consulta QA: `https://oplqa.qualitas.com.mx/q.php?SWC08545` (usuario de pruebas sdiaz/sdiaz; puede estar caducado).
- Tarjeta ficticia QA: `5454545454545454`, cvv 123, cualquier vigencia válida.
- El correo de Samuel Díaz (Metepec, 24 jul 2026) reenviado por Laura el 29 jul apunta a validar recibos con OPL pág. 15–16 (`oplListReceipts`) y aclara que las pólizas emitidas por la IA "se instalan en OPL".
