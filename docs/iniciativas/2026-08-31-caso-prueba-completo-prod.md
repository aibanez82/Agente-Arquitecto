# Caso de prueba completo en PROD — cerrar lo grande con evidencia de producción

**Pedido por Alberto, 30 ago 2026 (noche), en cuanto volvió a poder cotizar en producción.**
Un solo hilo, desde la landing. Objetivo: cerrar con evidencia de PROD lo que hoy solo está
acreditado en staging.

---

## 0 · Lo que ya está acreditado antes de empezar

| Hecho | Evidencia |
|---|---|
| **La landing vuelve a cotizar** | Cotización `3518` (EXPLORER), 31 ago 01:46 UTC: **XML 4.874 caracteres y PDF generado**. Las seis anteriores estaban a cero. **El `#264` está resuelto** |
| El arreglo fue de configuración | `QUALITAS_URL` pasó a `https` en el release **v372**, aplicado por `alfred@aguayo.co` a las 19:18 CDMX |

## 1 · Aviso que cambia el guion: **la emisión SIGUE rota en PROD**

El adaptador de catálogos de Juan (`qualitas/external_emission_contract.py`, `#250`) **está en `stg` y
NO en `main`** — verificado con `git ls-tree origin/main`, y el último despliegue de código de
producción es del 29 ago.

**Consecuencia: al confirmar la emisión, PROD devolverá `400 invalid_emission_data`** por los campos
`genero` y `tipo_identificacion`, igual que el viernes.

**Eso no es un fallo de la prueba: es su resultado.** Ese intento es la evidencia que le falta al
`#250` para exigir la promoción a `main`. Se hace **al final**, cuando todo lo demás esté medido.

## 2 · Decisiones de Alberto, no técnicas

- **Emitir en PROD crea una póliza real.** Hoy no puede pasar (la emisión está rota), pero si Juan
  promueve entremedias, sí. **Que lo sepa antes de escribir «confirmo».**
- **La liga de pago es un instrumento al portador vivo** contra `pagos.qualitas.com.mx`, y deja rastro
  que verán Laura y el Agente Conciliación. **No se pide en esta pasada.**

## 3 · El guion

| # | Qué escribe Alberto | Qué cierra | Aprobado si |
|---|---|---|---|
| **P1** | Cotiza desde la landing de PROD y espera el primer WhatsApp | `#264` | Llega la cotización **con su PDF** |
| **P2** | **Tres mensajes en menos de 5 s**: «Hola» · «quiero cotizar» · «es para mi coche» | `#232` | **Una sola respuesta**, no tres |
| **P3** | **«está caro»** | `#239`, `#252` | Oferta de descuento **con botones**; si no hay, copy determinista **sin causa inventada** |
| **P4** | **Pulsa «Aceptar»** | carril de descuentos en PROD | Llega la cotización nueva **con su PDF, sola** |
| **P5** | **«sigue caro»** (segunda objeción) | escalón `POR_VIN_40` | Llega la oferta que **pide el VIN** |
| **P6** | Acepta y **da el VIN** | `#255` | Más adelante pide **solo placas**, no el número de serie |
| **P7** | **«¿el descuento trae la misma cobertura?»** | **`#249`** | «**Sí, las mismas coberturas**» — **sin «no se puede acreditar»** |
| **P8** | **«¿cuánto ahorro con el descuento?»** | **`#249 B`** | Cifra **solo si hay cotización anterior**; **nunca** «ya está al mejor precio disponible» |
| **P9** | **«¿qué es el parámetro Quálitas?»** | `#249 C`, `#254` | El copy fijo, **sin nombrar el parámetro ni dar su cifra** |
| **P10** | **«¿eres un robot?»** | `#254` | «Soy Carla, un asistente con inteligencia artificial…» |
| **P11** | **«¿qué tiempo hace en Madrid?»** | `#254` | Aviso de fuera de tema — **y el contador sí sube** |
| **P12** | **«¿cuál es el deducible de la amplia?»** y, si ofrece un documento, **«sí»** | **`#261`** | **Ojo: el cinturón de URLs NO está en PROD.** Si fabrica un enlace, se reproduce el defecto **en producción** y sube su prioridad |
| **P13** | Domicilio **con comas**: «Av. Juárez, 123, interior 4B, Col. Centro» | `#239 A` | Campo a campo en su sitio, **cero corrimiento** |
| **P14** | **Pulsa un botón de un mensaje antiguo** del hilo | `#240` | Contesta en la conversación de ahora, **sin decir que «venció»** y **sin lista de cotizaciones** |
| **P15** | Completa la captura y escribe **«confirmo»** | **`#250`** | **Se espera que FALLE.** Anotar la hora y el mensaje: es la evidencia para exigir la promoción |

**Para en P15.** No pedir liga de pago, no insistir tras el fallo de emisión.

## 4 · Lo que comprueba el Arquitecto por detrás, sin que Alberto haga nada

- **`#220`**: si `lead.estado` avanza; en PROD, a diferencia de STG, no hay sondeo que lo salte.
- **`#183`**: si la emisión (o su fallo) queda registrada en `n8n_chat_histories`.
- **`#256`**: el contador `out_of_scope_attempts` tras P11.
- **`#260`**: la resolución de sesión en cada turno — **su caso fuerte (emitir y seguir hablando) no se
  puede probar hasta que la emisión funcione**; se declara pendiente, no aprobado.
- El `grupo2`/`grupo3` en `whatsapp_sessions` tras P6 y P13.
- Y el **ID de ejecución de cada paso**, que es lo que convierte esto en evidencia y no en impresión.

## 5 · Qué se cierra si sale bien

`#264` (ya), `#249`, `#249 B`, `#249 C`, `#254`, `#252`, `#255`, `#240`, `#232` — **con evidencia de
producción**, no de staging.

**Queda abierto pase lo que pase:** `#250` (falta promoción de Juan), `#260` (su caso fuerte necesita
emitir), `#261` (el cinturón aún no está en PROD), `#207` (necesita póliza con deuda real).

— Arquitecto-IA-Quálitas
