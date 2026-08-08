"""
S1 · Materialización del par sintético A/B — `DJANGO_S1_FIXTURE_MATERIALIZATION_CHECKPOINT`.

Se ejecuta contra el código Django YA DESPLEGADO, sin desplegar nada:

    heroku run --app hyl-wai-stg -- python manage.py shell < scripts/s1-fixtures/materializar-par-ab.py

Crea EXACTAMENTE: 2 cotizaciones · 2 leads · 2 detalles de cotización · 2 filas
`whatsapp_sessions` abiertas, todas con el MISMO recipient sintético y con identidades A/B
distintas. Nada más.

Propiedades que el script se impone a sí mismo:

- **cero DDL, cero DELETE, cero UPDATE de filas preexistentes** — solo INSERT;
- **todo dentro de una única transacción**: cualquier diferencia aborta el conjunto ANTES del commit;
- **cero llamadas externas y cero envíos**: no instancia servicios de Quálitas ni de Meta;
- **fail-closed**: si un guard no puede evaluarse, se deniega; nunca se asume que se cumple.

MODOS
  Sin `S1_FIXTURE_APPLY=1` corre en **dry-run**: evalúa guards, construye los valores y hace
  rollback deliberado. Es el control negativo. Con `S1_FIXTURE_APPLY=1` hace commit.
"""

import json
import os
import re
import sys
import uuid
from datetime import timedelta

from django.conf import settings
from django.db import connection, transaction
from django.utils import timezone

from qualitas.models import Cotizacion, CotizacionRespuestaXml, Lead

SALIDA = {"status": "BLOCKED", "motivo": None}
PATRON_RUN_ID = re.compile(r"^s1-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{8}$")
# Un móvil mexicano en formato E.164 sin '+': 52 + 10 dígitos.
PATRON_RECIPIENT = re.compile(r"^52[0-9]{10}$")


class GuardFallido(Exception):
    """Cualquier condición que impida continuar. Nunca se captura para seguir adelante."""


def _exigir(condicion, mensaje):
    if not condicion:
        raise GuardFallido(mensaje)


def _entorno(nombre):
    valor = (os.environ.get(nombre) or "").strip()
    _exigir(valor, f"falta la variable de entorno {nombre}")
    return valor


def guards():
    """Todo lo que se comprueba ANTES de abrir la transacción. Orden deliberado: lo más barato y
    lo más peligroso primero."""

    # 1) Ambiente. `AMBIENTE_PRUEBAS` está a 1 en STG y NO está definida en producción, donde el
    #    default del código es "0" -> False. Es un discriminador intrínseco, no una convención.
    _exigir(getattr(settings, "AMBIENTE_PRUEBAS", False) is True,
            "AMBIENTE_PRUEBAS no está activo: este script solo corre en el STG privado")

    # 2) Django tiene que seguir en `shadow`. Si alguien lo movió, paramos: el checkpoint entero
    #    se acordó sobre ese supuesto.
    from qualitas.whatsapp_conversations import get_whatsapp_conversation_id_mode
    modo = get_whatsapp_conversation_id_mode()
    _exigir(modo == "shadow", f"el modo de conversation-id es '{modo}' y tiene que ser 'shadow'")

    # 3) Run-id con el formato del contrato. No se genera aquí: lo fija el checkpoint.
    run_id = _entorno("S1_FIXTURE_RUN_ID")
    _exigir(PATRON_RUN_ID.match(run_id), "S1_FIXTURE_RUN_ID no cumple el formato contractual")

    # 4) Recipient. NO se inventa: un número inventado puede ser de una persona real, y esa es
    #    justo la razón de ser de `synthetic_attestation` en el contrato. Lo suministra el owner,
    #    que es quien puede atestiguar que es sintético y está en la allowlist del sender.
    recipient = _entorno("S1_FIXTURE_RECIPIENT")
    _exigir(PATRON_RECIPIENT.match(recipient),
            "S1_FIXTURE_RECIPIENT no tiene forma E.164 de móvil mexicano (52 + 10 dígitos)")

    # 5) Idempotencia dura: si el run-id ya dejó huella, no se repite ni se completa a medias.
    marca = f"{run_id}@s1.invalid"
    ya = Cotizacion.objects.filter(email__endswith=marca).count()
    _exigir(ya == 0, f"el run-id ya tiene {ya} cotización(es): no se reutiliza ni se completa")

    return run_id, recipient


