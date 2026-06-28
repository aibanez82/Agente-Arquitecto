# BBDD Espejo de Django — Decisión de Arquitectura

## Hallazgos del admin de Django

| Pregunta | Respuesta |
|---|---|
| Motor de BBDD | PostgreSQL 17 |
| Infraestructura | Heroku Postgres (servicio gestionado) |
| Replicación lógica / WAL | No soportada por Heroku hacia instancias externas |
| Usuario de solo lectura | Sí, disponible en Standard-0 |

## Decisión final: usuario de solo lectura directo en Standard-0

Se evaluó usar un follower de Heroku Postgres pero se descartó por costo (duplicaba el gasto ~$100/mes). 

Decisión: subir la BBDD a Standard-0 y crear una credencial de solo lectura. El dashboard se conecta directo a la base primaria con esa credencial limitada.

Trade-off aceptado: las queries del dashboard comparten instancia física con Django. Dado el volumen bajo (~1000 conversaciones/día) y queries simples del dashboard, el riesgo es bajo.

## Decisiones descartadas

- Logical Replication nativa de Postgres — no soportada por Heroku
- CDC con Debezium — choca con la misma limitación de slots lógicos
- Espejo en Supabase/Neon — ya no necesario
- Follower de Heroku — descartado por costo

## Plan de acción

1. ✅ Subir BBDD de Essential-0 → Standard-0
2. ~~Crear follower~~ — descartado
3. ✅ Crear credencial de solo lectura (`readonly_leads`)
4. ✅ Acotar con `GRANT SELECT` a tablas necesarias
5. ✅ Conectar dashboard directo con esa credencial
