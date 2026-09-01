# Auditoría de la proyección de estados del lead tras el cutover del `#135` — STG

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas (orden de Alberto, 1-sep)
> Responde a: `handoffs/2026-09-01-auditoria-proyeccion-estados-lead.md`
> **Solo lectura cumplida: cero INSERT/UPDATE, cero inyecciones, PROD sin tocar.**
> Fuentes: Postgres STG · código en `aguayo-co/HYL-WAI@origin/stg` (tip = `18f4ece`, el deploy;
> citado siempre con `git show origin/stg:…`, nunca el working tree) · config vars de
> `hyl-wai-stg` vía API de Heroku (GET).

## Respuesta corta a las tres preguntas

- **(a)** **Cero contradicciones duras** en los cruces póliza/pago, en ambos sentidos. Lo que sí hay:
  **34 leads infra-declarados** — sesiones de WhatsApp con captura o en fases avanzadas cuyo lead
  sigue en `COTIZACION_GENERADA`/`LEAD_CREADO`. No violan las reglas de la proyección; son su
  consecuencia (ver c).
- **(b)** Las 4 pólizas `LANDING` **no son error de atribución**: `origen='Landing Web'` las cuatro y
  ninguna tiene conversación de WhatsApp con captura detrás. El `#220` no se ensancha por aquí.
- **(c)** **El cutover SÍ reproyectó los 123 leads viejos** (no habrá mezcla de vocabularios), **pero
  proyecta solo desde hechos durables de Django e ignora deliberadamente el estado conversacional
  legado** — así que los informes mezclarán otra cosa más sutil: mismo vocabulario, distinta
  profundidad de evidencia, indistinguible al leerlos.

---

## (a) Contradicciones estado ↔ hechos

Cruces ejecutados, los cuatro a cero:

| Cruce | Resultado |
|---|---|
| Póliza emitida (`qualitas_polizaemitida` por `cotizacion_id` o `poliza_id`) con lead por debajo de `POLIZA_EMITIDA` | **0** |
| Póliza `PAGADO`/`fecha_pago` con lead ≠ `PAGO_CONFIRMADO` | **0** |
| Lead en `POLIZA_EMITIDA`/`PAGO_CONFIRMADO` sin póliza detrás | **0** |
| Lead en `PAGO_CONFIRMADO` sin póliza `PAGADO` (los 4: 934, 947, 949, 963 — todas `PAGADO`, `provider_poll`) | **0** |

El estado no puede contradecir a la póliza por construcción: `estado` solo lo muta
`_write_estado_authorized` (`lead_funnel.py:434`), respaldado por el trigger **activo**
`qualitas_lead_estado_authorized_writer_trg` en la BD, y es monótono (`S2_STATE_RANK`).

**Lo que sí encontré — 34 leads infra-declarados** (sesión de WhatsApp avanzada, estado que no lo
refleja). Los de más recorrido:

| Lead | Estado | Sesión | Fase | Captura |
|---|---|---|---|---|
| 893 | `COTIZACION_GENERADA` | waq_2246 | **payment_pending** | sí |
| 937 | `COTIZACION_GENERADA` | waq_2290 | **payment_pending** | sí |
| 857 | `COTIZACION_GENERADA` | waq_2210 | **policy_issuance** | sí |
| 940 | `COTIZACION_GENERADA` | waq_2293 | **policy_issuance** | sí |
| 943 | `COTIZACION_GENERADA` | waq_2296 | **policy_issuance** | sí |
| 836 | `COTIZACION_GENERADA` | waq_2189 | summary_confirmation | sí |
| 929 | `COTIZACION_GENERADA` | waq_2282 | summary_confirmation | sí |

Resto (data_capture o greeting con captura): 628, 629, 634, 694, 834, 839, 844, 845, 854, 892,
927, 928, 939, 941, 942, 944, 945, 946, 948, 951, 952, 953, 955, 956, 958, 959, 960. La mayoría
son sesiones de prueba de estos días (teléfonos de Alberto y del segundo tester), pero la mecánica
que los deja infra-declarados es la de producción futura — ver (c).

Matiz de atribución: el lead **962** es `canal=LANDING` pero su hecho `interes_confirmado` llegó
por `n8n_persisted_signal` (WhatsApp). Un solo caso, pre-cutover, lo dejo anotado.

## (b) Las 4 pólizas emitidas con canal LANDING

| Lead | Póliza | Emisión | `origen` | Sesión WA | Fase | Captura |
|---|---|---|---|---|---|---|
| 506 | 7620099371 | 24-jul | Landing Web | `525500000000` (legacy) | greeting | no |
| 507 | 7620099471 | 24-jul | Landing Web | `525555550100` (legacy) | greeting | no |
| 509 | 7620099472 | 24-jul | Landing Web | **sin sesión** | — | — |
| 933 | 7620101825 | 29-ago | Landing Web | waq_2286 | greeting | no |

Por el criterio del handoff (¿sesión de WhatsApp con captura? → mal atribuido): **ninguna la
tiene**. Emisiones del flujo web (las de julio, con pinta de pruebas de Juan: teléfonos
`5255000…`/`5255555501…`). Atribución consistente. Las cuatro siguen `estatus_pago=PENDIENTE`.

