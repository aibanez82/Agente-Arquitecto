# Diagnóstico Arquitecto — M47, M48, M49, Adenda 9

> Autor: Arquitecto-IA-Qualitas · 22 jul 2026
> Responde a: `Agente-MejorasConversacion/informes/parches/2026-07-22-handoff-agente-n8n-m47-m48-m49-adenda9.md`
> Verificación hecha contra **PROD vivo vía API** (`BtOaZm7WlZT-24V7hqCnF`), no contra el export
> local — que estaba desactualizado (61 nodos vs 107 reales; ver `CLAUDE.md` → Pendientes de
> infraestructura). Export local ya corregido en este mismo commit.

## M47 — confirmado: no existe nada parecido hoy

El bloque "RENOVACIÓN DE PÓLIZA" del `systemMessage` (nodo `AI Agent`, PROD) redirige
**incondicionalmente** cualquier mención de renovación al WhatsApp de renovaciones (5537511678),
sin distinguir mención pasiva ("¿mi póliza vieja afecta la nueva?") de intención explícita
("quiero renovar"). Hay que agregarlo de cero.

**Hallazgo transversal no capturado en la tabla de Mejoras Conv.:** el texto de M47 dice
*"que inicie justo cuando venza la actual"* — eso es activación futura (`FechaInicio` = fecha de
vencimiento de la póliza vieja). Es **el mismo bloqueante técnico que M48** (`FechaInicio`
hardcodeado a hoy+1 en `HYL-WAI/qualitas/services.py:452-454`, sin parámetro de entrada). La
tabla original marca a M47 sin bloqueante — es un error, corrijo: **M47 y M48 comparten el mismo
bloqueante de Django** y deberían ir en el mismo handoff/ despliegue, no por separado.

## M48 — confirmado, mismo bloqueante que M47

M34 (el bloque que M48 reemplaza) está confirmado live, sin cambios desde el 17 jul. El
bloqueante que reportó Mejoras Conv. es correcto y ya lo tenía yo mismo confirmado en esta misma
sesión: `FechaInicio` en el WS de Quálitas acepta hoy o cualquier fecha futura (spec
`HYL-WAI:docs/qualitas-documentacion-webservices/markdown/03-esquema-xml-emision.md`: *"no debe
ser menor a la fecha actual"*, sin tope máximo documentado), pero Django lo tiene fijo a hoy+1 y
no lo expone como parámetro ni en `generate_xml_payload` ni en la tool que llama el bot.

**Respuestas a lo que pide el handoff:**
1. **¿Puede Juan exponer `fecha_inicio`?** — no lo sé todavía, es pregunta para él, no algo que
   pueda confirmar desde aquí. Lo agrego a Pendientes de infraestructura como bloqueante externo.
2. **¿Tiene sentido desplegar el copy en STG mientras tanto?** — sí, con una condición: el copy
   de M47/M48 en STG debe ir acompañado de una nota en el propio handoff a Agente n8n dejando
   explícito que es solo para validar la conversación (tono, momento en que se ofrece, que no
   escale a contact center) — **no promover a PROD hasta que el campo `fecha_inicio` exista en
   Django**, porque si no el bot promete una fecha de activación que el sistema real no cumple
   (emitiría con hoy+1 aunque diga "cuando venza tu póliza actual"). Mismo patrón de guardrail
   que ya usamos para METEPEC (`docs/2026-07-20-handoff-agente-n8n-parquear-metepec-de-stg.md`).

## M49 — parcialmente desplegado, gap real identificado

Existe ya en PROD (nodo `AI Agent`, bloque "EDGE CASE — Cliente pregunta por 'promociones',
'descuentos', 'precio especial', u 'ofertas'") una regla que da precisamente el enfoque que pide
Alberto: precio preferencial digital + MSI, sin depender de la KB genérica. **Esto contradice la
nota vieja del 17-jul** ("necesita reemplazar líneas 183-188, no está listo") — alguien lo
desplegó entre el 17 y hoy sin dejar registro (repite el patrón de "Alberto salta al Arquitecto"
ya conocido).

Pero tiene dos huecos reales, que explican por qué L1668 vio "tipo de negocio":
1. **No menciona el recargo por fraccionar** — el texto vivo solo habla de MSI, no de que
   fraccionar sin MSI trae recargo. Falta agregarlo.
2. **Solo existe en `AI Agent`, no en `RAG IA Agent`** — si la pregunta del cliente entra por la
   rama de KB/RAG (`RAG IA Agent`, que sí tiene acceso a `search_doc_corpus`), no hay ningún
   guardrail que le impida traer contenido de "tipo de negocio" (probablemente un chunk de la KB
   sobre descuentos por volumen/flotillas, correcto para otro contexto pero irrelevante aquí).

**Respuesta a la pregunta del handoff:** ni "sigue sin desplegarse" ni "cae fuera del bloque" —
es un fix quirúrgico sobre un bloque que YA existe: (a) sumarle la frase de recargo por fraccionar
y la prohibición explícita de "tipo de negocio" en `AI Agent`, y (b) replicar el mismo guardrail
en `RAG IA Agent`, que hoy no lo tiene en absoluto.

## Adenda 9 — confirmado: gap real, Adenda 7 no lo cubre

Adenda 7 está confirmada live en PROD, pero su alcance es exactamente tan estrecho como decía la
nota del 14-jul: el propio texto del prompt dice *"Esta excepción aplica SOLO a este caso (CASO
A1); en cualquier otro punto de entrada a la conversación... preséntate normalmente"*. CASO A1 es
específicamente clic en el botón "Continuar cotización" de la plantilla de Meta o una confirmación
explícita tipo "sí"/"ok".

El camino de Adenda 9 (`canal=LANDING`, `quote_document_sent=true`, primer mensaje del cliente es
un comentario, no una confirmación) cae en la rama "para CUALQUIER OTRO mensaje" de CASO A, que sí
vuelve a presentar a Uriel — de ahí el duplicado. No hay superposición con Adenda 7, es un gap
adicional y real. Amplía la excepción de "no te vuelvas a presentar" a esta rama también.

## Plan de fix — orden recomendado

1. **M49 + Adenda 9** (sin bloqueantes) → handoff a Agente n8n, STG primero. Independientes entre
   sí, se pueden ir en el mismo handoff o en dos separados, como prefieras.
2. **M47 + M48** (bloqueante compartido de Django) → primero pedirle a Juan que exponga
   `fecha_inicio` en `generate_xml_payload` y en el endpoint/tool de emisión. En paralelo, se
   puede armar y probar el copy en STG (conversación) dejando explícito el guardrail de no
   promover a PROD hasta que el backend lo soporte.

## Pendiente de infraestructura — nuevo ítem

Agrego a `CLAUDE.md`: *"Exponer `fecha_inicio` como parámetro en `generate_xml_payload`
(`HYL-WAI/qualitas/services.py`) y en la tool de emisión que llama n8n — bloquea M47/M48
(activación diferida en renovación). Pedir a Juan."*

## Decisiones que necesito de ti (Alberto)

1. ¿Le pido esto a Juan ya, o prefieres agruparlo con otro pendiente que ya tenga (rotación de
   `N8N_TOKEN`, plantilla de Meta) para no mandarle mensajes sueltos?
2. ¿Armo ya el handoff a Agente n8n para M49 + Adenda 9 (sin bloqueantes), o prefieres los 4 juntos
   una vez que Juan responda sobre `fecha_inicio`?
