# Handoff Arquitecto → Agente n8n — Extender el monitor de Quálitas a wsTarifa y QBCImpresion

> Autor: Arquitecto-IA-Qualitas · 20 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-20-handoff-agente-n8n-extender-monitor-qualitas.md` — deja también copia en `Agente-n8n/handoffs/`.
> **Workflow destino: `Monitor Qualitas SIO PROD`** (id `3NQfglVIfPSdijm9`, n8n PROD). No es parte del flujo conversacional del bot — bajo riesgo, pero de todos modos probá manualmente (Execute Workflow / duplicar y probar en copia inactiva) antes de dejarlo corriendo en el schedule real, ya que no existe un gemelo en STG para este workflow en particular (nunca se construyó uno — es un utilitario standalone).

## Objetivo

Hoy el monitor certificado (18 jul 2026) solo chequea `WsEmision` (`sio.qualitas.com.mx`), que
cubre cotización + emisión. Confirmé leyendo `qualitas/services.py` en Django (`HYL-WAI`) que en
PROD **también dependemos de otros dos webservices de Quálitas, en un host distinto**
(`qbcenter.qualitas.com.mx`), que hoy no tienen ninguna alerta:

- **`wsTarifa`** (`http://qbcenter.qualitas.com.mx/wsTarifa/wsTarifa.asmx`) — cálculo de
  tarifas/precio (`services.py` líneas 92 y 157).
- **`QBCImpresion`** (`http://qbcenter.qualitas.com.mx/QBCImpresion/Service.asmx`) — generación
  de PDF de póliza/recibo (`services.py` línea 954).

Como corren en un host distinto al ya monitoreado, si `qbcenter.qualitas.com.mx` cae mientras
`sio.qualitas.com.mx` sigue arriba, hoy no nos enteramos — el bot podría fallar calculando
tarifas o generando el PDF de la póliza sin que salte ninguna alerta.

Verifiqué conectividad real a ambos endpoints (20 jul, GET simple sin `?WSDL`, igual que el
check existente de WsEmision): los dos responden `200` — mismo patrón funciona.

## Diseño — replicar el patrón exacto que ya usa el workflow para WsEmision (confirmado leyendo
## el workflow vivo vía API, no de memoria)

El patrón actual, por servicio, son 6 nodos encadenados desde el mismo trigger:
```
Every 10 min → Check <servicio> (httpRequest, onError: continueErrorOutput)
  ├─ output 0 (éxito) → Update State - Up (code) → Should Notify Recovery? (if) → Send Recovery Message (telegram)
  └─ output 1 (error) → Update State - Down (code) → Send Down Alert (telegram)
```
- El estado se guarda en `$getWorkflowStaticData('global')`, una key booleana por servicio
  (hoy: `qualitasWasDown` para WsEmision). Para los dos nuevos, usar keys separadas:
  `wsTarifaWasDown` y `qbcImpresionWasDown` — **no reutilizar la misma key**, cada servicio cae
  y se recupera de forma independiente.
- Mismo Telegram (credencial + `chatId: "357953725"`) para los tres — son alertas del mismo
  canal de monitoreo, no hace falta separarlos.
- **No refactorizar a un loop genérico** — el workflow ya está certificado y corriendo en PROD
  cada 10 min sin fallos; duplicar el patrón probado 2 veces más es más seguro que introducir
  una abstracción nueva en un workflow ya en producción. Si en el futuro se agregan más
  servicios y esto se vuelve repetitivo, se evalúa un refactor aparte — no ahora.

### Nodos nuevos — wsTarifa

- **`Check wsTarifa`** (httpRequest, `onError: continueErrorOutput`):
  `GET http://qbcenter.qualitas.com.mx/wsTarifa/wsTarifa.asmx`, timeout 15000 (igual que el
  existente).
- **`Update State - Up (Tarifa)`** (code):
  ```js
  const staticData = $getWorkflowStaticData('global');
  const wasDown = staticData.wsTarifaWasDown === true;
  staticData.wsTarifaWasDown = false;
  return [{
    json: {
      shouldNotify: wasDown,
      message: "✅ Quálitas wsTarifa (PROD) se restableció — qbcenter.qualitas.com.mx responde normal de nuevo."
    }
  }];
  ```
- **`Should Notify Recovery? (Tarifa)`** (if): misma condición exacta que el original
  (`{{ $json.shouldNotify }}` es `true`).
- **`Update State - Down (Tarifa)`** (code):
  ```js
  const staticData = $getWorkflowStaticData('global');
  staticData.wsTarifaWasDown = true;
  return [{
    json: {
      message: "⚠️ Quálitas wsTarifa (PROD) no responde — qbcenter.qualitas.com.mx/wsTarifa. Puede estar afectando el cálculo de tarifas/precio en cotizaciones reales. Se reintentará en el próximo chequeo."
    }
  }];
  ```
- **`Send Recovery Message (Tarifa)`** / **`Send Down Alert (Tarifa)`** (telegram): mismo
  `chatId` y misma credencial que los nodos existentes, `text` = `{{ $json.message }}`.

### Nodos nuevos — QBCImpresion

Mismo patrón exacto, cambiando URL, la key de static data (`qbcImpresionWasDown`) y los
mensajes:
- **`Check QBCImpresion`**: `GET http://qbcenter.qualitas.com.mx/QBCImpresion/Service.asmx`,
  timeout 15000.
- Mensaje de caída: `"⚠️ Quálitas QBCImpresion (PROD) no responde — qbcenter.qualitas.com.mx/QBCImpresion. Puede estar afectando la generación de PDF de pólizas/recibos. Se reintentará en el próximo chequeo."`
- Mensaje de recuperación: `"✅ Quálitas QBCImpresion (PROD) se restableció — qbcenter.qualitas.com.mx responde normal de nuevo."`

### Conexión desde el trigger

`Every 10 min` debe apuntar a las 3 cadenas en paralelo: `Check Qualitas SIO` (ya existe),
`Check wsTarifa` (nueva), `Check QBCImpresion` (nueva) — todas disparadas por el mismo
schedule, cada una independiente de las otras dos.

## Tareas

1. Agregar los nodos de arriba, conectados en paralelo al trigger existente.
2. Probar manualmente (Execute Workflow, o duplicar el workflow y ejecutar la copia) antes de
   dejarlo en el schedule real — confirmar que las 3 cadenas corren sin interferir entre sí en
   la misma ejecución.
3. Simular una caída de cada servicio nuevo (ej. apuntar momentáneamente la URL a un host que no
   responda, o bajar el timeout a un valor que fuerce el error) para confirmar que
   `Send Down Alert` dispara y que, al restaurar la URL correcta, `Send Recovery Message`
   también dispara — mismo criterio de prueba que se usó para certificar el monitor original
   (`docs: certifica monitor de Quálitas SIO en PROD`, 18 jul).
4. Confirmar que las 3 cadenas no interfieren entre sí (una caída de `wsTarifa` no debe afectar
   el estado ni las alertas de `WsEmision` ni de `QBCImpresion`).
5. Reportar el commit + resultado de la prueba.

## Fuera de alcance

- El webservice de pago (OPL) — no está documentado en
  `HYL-WAI:docs/qualitas-documentacion-webservices/`, no se puede monitorear sin conocer su
  endpoint real. Si Alberto lo consigue más adelante, es un handoff aparte.
- Refactor genérico del workflow a un loop parametrizado — explícitamente fuera de alcance por
  ahora (ver "Diseño" arriba).