## (c) ¿Reproyecta lo viejo o solo aplica a lo nuevo? — la respuesta tiene dos mitades

**Mitad 1 — sí reproyectó lo viejo, verificado por dato y por código:**

- `qualitas_leadfunnelcutovercontrol`: `mode=COMPLETED`, run `5e6e1520…`, 01:56:57→01:56:59 del
  1-sep, `expected_fingerprint == applied_fingerprint`.
- **123 eventos `cutover_convertido`** (`evidence_type=cutover_snapshot`), uno por lead, todos
  `transition_applied`, 118 `state_advanced`. Mapeo dominante: `COTIZACION_INICIADA →
  COTIZACION_GENERADA` (93). El vocabulario viejo (`COTIZACION_INICIADA`, `PAGO_APROBADO`,
  `DATOS_EMISION_INICIADOS`) **ya no existe** en `qualitas_lead`: `estado` actual ==
  `resulting_state` en **123/123**.
- Código: `build_cutover_snapshot` (`lead_funnel_cutover.py:509`) — «Derive the exact
  current-evidence projection **without trusting legacy text**».

**Mitad 2 — pero “reproyectar” significa menos de lo que parece.** `_projection_for_lead`
(`lead_funnel_cutover.py:237`) deriva el estado SOLO de: XML de cotización válido → póliza/asegurado
exactos → enlaces de pago → y el **ledger `qualitas_leadfunnelevent`**. **No lee `whatsapp_sessions`
ni `captured_data`** — y el ledger de hechos solo existe desde las 00:41 del 1-sep (8 hechos, todos
de los leads 962/963). Consecuencia medida: todo el progreso conversacional anterior al ledger es
invisible para la proyección → los 34 infra-declarados de (a), y 93 de 94 conversiones que en la
práctica quedaron en el renombrado plano.

**Lo que esto hace a los informes de negocio:** no habrá mezcla de vocabularios (eso el cutover lo
resolvió bien), pero sí **mezcla de profundidades**: un lead viejo en `COTIZACION_GENERADA` puede
tener al cliente con enlace de pago en la mano, mientras un lead nuevo en el mismo estado significa
exactamente lo que dice. Misma etiqueta, distinta verdad, y nada en la fila lo distingue.

**Hacia delante (verificado en código + config, sin testigo en datos):** las transiciones orgánicas
post-cutover quedan armadas — `_check_normal_mode` exige `mode=COMPLETED` **+
`LEAD_FUNNEL_S2_PROJECTION_ENABLED`** (tercera flag, además de las dos del handoff), y las 5
`LEAD_FUNNEL_*` de `hyl-wai-stg` están en `true` (leídas de la API de Heroku). Pre-cutover el mismo
gate explica los 8 hechos con `transition_applied=false`.

## Hallazgo lateral que le importa a cualquier auditoría futura

**`fecha_actualizacion` ya no registra los cambios de `estado`.** El escritor autorizado usa
`Lead.objects.filter(pk=…).update(estado=…)` — esquiva el `auto_now`. Medido: el cutover reescribió
123 estados y solo **2** filas tienen `fecha_actualizacion` en la ventana (962/963, tocadas por otra
vía). Quien audite «¿cambió algo tras las 01:53?» mirando `fecha_actualizacion` concluirá en falso
que no. La fuente de verdad temporal de los estados es `qualitas_leadfunnelevent.created_at`.

## Lo que NO pude comprobar (declarado)

1. **Que un evento orgánico post-cutover aplique transición de verdad**: cero tráfico desde las
   01:56:59 y esta orden prohíbe inyectar. Queda garantizado por código+flags, no por testigo —
   los 4 caminos de Alberto lo cubrirán.
2. **`occurred_at` vs realidad** de los 8 hechos pre-cutover: doy fe del registro, no del instante.
3. Nota menor: las 4 pólizas `PAGADO` tienen `fecha_pago` NULL (la fecha viene del poll, no del
   registro) — no afecta estados, lo dejo dicho.
4. Transparencia: existe mi sesión sintética `QA-SUITE-S1` (lead 954, de la suite conversacional,
   declarada en el informe anterior). Está en `greeting` sin captura: no entra en ningún cruce ni
   altera conteos (123 leads, ninguno sintético — el fixture no creó lead).

```
🧪 QA REPORT — 1 sep 2026 · auditoría proyección #135 (STG)
Triggered by: handoff 2026-09-01-auditoria-proyeccion-estados-lead.md

✅ (a) 0 contradicciones duras en 4 cruces póliza/pago (ambos sentidos)
✅ (b) 4 pólizas LANDING con atribución consistente (origen web, sin captura WA) — #220 no se ensancha
✅ (c) cutover COMPLETED, 123/123 reproyectados, fingerprints iguales, vocabulario unificado
⚠️ 34 leads infra-declarados (progreso conversacional pre-ledger invisible para la proyección)
⚠️ fecha_actualizacion ciega a los cambios de estado (update() esquiva auto_now) — auditar por leadfunnelevent
⚠️ transiciones post-cutover: armadas por código+5 flags, sin testigo en datos aún (0 tráfico post-01:56Z)
```

— Agente QA & Testing
