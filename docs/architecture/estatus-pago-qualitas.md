# Cómo saber con certeza si un cliente pagó la póliza

Movido desde `CLAUDE.md`, sección "Pendientes de infraestructura", al adelgazar el archivo (10 jul 2026).

## ✅ Mecanismo real confirmado (17 jul 2026) — no es un webhook, es un redirect de navegador

Se revisó la documentación oficial estructurada de Quálitas (`aguayo-co/HYL-WAI:docs/qualitas-documentacion-webservices/`, entregada 17 jul) buscando si Quálitas notifica el pago por webhook u otro medio — **no lo documenta en absoluto**, esa carpeta solo cubre cotización/emisión/tarifas/impresión, no el webservice de pago (OPL).

Cruzando esto con el código real de Django (`qualitas/services.py`), se confirmó el mecanismo real:

1. `generar_link_pasarela()` llama a `genWebPay` de Quálitas (`QUALITAS_URL_PAGO`) pasando **URLs de redirección del navegador**: `usucces`/`ufail` (`request.build_absolute_uri(reverse('pago_exitoso'))` / `pago_fallido`).
2. Cuando el cliente termina de pagar en la pasarela de Quálitas, **el navegador del cliente** es redirigido a `pago_exitoso` (o `pago_fallido`) con el número de póliza en el query string — no hay llamada servidor-a-servidor de Quálitas hacia Django.
3. `pago_exitoso` (`qualitas/views.py:945`) es lo que realmente marca `estatus_pago='PAGADO'`, dispara la descarga de documentos, y — si `origen == 'WhatsApp IA'` — llama a `enviar_webhook_whatsapp(poliza_obj)` (el webhook hacia n8n que actualiza `conversation_phase='completed'`).

**Por qué esto es frágil, no solo "no documentado":** depende de que el navegador del cliente complete el round-trip de vuelta a Django después de pagar. Si cierra la pestaña, pierde conexión, o la app de WhatsApp/navegador móvil mata la sesión antes de la redirección, Quálitas procesó el pago pero **Django nunca se entera** — no hay ningún mecanismo de respaldo servidor-a-servidor (ni webhook, ni polling de estatus) encontrado en el código ni en la documentación. Esto no es un vacío de documentación que se pueda resolver pidiéndole el dato a Quálitas — es una limitación real de cómo está construida la integración hoy, y es exactamente la razón de fondo por la que hace falta un mecanismo independiente de verificación (ver Agente Conciliación abajo).

## ⏳ En construcción — Agente Conciliación (14 jul 2026)

Alberto confirmó que el portal de Quálitas es un login simple, sin captcha, y que el volumen
diario de pólizas a conciliar es bajo. Se decidió resolver esto con un scraper determinístico
(Playwright, sin AI en el loop) en vez de un mecanismo automático del lado de Quálitas — repo
nuevo `aibanez82/Agente-Conciliacion`, protocolo completo en
`docs/protocolos/agente-conciliacion.md`. Escribe en una tabla propia (`conciliacion_pagos`),
nunca en `qualitas_polizaemitida`. Aún sin lógica real de scraping — falta que Alberto comparta
acceso al portal.

## 🔍 Nueva vía en exploración — webservices OPL (29 jul 2026)

Alberto consiguió el PDF oficial del webservice de pago **OPL** ("Operadora en Línea"), el hueco que la doc de `qualitas-documentacion-webservices` no cubría. Guardado y resumido en `docs/qualitas-api/opl-servicios-web.md` (+ PDF `OPL-Servicios-Web-v1.3.2.pdf`).

Hallazgos de la exploración (29 jul, contra PROD, solo lectura):

