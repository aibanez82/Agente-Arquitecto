# Iniciativa — Suite E2E conversacional: 50 casos sin landing y sin nadie delante de WhatsApp

**Pedida por Alberto, 29 ago 2026.** **Estado: APARCADA a petición suya** («guarda esta iniciativa
para más adelante»). Este documento existe para poder retomarla en frío dentro de semanas.

> **La idea:** generar y lanzar decenas de conversaciones de prueba contra el bot, cubriendo por
> dónde puede irse una conversación real, **sin crear cotizaciones a mano desde la landing y sin que
> Alberto tenga que estar delante del teléfono**. Y más adelante, que el **Agente Mejoras
> Conversación** diga qué casos conviene ejecutar, en vez de inventarlos nosotros.

---

## 1 · Lo que ya existe y no hay que construir

El **Agente QA** (`aibanez82/Agente_QATest_Qualitas`) tiene la maquinaria montada: runners para
`n8n`, `django`, `postgres` y `dashboard`, catálogo de tests con criterios PASS/FAIL (`SUITE.md`),
fixtures de leads y teléfonos, `run_all.sh` y un agregador que arma el reporte para el Arquitecto.
**Lo que no tiene son casos conversacionales**: su suite mira sistemas, no diálogos.

Y la **inyección sintética ya se usó aquí**: en `inbound_message_buffer` de STG hay filas con
`wamid.SONDA232.b1.…` y textos como «me llamo Juan Gomez Lara». Meter mensajes al bot sin teléfono
no es teoría en este ecosistema.

## 2 · Lo verificado el 29 ago, para no repetir el trabajo

- **El `Chat Message Trigger` del bot está DESCONECTADO.** Existe en el grafo
  (`@n8n/n8n-nodes-langchain.chatTrigger`, webhookId `52d0be99-…`) y parece el atajo ideal —un webhook
  de chat sin Meta de por medio—, pero **sus salidas están vacías** y no alcanza `Session Context
  Builder`, ni `AI Agent`, ni `Send message`. Es un vestigio. **Es la primera idea que se le ocurre a
  cualquiera: ahorra media tarde saber que no vale.**
- **La entrada real es `WhatsApp Message Trigger`** (webhookId `19640449-…`) → `Phone Number ID
  Guard`. Un POST con forma de payload de Meta y el `phone_number_id` del entorno pasa el guard.
- **Verificar no necesita teléfono.** Todo lo que recibe el cliente se lee del `runData` de la
  ejecución (`Outbound Leak Guard`, `AI Agent`, los nodos `Send *`). Es como se han diagnosticado
  todos los defectos del 28-29 ago.

## 3 · Los tres obstáculos reales

1. **El envío sí necesita un número.** El bot responde por Meta. O los mensajes aterrizan en un
   teléfono —el de Alberto, sin que esté delante, que ya cumple lo pedido— o se pide a Juan **un
   número de pruebas en Meta STG**. Lo segundo es lo limpio y es la dependencia externa más lenta:
   **pedirla primero**.
2. **Las aserciones tienen que ser semánticas, no literales.** El agente no es determinista. Se
   afirma comportamiento: «no aparece ningún `https://`», «pide el VIN», «no afirma precio con
   aplicación viva», «ningún turno acaba con `outbound_count: 0`». Es la forma de los hallazgos de
   esta semana, así que el vocabulario ya existe.
3. **Volumen con efectos reales.** 50 conversaciones son 50 tarificaciones contra Quálitas QA, más
   leads, ofertas y aplicaciones. **Se avisa a Juan antes, no después**, y la suite necesita una
   convención de limpieza entre casos.

## 4 · Techos que hoy harían nacer casos en rojo por causas ajenas

- **`#250`**: la emisión por WhatsApp está rota (Django valida con `DatosEmisionForm`). Cualquier
  escenario que llegue a emitir falla por eso, no por el bot.
- **`#207`**: `available` de la liga no se puede producir en STG (ninguna póliza está a la vez en el
  ledger de recibos y con cuota pendiente).

Retomar la iniciativa **después** de estos dos, o marcar esos casos como bloqueados desde el diseño.

## 5 · La segunda mitad: que los casos los elija quien lee conversaciones

El **Agente Mejoras Conversación** ya lee Postgres y analiza abandono y tono. Puede minar
`n8n_chat_histories` para sacar **la distribución real de lo que escriben los clientes** y ordenar
los escenarios por **frecuencia × daño**, en vez de por lo que se nos ocurra.

El `#251` es el argumento: nadie habría escrito «¿y la limitada?» como caso de prueba, y es una
pregunta que los clientes hacen constantemente.

**Matiz que no hay que olvidar:** `n8n_chat_histories` **es la memoria del modelo**
(`contextWindowLength: 60`), no un log completo. Sirve para minar frases del cliente; no sirve para
contar todo lo que pasó.

## 6 · Al retomar: por dónde se empieza

1. Pedir a Juan el número de pruebas de Meta en STG (dependencia externa más lenta).
2. Handoff al Agente QA con: forma del caso de prueba, inyector de payload, aserciones semánticas,
   limpieza entre casos y formato de reporte.
3. Un primer lote pequeño —cinco casos— antes de los cincuenta.
4. Y solo después, pedir al Agente Mejoras Conversación el ranking de escenarios.

— Arquitecto-IA-Quálitas
