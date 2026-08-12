# Informe — Dashboard · #156: **E1 y E2 cerrados**, E4 parcial

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Handoff:** `Dashboard:handoffs/2026-08-11-hyl-wai-156-discounts-conversation-control-dashboard.md`
**Rama:** `feature/issue-156-conversation-control-dashboard` (base `origin/stg`), empujada.
**Entrega detallada:** `Dashboard:docs/156/entrega-dashboard.md`

Contratos verificados antes de tocar código: los tres fingerprints del §2 coinciden exactamente.

---

## Lo que se publica

```text
DASHBOARD_156_E1_E2
rama=feature/issue-156-conversation-control-dashboard
commits=a273083 (E1) · f082f12 (E2) · 4396e54 (costura + invalid_request) · c6cd0fc (entrega)
suite_offline=118/118        (partia de 89; 29 nuevos)
postgres_efimero=31/31 gates OK
build=OK
merge=NO · deploy=NO · migraciones_vivas=NO · grants_vivos=NO · llamadas_reales=NO
stg y main intactos
```

## E1 — hecho, en la forma que dictaminaste

Resolver live-only en `lib/s1/conversationControl.js`: `public.conversation_control_v1` por igualdad
exacta de `session_id`, las 26 columnas explícitas, `LIMIT 2` como `fetchmany(2)`, y los tres códigos.
Sin fallback por teléfono, archive, `LIMIT 1` ni orden. La ausencia de la vista cae en
`dependency_unavailable`, así que el módulo es seguro antes del rollout.

**Aplicadas tus cuatro respuestas:**

- **Cableado (A + costura única):** `lib/s1/controlResolver.js`. Un solo punto de indirección, **no** un
  modo de runtime — no lee `process.env` y hay un test que lo afirma leyendo su propio fuente, para que
  convertirlo en configuración se ponga rojo. Los dos call-sites ya pasan por ella y hoy delega **byte a
  byte** en el legacy, con tests que comparan ambas salidas para acreditar cero cambio de comportamiento.
  Sustituir será cambiar una línea.
- **Call-sites listados** en la entrega §3 con fichero:línea y su respuesta actual. Y una corrección mía:
  `inbox.js` y `db-leads.js` **no** son call-sites —solo leen columnas de identidad y las anotan—, así que
  la sustitución afecta a dos sitios, no a cuatro. Lo que yo mismo te dije en la duda era incorrecto.
- **HTTP:** tabla aplicada solo a superficie nueva. Divergencia declarada en la entrega §4:
  `conversation_not_found` devuelve **400** en `retomarBuilder.js:14` y `conversation.js:14`, alineado
  serían 404. **No lo he tocado.**
- **`invalid_request`:** el selector ausente ya no fabrica `conversation_not_found`; se rechaza sin
  consultar, con 400, y hay un test que vigila que no contamine la lista cerrada de tres.

## E2 — hecho, y acreditado en PostgreSQL efímero de verdad

`migrations/2026-08-11-claims-epoch-anti-aba.sql`, **escrita y no aplicada**. Aditiva e idempotente,
porque la migración de fencing del 28 jul se aplicó a mano y nunca se versionó: esta salda esa deuda y
deja el mismo estado final se parta de donde se parta.

`CHECK(epoch>0)`, `UNIQUE(session_id,epoch)`, estados cerrados, `active` exige `quotation_id`, único
`active` por sesión, readiness físico (bigint / 255 / 80), y la columna de lease **sin `DEFAULT`** — no se
crean leases no nulas.

**La inmutabilidad va en trigger, no en la aplicación:** prohíbe DELETE, cambiar `session_id`/`control_id`/
`epoch`, retargetear identidad ya fijada y resucitar un terminal a `active`. Un camino de código puede
olvidar la regla; la base no.

`scripts/156/verificar-migracion-claims.sh` levanta un cluster propio (socket unix, sin TCP), aplica,
ejerce **31 gates** y lo destruye. Incluye el gate estrella del §6: **dos `take` concurrentes reales**
—dos procesos `psql`, mismo advisory lock— con **exactamente un ganador** y sin fila del perdedor.

## Lo que NO está, dicho sin maquillar

- **E3 (cable) y E5 (read models): no empezados.** Por tiempo, no por bloqueo: E3 es construible offline
  con stubs y E5 solo necesita los overlays del §9, ya congelados.
- **E4 parcial:** `canHumanSend` y `isAutomationEligible` hechas y probadas, cada estado con su
  `reason_code`. **La UI no se ha tocado** — sigue pintando `json.error`. La pieza que faltaba para poder
  arreglar esa deuda ya existe.
- **Gates del §6 sin cubrir:** `claim ↔ reserva` y `release A ↔ take B` dependen de E3. «Vista malformada»
  solo parcialmente: `schema_version` no soportado y `session_id` que no es el pedido, pero no una vista
  real corrupta, porque la vista no existe.
- **Brecha de roles declarada** (entrega §5): mono-rol, ownership no impuesto técnicamente, GRANTs
  escritos y comentados sin ejecutar.

## Nota de proceso

Porté los dos monitores desde el Agente n8n (`scripts/monitor-handoffs.sh`, `scripts/monitor-dudas.sh`);
este repo no tenía ninguno. Se acreditaron solos durante el trabajo: el de dudas cazó tu respuesta y la
etiquetó como mía, y el de handoffs avisó de tu corrección `c46c9cf` retirando E0.

Alberto decide qué se comenta en #156; yo no publico en el tracker.

---

## Adenda (12 ago) — costura asíncrona: **hecho**, y sin hallazgo de reordenación

Aplicada tu adenda sobre `4396e54`. Commit **`2d59499`**.

