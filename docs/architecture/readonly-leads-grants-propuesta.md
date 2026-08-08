# `readonly_leads` — huecos de SELECT y propuesta de grants acotados

8 ago 2026. Inventario **de solo lectura** sobre los catálogos de PROD. **Nada ejecutado**: los
grants los decide y aplica Juan (decisión de Alberto: la BD es suya).

## 1. La cifra real

De **93** tablas/vistas del esquema `public`, `readonly_leads` tiene SELECT sobre **14** y **le
faltan 79**. (En el barrido del tracker de esta mañana dije «21 tablas `qualitas_*`»: ese era el
subconjunto `qualitas_*`, y son **21** de esa familia. El total es 79.)

## 2. El criterio vigente se lee solo

Las 14 que sí tiene son exactamente el **dominio operativo** — leads, cotizaciones, pólizas,
WhatsApp y conciliación:

`qualitas_lead` · `qualitas_cotizacion` · `qualitas_polizaemitida` · `qualitas_asegurado` ·
`qualitas_leadactionevent` · `qualitas_whatsappmessage` · `whatsapp_sessions` (+`_archive`) ·
`n8n_chat_histories` (+`_archive`) · `conciliacion_pagos` · `leads_metepec` · `pg_stat_statements` (+`_info`)

No hay CMS, ni auth, ni admin. La propuesta de abajo **respeta ese criterio** en vez de inventar uno.

## 3. Por qué NO se propone un grant masivo

Un `GRANT SELECT ON ALL TABLES IN SCHEMA public` sería un error de seguridad, no un atajo. Entre las
79 que faltan están:

| Tabla | Qué contiene |
|---|---|
| `auth_user` | **hashes de contraseña** de los usuarios de Django/Wagtail |
| `django_session` | claves de sesión activas |
| `dashboard_users` | usuarios del Dashboard |
| `qualitas_leadadminsecuritysettings` | ajustes de seguridad del admin |

Darle eso a un rol de lectura para informes es exactamente lo que `#134` intenta evitar. Tampoco se
propone `ALTER DEFAULT PRIVILEGES`, por el mismo motivo: barrería automáticamente cualquier tabla
futura, incluidas las de esa clase. Hoy no hay ninguna default ACL definida, y conviene que siga así.

Fuera del alcance también: las **28 tablas `wagtailcore_*`** y demás CMS, `doc_chunks`/`kb_chunks`,
`taggit_*` y `django_*`. No hacen falta para diagnosticar el funnel.

## 4. Propuesta: siete tablas, cada una con su motivo

```sql
GRANT SELECT ON
  qualitas_leadcheckpointfollowupattempt,
  qualitas_leadfollowuppolicy,
  qualitas_leadfollowuppolicyaudit,
  qualitas_leadoperationalinfo,
  qualitas_cotizacionrespuestaxml,
  qualitas_numbersblacklist,
  qualitas_numeropruebawhatsapp
TO readonly_leads;
```

| Tabla | Filas (est.) | Por qué |
|---|---|---|
| `qualitas_leadcheckpointfollowupattempt` | 146 | **desbloquea `qualitas-issues#40`**, hoy no verificable |
| `qualitas_leadfollowuppolicy` / `...audit` | s/d | mismo dominio de seguimiento; sin ellas el diagnóstico de #40 queda a medias |
| `qualitas_leadoperationalinfo` | s/d | info operativa del lead, hermana directa de `qualitas_lead`, que sí está |
| `qualitas_cotizacionrespuestaxml` | 1 235 | **desbloquea `qualitas-issues#18`** (las opciones de cotización viven aquí) |
| `qualitas_numbersblacklist` | 70 | diagnóstico de WhatsApp: por qué a un número no se le envía |
| `qualitas_numeropruebawhatsapp` | **3** | ver abajo — puede estar en la ruta crítica de S1 |

`s/d` = `reltuples = -1`, es decir **nunca analizada**; no significa vacía.

## 5. `qualitas_numeropruebawhatsapp` merece un párrafo

Tiene **3 filas** y es, por nombre y por dominio, el registro de **números de prueba de WhatsApp**.

La materialización del par sintético A/B de S1 está bloqueada exactamente por eso: hace falta un
recipient **sintético y allowlisted** que alguien pueda atestiguar como tal, y el contrato prohíbe
inferirlo. Si esas tres filas son los números de prueba registrados, la respuesta ya existe en la
base y no la podemos leer.

Eso convierte este grant en algo más que higiene de tracker: puede estar en la ruta crítica de S1.
No lo afirmo —no puedo leer la tabla—, lo señalo como lo más probable y comprobable en un minuto por
quien sí tenga acceso.

## 6. Nota sobre STG

Este inventario es de PROD. Conviene decidir el mismo criterio para STG en la misma pasada, en vez
de descubrir el hueco a mitad de una corrida.

## 7. El riesgo que esto quita

El barrido de hoy dejó dos issues sin verificar por falta de permiso. El peligro no es la
incomodidad: es que **«no hay datos» y «no hay permiso» se ven igual** desde fuera. Ya estuve a punto
de publicar una conclusión falsa por esto mismo cuando `information_schema` me ocultó unas tablas de
PROD que sí existían — se veían como ausentes cuando solo estaban sin grants.
