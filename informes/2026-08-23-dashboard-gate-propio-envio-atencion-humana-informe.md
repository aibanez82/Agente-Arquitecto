# Informe — gate propio para el envío de Atención Humana (`N8N_OPERATOR_SEND_ENABLED`)

> Agente Dashboard · 23 ago 2026
> Ejecuta `Dashboard:handoffs/2026-08-23-gate-propio-para-el-envio-de-atencion-humana.md`
> **Entregado en PR y parado ahí. Sin merge, sin variables tocadas, sin `main`.**

## Entrega

| | |
|---|---|
| Rama | `feature/gate-propio-envio-atencion-humana` (de `stg@ac99994`) |
| SHA | **`509b1b3ecd5d2deb3b06ba0d189e02fe47db8157`** |
| PR | `aibanez82/Dashboard_seguroautoqualitas#6` → `stg`, **abierto, sin mergear** |
| Gates | **229/229** (225 antes, +4) y `check-claude-md-paths.sh` OK |
| `reason_code` | **`control_send_disabled`** — el que proponías |

## El diff del gate

Dos piezas en `apps/operacion/pages/api/operator-send.js`, y nada más en producción de código:

```js
const SEND_ENABLED_ENV = 'N8N_OPERATOR_SEND_ENABLED'

function humanSendEnabled(env = process.env) {
  return env?.[SEND_ENABLED_ENV] === 'true'
}
```

```js
  if (!operatorWebhookConfigured()) {
    return fail(res, 503, 'control_module_off', 'El envío humano no está configurado')
  }
+ if (!humanSendEnabled()) {
+   return fail(res, 503, 'control_send_disabled', 'El envío humano no está configurado')
+ }
```

Va **inmediatamente después** de la guarda de transporte y **antes de la validación de parámetros**,
o sea antes de la primera lectura de BD y de cualquier efecto. Con el envío apagado, el handler no
consulta nada ni llama a nadie.

## Las dos condiciones

**A · `reason_code` distinto — hecho.** `control_send_disabled`, mismo HTTP 503 y misma copy que
`control_module_off`.

Me pedías decirlo si tenía uno mejor en la nomenclatura del módulo: **usé el tuyo**, y por una razón.
Hay dos familias en este fichero — `control_*` para estado del módulo (`control_module_off`,
`control_transport_unconfigured`) y `human_send_*` para desenlaces de un envío intentado
(`human_send_uncertain`, `human_send_failed`, `human_send_blocked`). Este caso **nunca llega a
intentar** el envío, así que pertenece a la primera. Y queda leyéndose en contraste directo con su
hermano: *módulo apagado* frente a *envío deshabilitado*.

**B · El gate solo en `operator-send.js` — hecho.** No toca `lib/s1/n8nOperatorWebhook.js`, ni
`callOperatorWebhook`, ni `operatorWebhookConfigured()`, ni `claim.js`. `iniciar` y `liberar` quedan
exactamente como estaban.

## Ausente = apagado, y estricto

Comparación con el literal `'true'`, misma forma que `DASHBOARD_DISCOUNTS_V06_ENABLED`. No es
cosmética: con una comprobación laxa, un `N8N_OPERATOR_SEND_ENABLED=false` mal puesto —o un `0`, que
en JS es una cadena no vacía y por tanto truthy— **encendería** el envío. Con la estricta, cualquier
cosa que no sea exactamente `'true'` lo deja apagado. El único valor que enciende es el que alguien
tuvo que escribir a propósito.

## Evidencia de los tests

Cuatro nuevos, en `scripts/s1/test/claim-control-handler.test.js`:

| Test | Qué acredita |
|---|---|
| `envío APAGADO por omisión` | 503 `control_send_disabled`, **cero fetch y cero queries** |
| `los dos 503 se distinguen` | transporte ausente → `control_module_off`; envío apagado → `control_send_disabled` |
| `solo acepta el literal "true"` | `1`, `yes`, `TRUE`, `True`, `on`, `""` no encienden |
| `camino actual intacto` | con la variable, 200 y **una** llamada a `.../webhook/atencion-humana-enviar` |

Dos detalles de método, porque pediste acreditar las dos mitades y no solo el código:

1. El caso apagado usa un **cuerpo válido**. Con un cuerpo vacío el test pasaría igual aunque el gate
   estuviera mal colocado detrás de la validación, y no acreditaría nada.
2. **Verificación por mutación.** Retiré el gate y corrí la suite: los nuevos **fallan** — sin él la
   petición llega a las lecturas y devuelve `404` en vez de `503`. No están verdes por vacuidad.

```
✖ el gate solo acepta el literal "true"
  AssertionError: "1" no debe encender el envío
  404 !== 503
```

## Una nota sobre los fixtures, por si revisas el diff

`withOperatorEnv` (en `claim-control-handler.test.js`) y el `env` del test de continuación **no
conocían la variable**, así que con el gate puesto habrían ejercido el camino apagado en todos los
positivos y la suite se habría caído en sitios que no tienen que ver con esto. Ahora declaran
`N8N_OPERATOR_SEND_ENABLED: 'true'` explícitamente: representan un mundo con el envío habilitado, que
es lo que esos tests siempre quisieron ejercer. Es cambio de fixture, no de aserción — ninguno de los
tests existentes afloja lo que comprobaba.

## Lo que NO he tocado

- **Ninguna variable de entorno, en ningún entorno.** Ni PROD, ni Preview, ni `.env` local. Crear
  `N8N_OPERATOR_SEND_ENABLED` el día que se decida encender es de quien corresponda; mi trabajo era
  que su **ausencia** fuese segura, y lo es.
- **`main`, la promoción y F5.bis.** Nada movido.
- **`stg`.** El PR está abierto y parado, como ordena el handoff.

## Lo que queda en tu tejado

Revisar el PR `#6` y, cuando Alberto lo ordene, el merge. Si prefieres otro `reason_code`, otra
colocación del gate o que el flag admita más de un literal, dilo y lo cambio — es un commit.

— Agente Dashboard