def _xml_detalle_minimo():
    """Detalle de cotización mínimo.

    Se crea la FILA de `xml_cache` con los seis XML a NULL, deliberadamente. El endpoint de detalle
    recorre los escenarios y solo parsea los que tienen contenido, así que con NULL responde 200 con
    `opciones_cotizacion` vacío. Meter un XML falso obligaría al parser real a digerir algo
    inventado, y un fallo ahí rompería el endpoint para el par A/B: más superficie y ningún
    beneficio para Gate A, que no llama a Django.
    """
    return {}


def construir(run_id, recipient, sufijo):
    """Valores de UNA identidad (A o B). Todo inventado y prefijado por el run-id."""
    telefono = recipient[2:]          # el modelo guarda 10 dígitos; la sesión guarda 52+10
    return {
        "email": f"s1-{sufijo}-{run_id}@s1.invalid",
        "telefono": telefono,
        "codigo_postal": "01000",
        "marca": "SYNTHETIC",
        "nombre_marca": "SYNTHETIC",
        "modelo": "2020",
        "submarca": f"S1-{sufijo.upper()}",
        "version": f"S1 FIXTURE {sufijo.upper()} {run_id}",
        "paquete": "Amplia",
        "forma_pago": "C",
    }


def materializar(run_id, recipient):
    ahora = timezone.now()
    creado = {"cotizaciones": [], "leads": [], "detalles": [], "sesiones": []}

    for sufijo in ("a", "b"):
        cot = Cotizacion.objects.create(**construir(run_id, recipient, sufijo))
        creado["cotizaciones"].append(cot.id)

        det = CotizacionRespuestaXml.objects.create(cotizacion=cot, **_xml_detalle_minimo())
        creado["detalles"].append(det.pk)

        # `estado` y `canal_atencion` salen de los choices REALES del modelo. Django no valida
        # choices en `create()` --no hay CHECK en la BD--, así que un valor inventado entraría en
        # silencio y dejaría el fixture inconsistente. Verificado contra `ESTADOS_LEAD` y
        # `CANALES_ATENCION`; `asegurado` y `poliza` son nullable y se dejan vacíos a propósito.
        lead = Lead.objects.create(
            cotizacion=cot, estado="COTIZACION_INICIADA", canal_atencion="WHATSAPP",
        )
        creado["leads"].append(lead.id)

        # `whatsapp_sessions` no es un modelo de Django: la escribe n8n por SQL crudo. Se inserta
        # igual, con columnas explícitas y parámetros ligados -- nunca interpolando.
        conversation_id = f"s1-{sufijo}-{run_id}-{uuid.uuid4().hex[:8]}"
        with connection.cursor() as cur:
            cur.execute(
                """
                INSERT INTO whatsapp_sessions
                    (session_id, phone_number, quotation_id, lead_id, conversation_id,
                     conversation_phase, status, captured_data, policy_data, quotation_data,
                     last_activity, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, 'open', %s, %s, %s, %s, %s, %s)
                """,
                [
                    conversation_id, recipient, cot.id, lead.id, conversation_id,
                    "greeting",
                    json.dumps({"s1_fixture": True, "run_id": run_id, "identidad": sufijo}),
                    json.dumps({"s1_fixture": True}),
                    json.dumps({"s1_fixture": True, "cotizacion_id": cot.id}),
                    ahora, ahora - timedelta(minutes=1), ahora,
                ],
            )
        creado["sesiones"].append(conversation_id)

    return creado