**Tenías razón y el cabo suelto era mío:** anoté que la implementación live-only tendría firma asíncrona
y acto seguido afirmé que el cambio «arrastra los adaptadores de abajo, no los call-sites». Los
adaptadores sí, pero no se paraba ahí — `buildRetomarWire` era síncrona y su llamador es
`pages/api/n8n-proactive-message.js`. Escribí la consecuencia sin sacarla.

La costura nace ya con la **firma definitiva**:

```
controlResolver (async) → buildRetomarWire (async) → pages/api/n8n-proactive-message.js (await)
controlResolver (async) → pages/api/conversation.js (await)
```

**No hay hallazgo de reordenación que reportar**, que era lo que pedías saber: los dos llamadores
finales ya eran `async`, así que el `await` cabía en los dos sin tocar el orden de nada. Cero cambio de
comportamiento — una función `async` que devuelve un valor ya resuelto se comporta igual, y los tests
de delegación byte a byte contra el legacy siguen en verde.

**Donde sí apareció trabajo fue en los tests:** 8 llamadas en 4 ficheros. Dos tests cuyo nombre es un
template literal se me escaparon en la primera pasada y pusieron la suite en rojo con `SyntaxError`;
corregidos, y lo digo en vez de omitirlo porque el commit intermedio existió.

Añadido un test que **blinda la firma**: afirma que las dos funciones de la costura y `buildRetomarWire`
devuelven Promise. Mismo espíritu que `IMPLEMENTACION_VIGENTE` — si alguien las vuelve síncronas «porque
no hace falta», se pone rojo aquí y no dentro de la ventana. Verificado además que no queda ninguna
llamada sin `await` que devolviera una Promise y pasara aserciones por accidente.

**Suite 119/119, build OK.** Sigue sin haber merge, deploy ni grants: `stg` y `main` intactos.

---

## Adenda 2 (12 ago) — **E3, E5 y el stub corrupto: hechos**. Los cinco entregables cerrados

```text
DASHBOARD_156_COMPLETO
commits=9efb74a (E3) · d4cd007 (stub corrupto) · a1bd1f5 (E5)
suite_offline=162/162          (partia de 89; 73 nuevos)
postgres_efimero=47/47 gates   (migracion + release A<->take B + politica de producto)
stub_corrupto=19/19 gates
build=OK · merge=NO · deploy=NO · grants=NO
```

### E3 — cable

`command_id` **derivado** de `operation + session_id + control_id + epoch`, no aleatorio: el reintento
exacto lo reproduce solo, sin que el cliente tenga que conservarlo. El `request_hash` va aparte y cubre
el payload entero, y son los dos juntos los que separan replay exacto (mismo id + mismo hash → eco
persistido, sin repetir el CAS) de reutilización del id (mismo id + hash distinto → rechazo). **Si el id
fuera hash del payload completo, el segundo caso sería irrepresentable** y tu regla no tendría a qué
aplicarse; por eso son dos valores.

Idempotencia de take/release en módulo puro. El owner se comprueba **también en el replay**, para que no
se puedan sondear tokens ajenos.

**`release A ↔ take B` acreditado contra base real**: A toma, A libera, B toma, B recibe epoch nuevo, y
el CAS tardío con el epoch viejo de A afecta a **cero filas** sin tocar la toma de B. El ataque ABA
demostrado, no argumentado.

### Stub corrupto — construido del contrato

Relación PostgreSQL real con las 26 columnas **transcritas del §Columnas v1**, nunca del SQL de n8n, y el
resolver real conectado por `pg`. 19 gates, incluidas **columna faltante** y **relación desaparecida**.

Lo que acredita es la distinción que importa: ante una fila corrupta el resolver **no se hace el listo**
—entrega la fila y deja que la autorización la rechace, porque validar enums sería duplicar la autoridad
de la vista— y ante una relación rota devuelve `dependency_unavailable` en vez de reventar. El trío
`applied_*` incompleto se bloquea **con el reason de la vista** (`applied_token_partial`), no con uno
inventado.

**Se vuelve a correr contra la vista real cuando exista.** El stub acredita mi lado, la vista real la
integración; ninguno sustituye al otro.

### E5 — y el desfase con su cifra

Superficie nueva, sin tocar `lib/metrics.js` ni `FunnelV2.js`. Medido contra `F6-dashboard-chain`, que
se carga con `git show` del repo de contratos en vez de replicarse: **3 leads, 1 adquisición, factor 3
exacto** — el tope de descuentos por cadena.

Puntero del desfase, ya que Alberto relevó la cuantificación completa: **`lib/metrics.js:84` y `:92`**
(`total = leads.length`) y **`FunnelV2.js:144`** (`fmt(leads.length)`) cuentan un lead = una adquisición.

`continued` se **lee** del overlay, no se infiere de `parent_quote_id` — hay test de que el leaf tiene
padre y aun así no se bloquea. El timeline pone lo heredado primero **sin intercalar por fecha**: sus
marcas son anteriores al cutover y mezclarlas por hora produciría un hilo que parece uno cuando son dos.

### Lo que sigue sin estar

- **`claim ↔ reserva`**: las reservas de dispatch son ownership de n8n; necesita su lado.
- **Cableado a los endpoints** de E1 y E3: las piezas están probadas pero `pages/api/claim.js` y los
  resolvedores siguen con su lógica actual. Cablear `take` cambia su wire (hoy el reintento del propio
  agente da 409; el contrato pide 201 con los mismos tokens), y eso es superficie acreditada.
- **Lista de columnas de `dashboard_lead_continuation_v1` incompleta**: el §9 describe el overlay por
  concepto pero no publica todos los nombres. Consumo las seis que el fixture acredita, con un test que
  exige que ambas listas coincidan. **No es el SELECT definitivo** y lo digo antes de que lo parezca.
