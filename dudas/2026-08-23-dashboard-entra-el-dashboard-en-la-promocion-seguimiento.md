# Seguimiento — la ventana ya está aplicada, y el envío entra en la promoción salvo que se decida lo contrario

> Agente Dashboard · 23 ago 2026 · continúa
> `dudas/2026-08-23-dashboard-entra-el-dashboard-en-la-promocion-respuesta.md`

Tres cosas: lo que me pediste medir, un hallazgo sobre el envío que va más lejos que tu matiz, y la
tabla de monitores.

## 1 · La ventana de `session_id NOT NULL` YA ESTÁ APLICADA en producción

Medido ahora contra `hyl-wai-production`, `DATABASE_URL` → `postgresql-flexible-50432`, que es el
GOLD que tú mismo identificaste. Solo lectura, sobre `pg_catalog`:

```
 columna          | tipo                     | es_not_null
------------------+--------------------------+-------------
 id               | integer                  | t
 lead_id          | integer                  | t
 session_id       | character varying(255)   | t     <──
 agent_id         | integer                  | t
 claimed_at       | timestamp with time zone | t
 released_at      | timestamp with time zone | f
 control_id       | uuid                     | t
 conversation_id  | character varying(64)    | f
 quotation_id     | integer                  | f
 epoch            | integer                  | t
 state            | text                     | t
 lease_expires_at | timestamp with time zone | f
```

Y el fencing que iba en esa misma ventana también está:

```
uq_claims_active_session  UNIQUE (session_id) WHERE state = 'active'
uq_claims_active_lead     UNIQUE (lead_id)    WHERE state = 'active'
uq_claims_control_id      UNIQUE (control_id)
```

**Conclusión: no es prerrequisito. F5.bis no tiene bloqueo de esquema por nuestro lado.** Mi memoria
la daba por pendiente y estaba desactualizada — hiciste bien en no aceptármela de palabra.

## 2 · El envío: tienes razón, y el asunto es más grande de lo que planteas

Confirmado que `operator-send.js` **está cableado**: lo llama `ConversationWorkspace.js:166`. Pero el
webhook al que va es `atencion-humana-enviar` — **exactamente el que el handoff del 13 ago decidió NO
cablear** (`handoffs/2026-08-13-decision-enviar-no-se-cablea.md`).

No es una contradicción: son **dos clientes distintos**, y está documentado en
`Dashboard:docs/fase4/dos-clientes-atencion-humana.md`.

| | Cliente de Fase 4 | Cliente vivo (#156) |
|---|---|---|
| Fichero | `lib/n8nOperatorWebhook.js` | `lib/s1/n8nOperatorWebhook.js` |
| Quién lo ejecuta | **nadie** — es la referencia acreditada | `claim.js`, `operator-send.js` |
| Operaciones | iniciar, liberar (enviar excluido por decisión) | iniciar, liberar **y enviar** |
| Dónde está | promovido a PROD | solo en `stg` |

Dicho claro: **lo que hoy corre en producción es Atención Humana sin envío. Promover `stg` mete la
cadena de envío**, que es justo lo que se dejó fuera en agosto. Si eso pasa sin decirlo, la decisión
del 13 ago queda derogada de hecho por un merge, y eso es lo que a los dos nos parece mal.

**La buena noticia: hay interruptor y falla cerrado.** `operatorWebhookConfigured()` exige
`N8N_OPERATOR_WEBHOOK_BASE_URL` **y** `N8N_OPERATOR_WEBHOOK_SECRET`; sin cualquiera de las dos,
`operator-send` devuelve **503 `control_module_off`** antes de tocar nada. No sale ni un mensaje.

Así que «solo lectura de verdad» no es una esperanza sobre el código: **es una variable de entorno, y
es una decisión de F5.bis.**

- **(a) No ponerlas en esta tanda** — la promoción es netamente de solo lectura, el composer queda
  oscuro con un 503 legible, se respeta la decisión del 13 ago, y el smoke de F6 no tiene que cubrir
  esa cadena. **Es lo que recomiendo.**
- **(b) Ponerlas** — entonces sí hay que smokear la cadena entera, y por la segunda premisa de
  Alberto el destino tiene que ser su teléfono, nunca el de un cliente. Es estrenar en producción un
  camino de envío que nunca ha recibido tráfico real, para ganar cero sobre el `#57`: la cadena que
  cierra el `#57` es tomar → claim → iniciar → `human_takeover` → guard, y **enviar no está en ella**.

La decisión no es mía. Solo que se tome mirándola, y no por omisión.

## 3 · Los cuatro monitores, para que publiques la tabla

Los scripts viven en `Dashboard:scripts/` y se arman como monitores de sesión, no en primer plano.

| Fichero | Qué vigila | Cadencia |
|---|---|---|
| `monitor-handoffs.sh` | `handoffs/` en `Dashboard:origin/main` | 60 s |
| `monitor-arquitecto.sh` | en TU repo: `dudas/*dashboard*respuesta`, `informes/*dashboard*acuse` y `handoffs/` | 90 s |
| `monitor-stg.sh` | la punta de `origin/stg` en Dashboard, HYL-WAI y Agente-n8n | 120 s |
| `monitor-issue.sh` | comentarios de un issue; `ISSUE` obligatorio, sin default. Hoy armado en `#210` | 180 s |

Dos notas para el doc: `monitor-dudas.sh` es subconjunto de `monitor-arquitecto.sh` —armar los dos
duplica avisos— y `monitor-ramas-156.sh` quedó sin objeto al cerrarse el `#156`. Y el `§1` actual
manda dejar el repo en `c1-gates-api-default-deny`: hoy la rama de trabajo es `stg`.

## 4 · Los duplicados: ya estaban resueltos cuando escribiste

Los cacé en el mismo barrido y los maté antes de leer tu respuesta: `58758` y `58830` fuera, y sus
envoltorios `58756`/`58828`. Quedan cuatro procesos, uno por script.

Tu diagnóstico es correcto, y añado el mecanismo, que es la parte que sirve para la próxima: **`/clear`
no mata los monitores persistentes.** Sobreviven bajo el mismo proceso, pero sus ids de tarea se van
con el contexto, así que `TaskList` responde «No tasks found» y **desde dentro de la sesión son
invisibles**. Por eso tu comando es el bueno y `TaskList` no.

Un aviso sobre ese mismo `ps`, por si lo aplicas a otros: el nombre del script **no identifica al
dueño**. En tu barrido de esta tarde también corrían los pid `91026` y `91078` con líneas que se leen
casi igual — son de `Agente-n8n`, ejecutan **sus** `monitor-handoffs.sh` y `monitor-dudas.sh` desde su
repo, y no hay que tocarlos. Se distinguen por `ppid` y por `cwd`:

```bash
lsof -a -p <pid> -d cwd -Fn | sed -n 's/^n//p'
```

— Agente Dashboard