def postcondiciones(creado, recipient):
    """Se comprueban DENTRO de la transacción. Si algo no cuadra, se aborta el conjunto."""
    _exigir(len(creado["cotizaciones"]) == 2, "no se crearon exactamente 2 cotizaciones")
    _exigir(len(creado["leads"]) == 2, "no se crearon exactamente 2 leads")
    _exigir(len(creado["detalles"]) == 2, "no se crearon exactamente 2 detalles")
    _exigir(len(creado["sesiones"]) == 2, "no se crearon exactamente 2 sesiones")

    _exigir(len(set(creado["cotizaciones"])) == 2, "las cotizaciones A y B no son distintas")
    _exigir(len(set(creado["leads"])) == 2, "los leads A y B no son distintos")
    _exigir(len(set(creado["sesiones"])) == 2, "las conversaciones A y B no son distintas")

    with connection.cursor() as cur:
        cur.execute(
            """SELECT count(*), count(*) FILTER (WHERE status = 'open'),
                      count(DISTINCT phone_number)
                 FROM whatsapp_sessions WHERE conversation_id = ANY(%s)""",
            [creado["sesiones"]],
        )
        total, abiertas, telefonos = cur.fetchone()
    _exigir(total == 2, "las dos sesiones no están en la tabla")
    _exigir(abiertas == 2, "alguna sesión no quedó `open`")
    _exigir(telefonos == 1, "las dos sesiones no comparten el mismo transporte")

    # Consistencia quote/lead/identidad, leída de vuelta y no asumida.
    for cot_id, lead_id in zip(creado["cotizaciones"], creado["leads"]):
        lead = Lead.objects.select_related("cotizacion").get(id=lead_id)
        _exigir(lead.cotizacion_id == cot_id, "lead y cotización no están emparejados")
        _exigir(lead.cotizacion.telefono == recipient[2:], "la cotización no lleva el recipient")
        _exigir(hasattr(lead.cotizacion, "xml_cache"), "la cotización no tiene detalle asociado")


def main():
    aplicar = (os.environ.get("S1_FIXTURE_APPLY") or "").strip() == "1"
    try:
        run_id, recipient = guards()

        class Rollback(Exception):
            pass

        creado = {}
        try:
            with transaction.atomic():
                creado = materializar(run_id, recipient)
                postcondiciones(creado, recipient)
                if not aplicar:
                    raise Rollback  # dry-run: se deshace TODO deliberadamente
        except Rollback:
            SALIDA["status"] = "DRY_RUN_OK"
            SALIDA["motivo"] = "postcondiciones verdes; transacción revertida a propósito"
        else:
            SALIDA["status"] = "APPLIED"

        SALIDA["cotizaciones"] = len(creado.get("cotizaciones", []))
        SALIDA["leads"] = len(creado.get("leads", []))
        SALIDA["detalles"] = len(creado.get("detalles", []))
        SALIDA["sesiones"] = len(creado.get("sesiones", []))

        if aplicar and SALIDA["status"] == "APPLIED":
            destino = os.environ.get("S1_FIXTURE_PRIVATE_OUT")
            if destino:
                fd = os.open(destino, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                with os.fdopen(fd, "w") as fh:
                    json.dump({"run_id": run_id, "recipient": recipient, **creado}, fh)
                SALIDA["handoff_privado"] = "escrito 0600"

    except GuardFallido as exc:
        SALIDA["status"] = "BLOCKED"
        SALIDA["motivo"] = str(exc)
    except Exception as exc:  # cualquier otra cosa también es BLOCKED, nunca un éxito parcial
        SALIDA["status"] = "BLOCKED"
        SALIDA["motivo"] = f"{type(exc).__name__}: {exc}"

    # Salida pública: conteos y estado. Sin IDs, sin teléfono, sin run-id, sin filas.
    publica = {k: v for k, v in SALIDA.items() if k != "motivo"}
    print("S1_FIXTURE_RESULT " + json.dumps(publica, sort_keys=True))
    if SALIDA["motivo"]:
        print("S1_FIXTURE_REASON " + SALIDA["motivo"])
    sys.exit(0 if SALIDA["status"] in ("APPLIED", "DRY_RUN_OK") else 1)


main()
