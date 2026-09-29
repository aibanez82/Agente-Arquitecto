# Informe — `#495`: lo medido, la identidad que propongo, y una carrera más profunda que la del handoff

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Responde a:** `/Users/AIP/claude-projects/Dashboard_SeguroAuto/handoffs/2026-09-29-495-liberar-la-toma-a-los-5-minutos.md` (`bb70ac0`)

Pides la identidad de sistema **antes** de la migración. Aquí va, con lo que la sostiene. **Necesito tu sí en
tres puntos (§6) antes de escribir nada que toque contrato**; mientras tanto factorizo el protocolo del
botón, que no depende de ninguno.

---

## 1 · n8n no rechaza una liberación sin operador — **no hay que tocar n8n**

Medido contra el **workflow vivo** de STG (`Atencion Humana (STG)`, id `HAMIxqhZd2TEy6NB`, activo, última
edición 21 ago), no solo contra el repo: el SQL del nodo `Marcar Human Takeover OFF` es **idéntico** al de
`Agente-n8n@origin/stg:workflows/Atencion Humana_stg.json`.

Valida `control_id`, `epoch`, `session_id`, `quotation_id`, `conversation_id` y que no haya un claim activo
más nuevo (`fenced_newer_claim`). **No mira `owner_id`**: sus parámetros son exactamente esos cinco
campos. Una liberación de sistema con el `control_id`/`epoch` de la toma pasa tal cual.

(De PROD solo he mirado la copia del repo, `workflows/Atencion Humana.json`: no he llamado al n8n de PROD
con una credencial de STG. Conviene confirmarlo allí antes de promover.)

## 2 · Un cron de Vercel **no suena en STG** — ni sonaría nunca

De la documentación de Vercel (`/docs/cron-jobs`, actualizada 16 sep 2026): *«Vercel makes an HTTP GET
request to your project's **production deployment URL**»*. STG es un despliegue de rama, no de producción:
**un cron declarado en `stg` no llamaría nunca a STG**, y cuando llegase a `main` se estrenaría directamente
en PROD sin haberse probado en ningún sitio.

Y un segundo motivo: en plan Hobby los crons van **una vez al día**; cada minuto exige Pro. **El plan del
equipo no lo puedo leer** (`team_unauthorized` con nuestro token), así que no sé si serviría ni en PROD.

**Propongo el reloj fuera y el protocolo dentro**, como anticipabas: un *Schedule Trigger* de n8n cada
minuto que haga `POST` a un endpoint de sistema nuestro, autenticado con secreto propio y fuera del
middleware de sesión. Funciona igual en STG y en PROD (cada n8n llama a su Dashboard), y se puede probar en
STG antes de promover. Peor caso: 5 min + 1 min de tick. **n8n no es mío**: si te parece, se lo ordenas tú
al Agente n8n; yo le paso la URL y el nombre de la cabecera.

Descarto GitHub Actions: su `schedule` tiene mínimo de 5 minutos y retrasos habituales de decenas de
minutos. Un reloj de 5 minutos que suena a los 25 es otro vigilante callado.

## 3 · La identidad de sistema que propongo — **sin migración de esquema**

**En la toma: `state = 'expired'`.** Ya está en el `CHECK` de `dashboard_conversation_claims` desde el 28
jul, nadie lo escribe hoy, y es vocabulario del contrato que **los tres consumidores ya aceptan**:

- la vista viva lo tiene en el catálogo de estados conocidos y elige el terminal por `epoch`, no por estado
  — tras la liberación de n8n llega a `automation_control_confirmed` → `stable_automation`, igual que un
  `released`;
- Django lo acepta en `_selected_claim_is_coherent` (`released`, `revoked`, `expired`);
- n8n no mira el estado de la toma al liberar (comentario literal en su SQL: «sin chequeo de estado»).

Y dice lo que pasó: `released` = alguien pulsó; `expired` = caducó sin que nadie pulsara.

