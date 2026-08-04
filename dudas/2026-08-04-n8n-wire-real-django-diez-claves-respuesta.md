# Respuesta del Arquitecto — wire real de Django: 10 claves confirmadas; el chequeo de identidad SE QUEDA

**1. Esquema cerrado sobre 10 claves: CONFIRMADO.** Lo verifiqué yo mismo contra la fuente
(`aguayo-co/HYL-WAI@stg:qualitas/whatsapp_checkpoint_followups.py`, `build_n8n_payload` L656-668):
las 10 claves exactas que citas, con `conversation_id` derivado de la propia fila (fallback a
`session_id` cuando es `waq_*`). El «8 conocidos» de mi handoff era **un error mío** — lo derivé
del ejemplo de tu primera duda (que traía 8 claves) en vez de leer el productor; tú hiciste lo
correcto yendo a la fuente. La corrección del registro en `#132` la hago yo: la frase errónea
("sin `conversation_id` ni `identity_mode`") vive en mi pregunta §12, no en la resolución de la
autoridad (que delimitó por productor, sin enumerar claves) — la rectifico como nota factual al
publicar tu entrega r2.

**2. El chequeo de identidad DENTRO del carril de Django se queda.** No es un añadido "más allá
de la letra": el propio dictamen lo pide — P1-N1b cierra con «el discriminador debe acreditar el
carril previo **sin permitir campos Dashboard contradictorios**». Un `conversation_id` no vacío
que viola la tabla de identidad es exactamente eso. Además: (a) Django construye ese valor desde
la propia fila, así que un wire contradictorio implica una fila corrupta — y NO enviar un
WhatsApp sobre una fila corrupta es el resultado correcto (espíritu §4.4, fail-closed); (b) la
conformidad Django v1.1 (PASS, `c.5185067604`) hace implausible el falso rechazo de tráfico
legítimo. Tu riesgo declarado (fila STG con `conversation_id` incoherente → follow-up rechazado)
queda como **límite declarado en la entrega**, no como veto: si la autoridad prefiere
warn-only, es un cambio de una línea que haremos bajo su dictamen, no preventivamente.

**Nada que cambiar en `fb98f24`.** Deja la rama quieta; verifico tu informe y publico. Buen
trabajo yendo al productor real antes de cerrar el esquema — esa es la diferencia entre cumplir
el handoff y cumplir el contrato.
