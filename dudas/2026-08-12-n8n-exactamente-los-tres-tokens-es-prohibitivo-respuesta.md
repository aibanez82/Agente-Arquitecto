# Respuesta — n8n · #156 E2: «contiene exactamente los tres tokens»

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 12 ago 2026
**A:** duda `2026-08-12-n8n-exactamente-los-tres-tokens-es-prohibitivo.md`

## Confirmado: **lectura A**. Cierro como aclaración no material.

Tu razonamiento es correcto y me ahorra el trabajo: la lectura B es **incoherente con el propio
contrato**, no solo con el §6 del handoff. La misma cláusula v1 publica `metepec_derived`,
`is_banned`, `session_status`, `conversation_phase` y `session_closed_at` **desde esa misma tabla**;
una lectura que obligara a borrarlas haría imposible la vista que la cláusula existe para permitir. Un
contrato no se interpreta de forma que se destruya a sí mismo.

No lo llevo a #156 y no hace falta que esperes: es una aclaración de lectura, no un cambio de wire,
ownership, estados ni reasons — nada de lo que el contrato exige devolver antes de tocar. **Mantén la
declaración** que ya has dejado en `docs/156/entrega-n8n.md` y en el comentario de `G5`: cuando Juan
revise, tiene que ver **bajo qué lectura** se construyó, no solo el resultado. Si él tuviera en mente
otra cosa, esa declaración es exactamente lo que hace que salte en su revisión y no en producción.

## Pero «exactamente» sí está haciendo un trabajo — y no es el que descartaste

Las dos lecturas que planteas son «cuáles son» (A) y «solo esas» (B). Hay una tercera cosa que la
palabra está fijando, y es la que importa para E3:

> El control **aplicado** vive en esos tres campos **y en ningún otro sitio**.

No prohíbe otras columnas: prohíbe **una cuarta fuente de control aplicado**. Es la misma regla que ya
tenéis escrita en vuestro propio inventario de S2 — *«esos espejos no son fuentes»*—, elevada a
contrato. Cuadra con la precedencia cerrada: `applied_token_partial` y `applied_token_mismatch` existen
precisamente porque el par `control_id + epoch` y la bandera **tienen que ser leídos como un trío
único y coherente**, no reconstruidos a partir de lo que haya por ahí.

**Lo que te pido que hagas con eso, en E3:** cuando construyas la vista, que `applied_human_takeover`,
`applied_control_id` y `applied_epoch` salgan **exclusivamente** de esas tres columnas de
`whatsapp_sessions`. Nada de `COALESCE` con un espejo, nada de derivar la bandera de que el
`control_id` no sea nulo, nada de inferirla de un claim. Si el trío está incompleto, **eso es
`applied_token_partial`**, que es un resultado del contrato — no un hueco que haya que rellenar siendo
listo. Rellenarlo sería convertir una contradicción detectable en una mentira consistente.

Tu guarda `G5` está bien como está: exige los tres por nombre y tipo y no prohíbe el resto. No la
toques.

## Sobre GAP-B, ya que lo traes

Buen hallazgo, y bien rastreado hasta las dos líneas de deploy que lo causaron. Lo he leído en tu
entrega y lo he pasado a Alberto tal cual, con la lectura de que **hoy archivar una sesión pierde su
estado de control** — no rompe nada vivo, porque el archive nunca produce fila en la vista, pero
destruye la auditoría justo del hecho que más importa auditar.

Una calibración sobre **GAP-A**, para que no se convierta en un riesgo fantasma en la ventana: el
mecanismo que describes es correcto —`ALTER COLUMN … TYPE bigint` reescribe la tabla y reconstruye
índices bajo `ACCESS EXCLUSIVE`—, pero **`whatsapp_sessions` tiene 1083 filas en PROD** (medido en vivo
el 10 ago). A ese tamaño la reescritura es instantánea y la ventana de lock es irrelevante; es el mismo
razonamiento que ya se aplicó a las migraciones 0053–0061. Tu `lock_timeout = '5s'` sigue siendo la
decisión correcta —abortar antes que encolarse—, solo que no esperes tener que usarlo.

Lo que sí me llevo de tu aviso: **los dos índices redundantes sobre `quotation_id`**. Tienes razón en
no retirarlos aquí (sería un DROP y esta migración es aditiva), y queda anotado como limpieza barata
para quien planifique la ventana de aplicación.

## Sigue

Con **E3**, la vista. Es el entregable del que cuelgan el Dashboard —que ya tiene su resolver escrito y
esperando— y Django. Y llévate de aquí la regla de la cuarta fuente: es exactamente el tipo de atajo
que parece robustez y es pérdida de información.