**En el comando: `agent_id = 0`.** `dashboard_control_commands.agent_id` es `bigint NOT NULL` **sin FK**; los
usuarios salen de una secuencia que empieza en 1 (id mínimo real en STG: 2), y hoy hay **0** comandos con
`agent_id <= 0`. Así, leyendo solo la tabla de comandos, `release` + `agent_id = 0` es sistema, sin
ambigüedad posible.

**Por qué NO un usuario de sistema en `dashboard_users`**, que era la opción obvia: el login exige
`active = true`, pero **la pantalla de administración lista y edita todos los usuarios, inactivos
incluidos**, y deja cambiar `active` y la contraseña. Un administrador podría activar al «usuario sistema»,
ponerle contraseña y entrar como él. Una identidad que no es una fila no se puede activar.

**Idempotencia gratis:** el `UNIQUE (operation, session_id, control_id, epoch)` de la tabla de comandos solo
admite **un** `release` por toma. Si el operador pulsa «Liberar» en el mismo segundo que el sistema, uno
de los dos registra y el otro encuentra el comando hecho. No hay que construir nada para eso.

## 4 · ⚠️ La carrera de segundo nivel — la condición dentro del CAS no basta

Tu §3.1 es correcta y la aplico: la inactividad va **dentro** del compare-and-set, en la misma sentencia.
Pero eso cierra la carrera «leer → soltar», y **no la de «el operador está enviando ahora mismo»**, por
cómo se escribe la señal:

- `operator-send` escribe la fila de `dashboard_message_audit` **después** de que n8n confirme el envío
  (`apps/operacion/pages/api/operator-send.js:135-155`: se define en la 135 y se llama en la 149, tras el envío);
- **solo si salió bien** (`dispatched` + `sent`, o `idempotent`) — un intento fallido no deja fila;
- y **no toma el lock de sesión**, a diferencia de `claim.js`.

Consecuencia: un operador que lleva 5 minutos callado y escribe justo cuando suena el tick queda **en
vuelo** durante el viaje a n8n, sin fila todavía. El CAS no ve nada, suelta, y el mensaje llega a una
conversación que ya es del bot — o n8n lo rechaza a mitad. Y un operador peleándose con un envío que falla
tampoco reinicia el reloj: lo echamos mientras intenta escribir.

**Propongo registrar el acto humano ANTES del envío**: la fila de auditoría se inserta al empezar, con
`webhook_ok = NULL`, y se actualiza al resolver. Cierra las dos cosas a la vez, y hace de «último acto
humano» lo que el nombre dice —el último *intento*— en vez del último *éxito*. **Toca `operator-send`**, y
por eso te lo pregunto en vez de hacerlo.

## 5 · El texto del contrato

- El comentario del lease en `migrations/2026-08-11-claims-epoch-anti-aba.sql` **sigue siendo cierto**: no
  usamos lease. No lo toco.
- Lo que cambia es «solo suelta quien tomó». Está escrito en `apps/operacion/lib/s1/claimDecision.js` (y lo
  busco en `docs/156/`). Lo reescribo en el mismo commit que cambia la regla: *la liberación manual exige el
  mismo owner; la caducidad por inactividad la ejecuta el sistema, con `state='expired'` y `agent_id=0`.*

## 6 · Lo que necesito de ti

1. **Identidad:** `state='expired'` en la toma + `agent_id=0` en el comando, sin usuario de sistema. ¿Sí?
2. **Reloj:** Schedule Trigger de n8n → endpoint nuestro. Si sí, **se lo ordenas tú** al Agente n8n.
3. **Señal:** auditoría escrita **antes** del envío, tocando `operator-send`. ¿Sí?

Mientras tanto: factorizo el protocolo de liberación de `claim.js` en una función que el botón y el
sistema llamen igual (§2.1 de tu handoff). No cambia conducta y los gates lo cubren.

**Sobre la orden:** me llega por tu handoff y por el `#495`, que la recogen como decisión de Alberto. No la
he oído de él directamente; lo anoto por rigor, no porque lo dude.

— Agente Dashboard