1. **Django ya usa OPL** — credenciales operativas en Heroku (`QUALITAS_WPUID`/`QUALITAS_WPTOKEN`): `derivar_poliza_opl()` instala la cobranza CL y `generar_link_pasarela()` usa el REST `api.php` (`genWebPay`/`fareceipt`).
2. El WSDL PROD expone operaciones **no documentadas** en el PDF, entre ellas **`oplConciliation`** y `oplListPols` — nombres que apuntan directo a nuestro caso de uso. Pedir doc a Quálitas vía Juan.
3. `oplListReceipts` (lista recibos pendientes de cobro) **requiere una credencial que no tenemos**: el "Pid de negocio OPL" (`pid`+`token`), distinta del `wpuid`/`wptoken`. Verificado en vivo: rechaza nuestras credenciales con `Negocio Inexsistente o Token Invalido!!`. Pedir a Quálitas vía Juan.
4. Limitación semántica: `oplListReceipts` no distingue póliza pagada de cancelada (ambas responden vacío) — confirma "sigue debiendo", no "pagó". El scraping de Q360 sí distingue (columna `estado` de `conciliacion_pagos`). Por eso el plan es **cruce**, no sustitución.

**Cruce validado en vivo (29 jul, Alberto ejecutó `test-fareceipt.cjs` contra PROD):** `api.php m=fareceipt` funciona con el `wptoken` que ya tenemos y devuelve el *siguiente* recibo cobrable de la póliza:

| Estado en `conciliacion_pagos` | Póliza | Respuesta `fareceipt` |
|---|---|---|
| PENDIENTE | 7620099716 | recibo `np:1/nps:1`, `fcr`=hoy, monto coincide |
| VENCIDO | 7620098627 | recibo `np:1/nps:1`, `fcr` rodada a hoy, monto coincide |
| PAGADO (fraccionada 12 pagos) | 7620099601 | siguiente recibo `np:2/nps:12`, `fcr` 2026-08-26 → cobra el 2 ⇒ el 1 se pagó |
| CANCELADO | 7620098974 | `"No hay recibos disponibles a cobro"` |

Ambigüedad residual: póliza totalmente pagada (o contado `nps=1` pagada) responde igual que cancelada — el scraping desambigua. Por eso el API **complementa** al scraping como red de seguridad, no lo sustituye.

**Handoff entregado al Agente Conciliación** (29 jul): `Agente-Conciliacion:handoffs/2026-07-29-verificacion-cruzada-api-fareceipt.md` (rama `main`) — reglas de cruce por estado, solo `m=fareceipt`, discrepancias se alertan sin tocar `estado`. Requiere que Alberto añada `QUALITAS_WPTOKEN` como secret de GitHub Actions en ese repo.

**Pendiente vía Juan:** pedir a Quálitas el Pid de negocio OPL (para `oplListReceipts`/`getRefOpl`) y la documentación de `oplConciliation`/`oplListPols`. Borrador: `docs/2026-07-29-mensaje-juan-opl-pid-y-conciliacion.md`.

## 🎯 Salto de calidad — API REST v1.4 con `listrecs` (31 jul 2026)

Alberto recuperó el paquete completo del alta del negocio 08545/clave 27614 (correo "27614_ALTA DE NEGOCIO", nov 2025), que incluye la **spec oficial de `api.php`**: `docs/qualitas-api/Api-REST-Link-de-Pago-v1.4.pdf`, resumida en `docs/qualitas-api/api-rest-link-de-pago.md`. Cambia el tablero:

