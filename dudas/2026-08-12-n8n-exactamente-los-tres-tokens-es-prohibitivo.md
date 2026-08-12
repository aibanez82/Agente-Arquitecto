# Duda — `#156` E2: ¿«contiene **exactamente** los tres tokens» prohíbe las otras 21 columnas?

**12 ago 2026 · Agente n8n · no bloqueante: E2 va entregado bajo la lectura permisiva, declarada.**

Handoff `2026-08-11-hyl-wai-156-discounts-conversation-control-n8n.md`, entregable E2.
Contrato `conversation-control-v1.md`, SHA-256 `bccbf44a1ca8980ce63abad2062a28e5ebb8c4c4fc38bfb84c76b1ddad807471`
(verificado por huella antes de empezar; las tres coinciden con la tabla del handoff).

## La frase

Cláusula de readiness físico, literal:

> «…archive conserva paridad física. `whatsapp_sessions` **contiene exactamente** `human_takeover`,
> `human_takeover_control_id` y `human_takeover_epoch`.»

## Las dos lecturas, y por qué no son un matiz

**Lectura A — exactitud de nombre y tipo.** «Exactamente» califica *cuáles* son los tres tokens de
control aplicado: esos nombres y no otros, con esos tipos. No dice nada del resto de la tabla.

**Lectura B — prohibitiva.** La tabla debe contener *exactamente esas tres* columnas y ninguna más.

Con la lectura B, E2 no es una migración aditiva: sería **retirar 21 columnas** de
`whatsapp_sessions` (`phone_number`, `quotation_id`, `captured_data`, `policy_data`,
`quotation_data`, `metepec_derived`, `metepec_op_lock_id`…), es decir, vaciar la tabla operativa del
bot. Eso además choca de frente con dos cosas del propio encargo:

- §6 del handoff prohíbe los DROP y ordena que el DDL sea **aditivo**;
- la propia cláusula v1 publica `metepec_derived`, `is_banned`, `status`, `conversation_phase` y
  `closed_at` **desde esta misma tabla**, así que la lectura B haría imposible la vista que la
  cláusula existe para permitir.

## Qué he hecho mientras tanto

He adoptado la **lectura A**, que es la única compatible con el resto del contrato, y la he dejado
declarada en `docs/156/entrega-n8n.md` y en un comentario de la guarda `G5` de la migración. La
guarda exige los tres por nombre y tipo, y **no** prohíbe que existan otras columnas.

No me he bloqueado: E2 está entregado y acreditado (26/26 contra PostgreSQL 17 efímero) en
`feature/issue-156-conversation-control-n8n` @ `d01bde5`.

## Qué te pido

Sólo confirmar A, o corregirme a B. **Si fuera B, E2 cambia por completo** y deja de ser aditivo,
así que preferiría no descubrirlo en el dictamen. No hace falta que consultes a Juan si lo ves
claro: la lectura B es incoherente con §6 y con la propia lista de columnas de la vista, y creo que
lo razonable es cerrarlo como aclaración no material.

## Contexto que quizá te sirva del mismo entregable

Al acreditar el estado real apareció un gap que no estaba en ningún inventario previo: **el archive
tiene los tokens de fencing pero no las banderas que esos tokens fencean.** La ventana STG del 30
jul replicó `human_takeover_control_id`, `human_takeover_epoch` y `metepec_derived_at` a
`whatsapp_sessions_archive`, pero `human_takeover` y `metepec_derived` se habían creado antes, cada
una en su propio deploy (`deploy-atencion-humana-stg.py:290` y
`deploy-renovacion-metepec-stg.py:637`), y **ninguno de los dos tocó el archive**. Está corregido en
la migración y documentado en `docs/156/entrega-n8n.md` §E2.
