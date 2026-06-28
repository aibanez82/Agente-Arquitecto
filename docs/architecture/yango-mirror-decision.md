# BBDD Espejo de Django (Django) — Decisión de Arquitectura

> Actualiza y reemplaza el plan original de "Logical Replication nativa / CDC con Debezium hacia Supabase o Neon".

## Hallazgos del admin de Django

| Pregunta | Respuesta |
|---|---|
| Motor de BBDD | PostgreSQL (local preparado con PostgreSQL 17) |
| Infraestructura | Servicio gestionado: **Heroku Postgres** |
| Replicación lógica / WAL | No se puede asegurar solo por estar en Heroku — **confirmado: no soportada** (ver hallazgo técnico abajo) |
| Usuario de solo lectura acotado | Probablemente sí, pero requiere validación en la instancia real |
| Acceso externo | Probablemente sí, controlado; falta confirmar modelo de red exacto |

## Hallazgo técnico clave

Heroku Postgres **no soporta replicación lógica hacia instancias externas** bajo ningún tier. Esto descarta la opción original de "Logical Replication nativa de Postgres". CDC con Debezium también queda en duda, ya que típicamente depende de slots de replicación lógica con la misma limitación.

Tier actual de la BBDD de producción: **Essential-0** ($5/mes). Este tier:
- No soporta fork/follow (confirmado con error real: `Error: You can't create a custom credential on Essential-tier databases.`)
- No permite credenciales adicionales (usuario de solo lectura separado)

## Decisión final: usuario de solo lectura directo en Standard-0 (sin follower)

Se evaluó usar un **follower** de Heroku Postgres (réplica física en tiempo real, aislada de producción), pero se descartó por costo: un follower es un add-on separado y facturado aparte — habría significado pagar dos instancias Standard-0 (~$100/mes en total) en vez de una (~$50/mes).

**Decisión tomada:** subir la BBDD de producción a Standard-0 y crear ahí mismo un **usuario/credencial de solo lectura**, sin follower. El dashboard se conecta directo a la base primaria con esa credencial limitada.

Trade-off aceptado conscientemente: las queries del dashboard comparten instancia física con la app real de Django (ya no hay aislamiento físico total), pero dado el volumen bajo (~1000 conversaciones/día) y que las consultas del dashboard son simples (no agregaciones pesadas), el riesgo de impacto en producción se considera bajo. Si en el futuro el dashboard necesita correr reportes/agregaciones pesadas, reevaluar el follower en ese momento.

### Plan de acción

1. ~~Subir la BBDD de producción de Essential-0 → Standard-0~~ — **hecho**
2. ~~Crear un follower~~ — **descartado por costo**
3. Crear una credencial de solo lectura en la base primaria (Standard-0 sí soporta credenciales adicionales)
4. Acotar esa credencial, vía `GRANT SELECT`, solo a las tablas de conversaciones/leads necesarias
5. Conectar el dashboard directo a la base primaria con esa credencial

### Pendiente de confirmar

- Modelo de red exacto para el acceso externo (qué tan "controlado" es el acceso — si requiere allowlist de IPs, VPN, etc.)
- Validar en la práctica que las queries del dashboard no generan carga perceptible sobre producción

## Decisiones descartadas

- ~~Logical Replication nativa de Postgres~~ — no soportada por Heroku hacia instancias externas
- ~~CDC con Debezium~~ — probablemente choca con la misma limitación de slots lógicos
- ~~Espejo en Supabase/Neon~~ — ya no es necesario
- ~~Follower de Heroku~~ — descartado por costo (duplicaba el gasto de BBDD); se opta por usuario de solo lectura directo en la primaria
