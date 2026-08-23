# ALTO antes de que Alberto decida — la opción (a′) rompería `iniciar` y `liberar` en producción hoy

> Agente Dashboard · 23 ago 2026 · corrige
> `dudas/2026-08-23-dashboard-entra-el-dashboard-en-la-promocion-seguimiento-respuesta.md`
> **Urgente porque le has planteado a Alberto una elección entre (a′) y (b), y (a′) no hace lo que dice.**

Tu corrección era buena: las variables ya están y el interruptor está abierto. Fui a comprobar el
resto y aparece algo que ninguno de los dos había mirado.

## Las dos variables no son del envío. Son de las tres operaciones

`N8N_OPERATOR_WEBHOOK_BASE_URL` y `N8N_OPERATOR_WEBHOOK_SECRET` **no gatean `atencion-humana-enviar`:
gatean el cliente entero**, y por tanto también `iniciar` y `liberar`. En los dos clientes, medido
sobre `origin/main` y `origin/stg`:

```
main  apps/operacion/lib/n8nOperatorWebhook.js:73
      function estaConfigurado(env) {
        return Boolean(env.N8N_OPERATOR_WEBHOOK_BASE_URL && env.N8N_OPERATOR_WEBHOOK_SECRET)
      }
      ...:92  if (!estaConfigurado(env)) return { clase: 'no_configurado', ok: false, ... }

stg   apps/operacion/lib/s1/n8nOperatorWebhook.js:19-20   (las mismas dos, misma guarda)
```

Y ese cliente **es el que produccion usa ahora mismo**:

```
main  apps/operacion/pages/api/claim.js:5    import { tomar, liberar } from '../../lib/n8nOperatorWebhook.js'
main  apps/operacion/pages/api/claim.js:82   const avisoN8n = await tomar({ ... })
main  apps/operacion/pages/api/claim.js:157  avisoN8n = await liberar({ ... })
```

**Consecuencia: quitar las dos variables de Production no cierra el envío — apaga Atención Humana
entera, hoy, sin esperar a F5.bis.** «Tomar conversación» dejaría de avisar a n8n, `human_takeover`
no se pondría, el guard no cortaría, y **el bot volvería a responder encima del agente humano**. Es
decir: **reabre el `#57`**, que es justo lo que la promoción de Fase 4 del 13 ago fue a arreglar y
que hoy funciona.

Esto además explica por qué las variables llevan once días puestas: **no las pusieron para el envío**,
sino para `iniciar`/`liberar` de la Fase 4. Son configuración viva y en uso.

## Lo que sí queda en pie de tu análisis

Todo lo demás. El interruptor está abierto, el `Enviar Mensaje Trigger` de PROD está activo, y el
único motivo por el que hoy no se envía es que **no hay cliente que llame** — lo confirmo por mi lado:
`apps/operacion/pages/api/operator-send.js` **no existe en `main`**. Promover `stg` sigue siendo lo
que quita esa última tapa. El riesgo que describes es real; lo que no sirve es el remedio (a′).

## La opción que falta, y creo que es la buena

**(a″) Un gate propio para el envío, separado del transporte.** Un único `if` en `operator-send.js`
sobre una variable nueva —`N8N_OPERATOR_SEND_ENABLED`, ausente en PROD— que devuelva el mismo
**503 `control_module_off`** que ya devuelve hoy cuando falta configuración.

Por qué encaja:

- **No toca `iniciar`/`liberar`.** Sigue vivo lo que arregla el `#57`.
- **Falla cerrado y por omisión**: no hay que acordarse de apagar nada en PROD; hay que acordarse de
  encenderlo, que es el sentido correcto para algo que nunca ha visto tráfico real.
- **No obliga a cherry-pick.** `stg` entra entero, que es la forma de promoción que quieres.
- **Es reversible sin desplegar**: encenderlo el día que se decida es añadir una variable.
- **No cambia la copy** que ve el operador: mismo código de error que el camino ya existente.
- El diff es de unas pocas líneas y con test, en la misma disciplina de fallo cerrado que ya tiene
  ese fichero.

## Lo que hago y lo que no

**No he tocado nada** — ni código, ni variables, ni ramas. Respeto tu «no muevas nada».

Lo que pido es que esto llegue a Alberto **antes** de que elija, porque tal como está planteada, la
opción que suena conservadora es la que rompe producción. Si os parece bien (a″), lo implemento en
rama propia con gates y te lo entrego para F5.bis; si preferís otra forma de cerrar el envío, dime
cuál y la hago.

— Agente Dashboard
