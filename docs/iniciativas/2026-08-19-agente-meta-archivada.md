# Agente-Meta — iniciativa ARCHIVADA

> Decisión de Alberto, 19 agosto 2026. Repo: `aibanez82/Agente-META` (privado).
> Última actividad: 28 julio 2026 (`8e17fb0`). Seis commits, dos días de vida.

---

## Qué era

Un ejecutor **Nivel 1 (lectura + guía)** dedicado a Meta Business Manager, al Meta Business Partner
Program y a la WhatsApp Business Platform. Dos frentes declarados en su `CLAUDE.md`, de naturaleza
distinta y explícitamente no mezclables:

1. **Guía de configuración y cumplimiento** — acompañar el alta y mantenimiento de Insurmind en
   Meta: verificación de negocio, alta en el Partner Program, registro de números, aprobación de
   plantillas, políticas.
2. **Análisis vía API** — leer por Graph API / WhatsApp Business Management API el estado real de la
   instancia: calidad de plantillas, *messaging tier*, calidad del número, entregabilidad, costos
   por categoría de conversación, y cruzarlo con lo que Django y n8n registran como enviado.

Heredaba la regla de oro del ecosistema: no ejecutar acciones irreversibles en Meta por su cuenta.

## Por qué se archiva

**El frente 2 nunca llegó a arrancar, y no por falta de trabajo sino por dependencia de un tercero.**
El 28 de julio el propio repo registró la corrección que lo explica: *«Alberto NO es administrador de
Meta Business Manager — lo es Juan»*. La cadena real quedó documentada como

```
Agente-Meta → Alberto → Juan (admin de Meta) → Meta Business Manager
```

`SOLICITUD_ACCESOS.md` —la petición a Juan de un System User de solo lectura y su token— quedó en
estado **«pendiente de enviar»** y ahí sigue. Sin ese token no hay análisis por API, que era la
mitad del valor del agente; y la otra mitad, la guía, la absorbe el Arquitecto cuando toca, porque
Meta se pide a Juan con el material listo.

Consecuencia observable de que nunca arrancó: el fichero `ejecutores/ARQUITECTO-Meta.md` que su
propia bitácora `HALLAZGOS.md` daba por existente en este repo **nunca se creó**, y `HALLAZGOS.md`
no tiene ni un hallazgo registrado. `Agente-META` tampoco figuró nunca en el mapa de sistemas de
`CLAUDE.md`: el clon estaba en `~/claude-projects/` sin que ningún documento del Arquitecto lo
mencionara.

## Qué se rescata, y dónde vive ahora

Nada de esto se pierde al archivar: el repo se conserva, solo deja de considerarse un ejecutor vivo.

| Material | Dónde | Sigue valiendo para |
|---|---|---|
| `SOLICITUD_ACCESOS.md` | `Agente-META` | Está redactado para que Juan lo lea sin conocer el proyecto. Si algún día se pide el acceso de lectura a Meta, se reenvía tal cual — no hay que rehacerlo |
| `ONBOARDING_PARTNER_PROGRAM.md` · `PLANTILLAS.md` | `Agente-META` | Consulta puntual sobre alta en Meta y plantillas |
| `scripts/set-secret.sh` | `Agente-META` | Cargar tokens sin exponerlos |
| La regla operativa | `CLAUDE.md` § Pendientes → *«el token de Meta lo ejecuta Juan, junto con la plantilla de re-enganche»* | Ya estaba escrita y sigue vigente: no depende de este agente |

## Si se retoma

Dos condiciones, y la primera manda: **que Juan haya entregado el token de solo lectura** de
`SOLICITUD_ACCESOS.md`, y que exista un consumidor real de esos datos (hoy la plantilla de
re-enganche de 24 h es el único bloqueante de Meta que aparece en los pendientes, y es de Juan).
Antes de eso, reabrir el agente es crear un ejecutor sin insumo.
