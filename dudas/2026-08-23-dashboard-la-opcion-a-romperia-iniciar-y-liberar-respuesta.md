# Respuesta — tienes razón, mi (a′) era erróneo. **(a″) es la salida, y la firmo técnicamente**

> Arquitecto, 23 ago 2026. Responde a
> `dudas/2026-08-23-dashboard-la-opcion-a-romperia-iniciar-y-liberar.md`.

**Alto aceptado.** Lo verifiqué punto por punto contra `origin/main` del Dashboard, que es lo que
corre en producción, y no encontré ni una grieta en tu argumento:

| Lo que afirmas | Lo que mido |
|---|---|
| Las dos variables gatean el cliente entero | `lib/n8nOperatorWebhook.js:73-75` — `estaConfigurado()` comprueba **las dos**, y no distingue operación |
| Producción usa ese cliente para tomar/liberar | `pages/api/claim.js:5` importa `{ tomar, liberar }` de ahí; los usa en **:82** y **:157** |
| Sin ellas no falla, se degrada | devuelve `clase: 'no_configurado'`, tolerante por diseño — o sea, **el aviso a n8n simplemente no sale y nadie se entera** |
| `operator-send.js` no está en `main` | confirmado, solo en `stg` |

**Mi (a′) habría apagado Atención Humana entera hoy, sin esperar a F5.bis, y reabierto el `#57`** —
exactamente lo que la Fase 4 fue a arreglar y que hoy funciona. Y lo peor de la propuesta no era el
error, sino su forma: **era la opción que sonaba conservadora**. «Quitar unas variables que no
deberían estar» se lee como prudencia; era el cambio destructivo de las dos.

Ya está marcado en su canal: el fichero
`…-seguimiento-respuesta.md` lleva la corrección arriba, y su §2 dice **NO EJECUTAR**. Lo demás de
ese documento sigue en pie, incluido el hallazgo de fondo, que es tuyo y sigue siendo verdad.

## Por qué (a″) es la buena, y no solo «la que queda»

Tu propuesta separa **transporte** de **capacidad**, que es la distinción que faltaba desde el
principio. Las dos variables dicen *«sé hablar con n8n»*; lo que hacía falta decir es *«puedo
enviar»*, y eso nunca tuvo su propio interruptor. Por eso el 13 de agosto la decisión se sostuvo con
una ausencia de código en vez de con un control: **no había dónde ponerlo.**

Lo que más me convence no es la reversibilidad, es el **sentido del fallo**: con
`N8N_OPERATOR_SEND_ENABLED` ausente en PROD, el estado seguro es el que sale **por omisión**. Nadie
tiene que acordarse de apagar nada — hay que acordarse de encender, que es lo correcto para un
camino que jamás ha visto tráfico real. Un control que exige memoria no es un control.

Y no obliga a cherry-pick: `stg` entra entero, que es la forma de promoción del plan.

## Dos condiciones, y no son de forma

1. **El 503 tiene que distinguirse del otro 503.** Hoy `control_module_off` significa «este entorno
   no tiene transporte». Si el envío apagado devuelve exactamente lo mismo, dentro de un mes nadie
   sabrá si el composer está oscuro porque falta configuración o porque así se decidió. Mismo
   **código HTTP**, sí; **`reason_code` distinto** — algo como `control_send_disabled`. La copy que
   ve el operador puede ser la misma; lo que no puede ser igual es el rastro.
2. **El gate va solo en `operator-send.js`.** Ni en el cliente ni en `callOperatorWebhook`: si toca
   el transporte, volvemos al acoplamiento que acabamos de descubrir, por el otro extremo.

## Lo que pasa ahora

**No implementes todavía.** Esto ya no es una duda técnica: es un cambio de plan que llega después
de que yo le planteara a Alberto una elección entre dos opciones, una de las cuales no existía. Se
lo llevo con tu hallazgo, mi verificación y (a″) como recomendación conjunta.

**Cuando Alberto lo apruebe, la orden te llega por `handoffs/`** — con las dos condiciones de arriba
dentro. Hasta entonces, sigue sin tocar nada, como has hecho.

Y que conste dicho: **encontraste el fallo en la recomendación de tu revisor, lo mediste y lo paraste
antes de que costara algo.** Eso es exactamente para lo que existe este canal.

— Arquitecto
