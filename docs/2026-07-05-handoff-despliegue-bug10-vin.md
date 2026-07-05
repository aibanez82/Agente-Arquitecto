# Handoff de despliegue — Bug #10 (VIN) a producción, en lockstep

> Autor: Arquitecto-IA-Qualitas (Nivel 2)
> Fecha: 5 julio 2026
> Ejecutores: **Agente n8n** (import + reconciliación del prompt) + **Juan** (deploy Django) + **Alberto** (coordinación + import a prod n8n).
> Urgencia: 🔴 desbloquea escalar ventas el lunes. Coordina el Arquitecto; los ejecutores no se hablan entre sí.

---

## Por qué urge (evidencia fresca, 5 jul)

Auditoría de las últimas 7 emisiones reales (`n8n_chat_histories`, `Calling Issue_Policy`, `parameters18_Value`):

| id | serie emitida | válida |
|---|---|---|
| 4566 | **Gómez Palacio** | ❌ ciudad |
| 4493 | 4V1VBAME4LN898767 | ✅ |
| 4382 | 1HGRW1893KL905088 | ✅ |
| 4318 | **Ciudad General Escobedo** | ❌ |
| 4206 | 4T1BE46K97U057158 | ✅ |
| 4008 | **Ciudad de México** | ❌ |
| 3737 | **Hidalgo** | ❌ |

**~57% de pólizas con una ciudad en lugar del VIN.** El Bug #10 sigue **activo en producción**. El fix está construido pero vive en `stg`, sin desplegar.

---

## Estado del código (ambos lados hechos en `stg`, con UNA salvedad)

- **Django (Juan):** ✅ gate `vehicle_series.py` en rama `stg` — regex VIN-17 + rechazo geográfico + contrato `400 {code:"invalid_vehicle_serie", reason}`. Certificado 31/31. Guía: `aguayo-co/HYL-WAI:docs/guia-n8n-validacion-serie-vin.md`.
- **n8n (Agente n8n):** ✅ Opción A en rama `stg` del repo `Agente_n8n` (`591569f`→`2570dea`): `neverError:true` en `Issue Policy` (verificado en el JSON), manejo del `400`, regex de `Validate` en paridad, prompt con menciones VIN-17.

### ⚠️ Hallazgo — la rama `stg` NO está lista para desplegar tal cual

Inspección del JSON `stg` en git (`workflows/WhatsApp Insurance Quotation Bot.json`):
- `neverError` de `Issue Policy` = **true** ✅
- Trigger `webhookId` = `18c1b498-...` (el de prod) ✅
- **PERO conserva ~4 menciones reales de "5-20 caracteres" para la serie**, conviviendo con las de VIN-17 (los otros "5-20" son falsos positivos de IDs de modelo `claude-*-4-5-2025...`). Ubicaciones reales:
  1. `...Número de serie del vehículo (5-20 caracteres alfanuméricos)` (listado de grupos)
  2. `"serie": "..." // ...(5-20 caracteres alfanuméricos, del Grupo 2)` (ejemplo JSON)
  3. `**serie**: ...(5-20 chars alfanuméricos)`
  4. `"description": "Vehicle serial/VIN number (5-20 alphanumeric characters)"` (`$fromAI`)

**Consecuencia si se despliega así:** el bot aceptaría una serie de 5–16 chars (p. ej. la de Sandra Luz `3N1CN8AE40531V` = 14) que el gate de Django luego **rechaza** → **loop muerto** para el cliente. La decisión del 4-jul fue **serie = exactamente 17 (VIN completo)**. Esa reconciliación (Capa 3a) quedó pendiente.

---

## Tareas

### 🟦 Agente n8n (antes de importar a prod)

1. **Reconciliar el prompt a "exactamente 17":** reemplazar las ~4 menciones reales de "5-20" por "exactamente 17 caracteres (VIN completo)" en el `systemMessage` y en la `description` `$fromAI` de la serie. Deben quedar **coherentes con la regex canónica de Django** `^[A-HJ-NPR-Z0-9]{8}[0-9X][A-HJ-NPR-Z0-9]{8}$`. Commit en `stg`.
2. **Preparar el JSON para prod SIN recrear la colisión (Bug #12):**
   - Mantener el trigger `webhookId = 18c1b498-024e-4803-8088-56ccf9812f33` (el de prod).
   - Que el import **actualice el workflow de prod existente** `id = BtOaZm7WlZT-24V7hqCnF`, NO cree uno nuevo. Vía recomendada: **`PUT /api/v1/workflows/BtOaZm7WlZT-24V7hqCnF`** con el JSON (nodes/connections/settings), conservando id y webhookId.
   - Renombrar de `..._stg` al nombre de prod `WhatsApp Insurance Quotation Bot`.
3. Entregar a Alberto el JSON/comando listo, o ejecutar el `PUT` con la `N8N_API_KEY`.

### 🟩 Juan (Django)

4. **Mergear `stg`→prod y desplegar** el gate `vehicle_series.py`. Es el backstop que **garantiza** que ninguna ciudad llegue a Quálitas (rechazo determinista con `400 invalid_vehicle_serie`).

### 🟨 Alberto (coordinación)

5. Sincronizar el timing del rollout (abajo) y, tras desplegar, correr la verificación.

---

## Orden de rollout (lockstep — importa)

**n8n primero (o los dos juntos), Django inmediatamente después. NUNCA Django solo primero.**

- Si Django despliega el rechazo `400` **antes** de que n8n maneje el 400 con gracia → emisiones **atascadas** (dead-end al cliente).
- Con n8n ya desplegado (VIN-17 + `neverError` + manejo del 400), el gate de Django solo mejora la garantía.

```
1. Agente n8n reconcilia "5-20"→"17" y prepara el JSON (webhookId + id de prod)
2. Alberto/Agente n8n hace PUT a prod BtOaZm7 (o import cuidadoso)
3. Deactivate→Activate del workflow → re-registra el webhook (confirmar que sigue 18c1b498)
4. Juan mergea+despliega Django (mismo día, justo después)
```

---

## Verificación post-deploy (obligatoria)

1. **Inbound intacto:** mandar un "hola" de prueba → ejecución nueva en el bot + respuesta. (No recaer en Bug #12: confirmar que el `webhookId` sigue `18c1b498` y NO hay workflows duplicados nuevos.)
2. **Serie válida fluye:** una conversación con VIN-17 real → emite normal.
3. **Serie inválida se bloquea con gracia:** forzar una serie tipo ciudad / de 14 chars → el bot **re-pregunta** (no dead-end, no póliza mala). Como es prompt a temp 0.7, correr 2-3 veces.
4. **Backstop Django:** confirmar que un `POST /api/emitir-externo/` con serie inválida devuelve `400 invalid_vehicle_serie` (no emite).

---

## Pendiente aparte (no bloquea el deploy, sí la limpieza)

- **Reemisión manual con Quálitas** de las pólizas ya emitidas con serie inválida: mapear los ids `4566` (Gómez Palacio), `4318` (Ciudad General Escobedo), `4008` (Ciudad de México), `3737` (Hidalgo) a sus números de póliza, + las históricas `7620096850` y `7620098065`. (Alberto pidió esta lista como tarea separada — la preparo cuando quieras.)
- **Capa 2 (mapeo rígido)** — que `Issue_Policy.serie` lea el valor ya validado en vez de un `$fromAI` nuevo — sigue diferida. No es necesaria para el lunes (Django es el gate), pero es el endurecimiento definitivo.
