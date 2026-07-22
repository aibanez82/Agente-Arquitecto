# Handoff — filtro de horario 9am-8pm CDMX en `checkpoint_followups`

> De: Arquitecto. Objetivo: cerrar el único bloqueante real que queda para tener
> `checkpoint_followups` corriendo en PROD de forma sostenida (sin depender de que alguien lo
> revierta a mano antes de que oscurezca, como se hizo el 20 jul). Contexto completo:
> `docs/iniciativas/seguimiento-leads-estancados.md`.

## Estado verificado ahora mismo (21 jul, mañana)

- PROD en estado seguro, confirmado en vivo vía Heroku API: `WHATSAPP_CHECKPOINT_FOLLOWUPS_ENABLED=true`,
  `WHATSAPP_CHECKPOINT_FOLLOWUPS_DRY_RUN_DEFAULT=true`. La reversión del 20 jul (handoff
  `2026-07-20-handoff-juan-activar-envio-real-checkpoint-followups-sin-filtro-horario.md`) sí se
  hizo a tiempo.
- Revisé `origin/main` de `HYL-WAI`: no hay ningún filtro de horario en
  `qualitas/whatsapp_checkpoint_followups.py` ni en `whatsapp_followup_policy.py`. Los 2 PRs que
  mergeaste ayer/hoy (`a909c83` validate follow-up policies, y el de reordenar el admin Wagtail)
  no lo tocan — sigue siendo el único gap de diseño pendiente de esta iniciativa.

## El cambio (mismo patrón que el guard de `status` que ya tienes en producción)

Una condición más en `evaluate_checkpoint_followup_candidate()` — sin campo nuevo en BD, sin
lógica nueva de reintentos: si un candidato cae fuera de la ventana, sale `ineligible` y el propio
Scheduler lo vuelve a evaluar sola en la siguiente corrida ya dentro del horario.

**Imports** (`qualitas/whatsapp_checkpoint_followups.py`, junto a los que ya existen):

```python
import zoneinfo
```

**Constantes** (junto a `CLOSED_N8N_SESSION_STATUSES` y el resto de constantes del módulo):

```python
CHECKPOINT_FOLLOWUPS_BUSINESS_HOURS_TZ = zoneinfo.ZoneInfo("America/Mexico_City")
CHECKPOINT_FOLLOWUPS_BUSINESS_HOURS_START = 9   # 9am CDMX, inclusive
CHECKPOINT_FOLLOWUPS_BUSINESS_HOURS_END = 20    # 8pm CDMX, exclusivo
```

**En `evaluate_checkpoint_followup_candidate`**, justo después de definir el closure `ineligible`
y antes del primer `if candidate.skip_reason:` (así es lo primero que se evalúa, sin gastar
queries en un candidato que de todos modos va a salir descartado por horario):

```python
    local_hour = now.astimezone(CHECKPOINT_FOLLOWUPS_BUSINESS_HOURS_TZ).hour
    if not (
        CHECKPOINT_FOLLOWUPS_BUSINESS_HOURS_START
        <= local_hour
        < CHECKPOINT_FOLLOWUPS_BUSINESS_HOURS_END
    ):
        return ineligible("outside_business_hours", local_hour=local_hour)
```

`now` ya es tz-aware (`timezone.now()` o el parámetro inyectado en tests) — `astimezone()` con
`zoneinfo` es el mismo patrón que ya usas en `qualitas/management/commands/exportar_leads.py`, no
introduce dependencia nueva.

**Test sugerido** (mismo estilo que `test_checkpoint_followup_skips_closed_n8n_session` en
`tests/services/test_whatsapp_checkpoint_followups.py`, que ya inyecta `now=` a
`dry_run_checkpoint_followups`): construir un `now` tz-aware fuera de la ventana (p. ej. 23:00
CDMX) con `datetime(..., tzinfo=zoneinfo.ZoneInfo("America/Mexico_City"))`, correr el resto del
fixture igual que ese test, y afirmar `evaluation.reason == "outside_business_hours"`. Te dejo la
mecánica del fixture a ti — conoces mejor los helpers (`_insert_session`,
`_insert_waiting_history`) que yo.

## Despliegue — en este orden

1. Aplicar y correr tests en `stg` primero.
2. Verificar en vivo en STG: forzar (pin data o `now=` de prueba) un candidato fuera de ventana y
   confirmar que sale `ineligible`/`outside_business_hours`, y uno dentro de ventana que sí sea
   elegible.
3. Promover a `main` / `hyl-wai-production`.
4. Avísame en cuanto esté en PROD — coordino con Alberto una prueba de envío real controlada (un
   solo candidato, `DRY_RUN_DEFAULT=false` brevemente, dentro de la ventana 9am-8pm) antes de
   decidir dejar el envío real sostenido.

## Nota aparte, no bloqueante

Durante el ensayo de envío real del 20 jul se encontró el issue `qualitas-issues#43` (a veces
`requiere_factura` no persiste tras la respuesta del usuario → lead huérfano de
`checkpoint_followups`). Sigue abierto, criticidad media, no bloquea este filtro de horario — es
un hallazgo aparte.
