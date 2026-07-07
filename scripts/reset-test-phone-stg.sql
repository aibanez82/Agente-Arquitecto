-- Reset de datos de prueba de un número en el entorno de STAGING (hyl-wai-stg).
-- NUNCA correr contra producción.
--
-- Uso: reemplazar TELEFONO_REPLACE (10 dígitos, sin prefijo de país) en las 4
-- apariciones de abajo y correr en TablePlus (o el cliente SQL que uses)
-- conectado a la BD de STAGING. Repetible cada vez que quieras limpiar el
-- número para una prueba E2E nueva.
--
-- Basado en las relaciones de qualitas/models.py (aguayo-co/HYL-WAI):
-- qualitas_cotizacion tiene CASCADE hacia Lead, Asegurado, PolizaEmitida y
-- CotizacionRespuestaXml (se borran solos). qualitas_leadactionevent y
-- qualitas_whatsappmessage usan SET_NULL (NO cascadean) y hay que borrarlos
-- aparte o quedan huérfanos con la referencia en NULL.

BEGIN;

DELETE FROM qualitas_leadactionevent
WHERE cotizacion_id IN (SELECT id FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE')
   OR lead_id IN (
        SELECT l.id FROM qualitas_lead l
        JOIN qualitas_cotizacion c ON l.cotizacion_id = c.id
        WHERE c.telefono = 'TELEFONO_REPLACE'
   );

DELETE FROM qualitas_whatsappmessage
WHERE phone_number LIKE '%TELEFONO_REPLACE%';

-- CASCADE se encarga de Lead, Asegurado, PolizaEmitida y CotizacionRespuestaXml
DELETE FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE';

-- Tablas de n8n (mismo Postgres de STG). LIKE en vez de = por si el prefijo
-- de país quedó como 52 o 57 (ver Bug #2 / hallazgo NumeroPruebaWhatsapp sin resolver).
DELETE FROM n8n_chat_histories WHERE session_id LIKE '%TELEFONO_REPLACE';
DELETE FROM whatsapp_sessions WHERE session_id LIKE '%TELEFONO_REPLACE';

COMMIT;