1. **`m=listrecs` (v1.4) devuelve el status de TODOS los recibos de una póliza** — `status_rec` (`pagado`/`por cobrar`/`rechazado`/`cancelado`), `fpago`, `banco`, `autoriza`, `referencia` con causa de rechazo. Es la confirmación positiva de pago que ni `fareceipt` ni `oplListReceipts` dan (ambos solo dicen "sigue debiendo"), y usa el **mismo `wptoken` que ya tenemos**, sin Pid OPL. **✅ Validado en vivo (31 jul, Alberto ejecutó `test-listrecs.sh` contra PROD, las mismas 4 pólizas del cruce fareceipt):** PAGADO → recibo `pagado` con fpago/banco/autoriza; CANCELADO → recibo `cancelado` (desambigua lo que fareceipt no podía); PENDIENTE y VENCIDO → `por cobrar` (entre sí no se distinguen — eso sigue viniendo del scraping). `searchlink` además da el ciclo de vida del link con timestamp exacto de pago (`paylink`). Tabla de mapeo y gotchas: `docs/qualitas-api/api-rest-link-de-pago.md`. Con esto el cruce del Agente Conciliación puede pasar de "red de seguridad parcial" (fareceipt) a **verificación completa por API**, y a futuro podría discutirse invertir los roles (API primaria, scraping de respaldo).
2. **`searchlink`/`cancellink`/`genlink`** responden por API a lo que Juan pidió a Laura el 23 jul (regenerar link vencido, consultar links) — la respuesta estaba en la doc del alta de nov 2025.
3. **Las llaves OPL de QA + encriptación se enviaron a `janderson.gomez@aguayo.co` (25 nov 2025)** — el Pid OPL que nos falta probablemente lo tiene el equipo de Juan; preguntar ahí antes que a Quálitas.

Nota de gobernanza (31 jul): el monitor de #140 (HYL-WAI) observó la prueba en vivo de `listrecs` como posible acción sin checkpoint. Reconciliado por Alberto en `HYL-WAI#140` (comentario `5146329245`): la ejecución fue manual/humana, pertenece a este workstream de pagos (fuera del alcance del freeze del rollout Dual) y no se contabiliza como evidencia C2 ni GO; se propuso además delimitar el freeze a la superficie Dual para no congelar la operación viva preexistente (monitor SOAP, cron Conciliación, lecturas Dashboard, api.php del flujo de venta).

## Fila original de la tabla de pendientes

