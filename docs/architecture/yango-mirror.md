# Base de datos espejo — Conversaciones Django (propuesta original)

> Estado: **superado**. Ver `yango-mirror-decision.md` para la decisión final tomada.

## Contexto original

El plan inicial era crear una base de datos espejo de producción Django para 
aislar las queries del dashboard del sistema transaccional.

## Por qué se descartó el espejo

- Heroku Postgres no soporta replicación lógica hacia instancias externas
- CDC con Debezium choca con la misma limitación de slots lógicos
- Un follower de Heroku duplicaba el costo (~$100/mes vs ~$50/mes)

## Decisión final

Usuario de solo lectura (`readonly_leads`) directo en Standard-0, sin espejo.
Ver `yango-mirror-decision.md` para el detalle completo.