| Cómo saber con certeza si un cliente pagó la póliza — la doc oficial SOAP de Quálitas (`docs/qualitas-api/`: WsEmision, WsTarifas, WsImpresion, Matriz de Captura) **no documenta ningún endpoint ni campo de consulta de estatus de pago** (verificado 7 jul). Solo cubre `FormaPago` (método/frecuencia) y los recibos generados al emitir — nada sobre si un recibo/link de pago fue efectivamente pagado. Hoy la única señal automatizada es `qualitas_polizaemitida.estatus_pago`, que depende de un webhook externo de Quálitas hacia Django no documentado en su spec (ver Bug #7 y su workaround). Detectado por Alberto al revisar una conversación con póliza emitida y link de pago enviado, sin forma de confirmar el pago desde ahí. **No es dependencia de Juan** — la resolución probable es manual: Laura (Hylant) reporta ventas/pagos confirmados en una hoja Excel al día siguiente. | 💡 Sin investigar — definir si conviene formalizar el reporte de Laura como fuente de verdad (p. ej. cargarlo al Dashboard) en vez de perseguir un mecanismo automático de Quálitas |

---

## Dictamen 25 ago 2026 — dos fuentes de pago, y una lleva una semana muerta

**Encargo de Alberto:** investigar la duplicación entre el Agente Conciliación (scraping del portal
Q 360) y el ledger de recibos de Juan (`listrecs` de `pagos.qualitas.com.mx`), y recomendar.

**Todo lo de abajo está medido el 25 ago contra la base de PROD y la API de GitHub Actions.**

### Lo que hay

| | Agente Conciliación (nuestro) | Ledger de recibos (Juan) |
|---|---|---|
| Origen | scraping del portal Q 360, Playwright | `listrecs` con token, contrato `policy-receipt-v1` |
| Tabla | `conciliacion_pagos` (308 filas) | `qualitas_qualitasproviderreceipt` (366) + snapshots (189) |
| Clave con la póliza | **texto** `numero_poliza` | **FK** `poliza_id` |
| Cadencia | cron diario (GH Actions) | poll, `SYNC_MODE=apply`, encendido en PROD |
| **Última lectura real** | **18 ago 12:59Z — hace 7 días** | **25 ago 22:00Z — hace minutos** |
| Pólizas cubiertas | 58 de 59 | **59 de 59** |
| Estados | PAGADO 34 · PENDIENTE 157 · CANCELADO 121 · VENCIDO 8 | pagado 33 · por_cobrar 141 · cancelado 121 · **rechazado 71** |

### Los cuatro hechos que deciden

1. **Nuestro scraper lleva 7 días roto y nadie se enteró.** 11 de las últimas 12 ejecuciones en
   `failure`; la única buena fue el 18 ago. Causa: `locator.fill: Timeout 30000ms` en `login()`
   (`src/conciliar.js:25`) — no entra al portal. Es la fragilidad estructural del scraping, no un
   fallo puntual.
2. **Coinciden donde se puede comparar:** 121 recibos cancelados **exactamente iguales** en ambos, y
   el mismo rango de fechas de pago (15 jun – 17 ago). No es que una fuente sea mala; es que una
   está parada.
3. **Él ve algo que nosotros no podemos ver: `rechazado`, 71 recibos.** Nuestro modelo no tiene ese
   estado. Un pago rechazado es **invisible** para nosotros. Y tiene granularidad que no tenemos:
   `installment_number`, `expected_installments`, `payment_term`, `reference`, `bank`,
   `authorization`, `card_termination`.
4. **Nuestro `VENCIDO` (8) no es información única:** se deriva de `due_date` + `por_cobrar`.

### Una sola discrepancia real, y hay que resolverla a mano

Póliza **`7620098864`** (emitida 16 jul): nosotros decimos **1 recibo pagado el 28 jul**, el ledger
dice **0**. Nuestra lectura es del 28 jul, anterior a la avería, así que **no se explica por la
caída**. O tenemos un falso positivo del portal o el `listrecs` no lo ve. **Requiere comprobación
humana contra el portal**; hasta entonces no se cierra.

### Y el hallazgo que no era el objeto de la investigación

**Tres pólizas con recibo pagado siguen en `estatus_pago = 'PENDIENTE'`:**

| Póliza | Emitida | Pagada | Confirmado por |
|---|---|---|---|
| `7620096928` | 16 jun | **16 jun** | **las dos fuentes** |
| `7620097487` | 26 jun | **2 jul** | **las dos fuentes** |
| `7620098864` | 16 jul | 28 jul | sólo la nuestra (ver arriba) |

Dos de ellas llevan **dos meses cobradas y sin reconocer**. Con `estatus_pago` mal, el Dashboard las
pinta como impagadas y el bot puede seguir persiguiendo a un cliente que ya pagó.

### Recomendación

**El ledger gana. Retirar el scraping.** No por elegancia: por cobertura, frescura, granularidad y
por un estado (`rechazado`) que nos falta — y porque el nuestro lleva una semana muerto sin que
saltara nada.

1. **Hoy — apagar el cron de Conciliación, no revivirlo por inercia.** Una fuente muerta que parece
   viva es peor que no tener fuente. Si se quiere un testigo independiente unas semanas, que sea una
   decisión explícita con su comparador automático, no el estado actual por defecto.
2. **Que el aplicador de Django consuma SU ledger, no nuestra tabla.** Hoy `conciliation_payments.py`
   lee `conciliacion_pagos` y `PAYMENT_RECONCILIATION_APPLY_ENABLED=false` lo mantiene apagado. **Ese
   camino nace obsoleto** si retiramos el scraping: leería una tabla que ya nadie alimenta.
3. **Las tres pólizas se arreglan ya**, independientemente de lo demás. Es dinero cobrado.

**Lo que NO recomiendo: mantener las dos como «doble verificación».** Suena prudente y no lo es.
Hoy teníamos dos fuentes y la discrepancia de `7620098864` llevaba semanas ahí sin que nadie la
viera, porque **nadie compara**. Dos fuentes sin comparador automático no son redundancia: son
ambigüedad, y encima cuestan el doble de mantener.

### Lección de método

Un cron que falla 11 veces seguidas sin que nadie se entere es el §2.8 de la bitácora de promoción
—«monitores que se callan»— repetido. **Todo productor de datos que alguien lea como verdad necesita
una alarma de frescura**, no sólo de error: la tabla seguía ahí, con datos plausibles, siete días
vieja.
