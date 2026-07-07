-- Reset de datos de prueba de un número en el entorno de STAGING (hyl-wai-stg).
-- NUNCA correr contra producción.
--
-- Uso: reemplazar TELEFONO_REPLACE (10 dígitos, sin prefijo de país) en todas
-- las apariciones de abajo y correr en TablePlus (o el cliente SQL que uses)
-- conectado a la BD de STAGING. Repetible cada vez que quieras limpiar el
-- número para una prueba E2E nueva.
--
-- v2 (7 jul, corregido con ayuda del Agente n8n + verificación directa de
-- pg_constraint en producción): las FK de qualitas/models.py usan
-- on_delete=CASCADE/SET_NULL, pero eso es comportamiento del ORM de Django,
-- NO un constraint real en la base de datos — TODAS las FK relevantes están
-- creadas como NO ACTION a nivel Postgres (verificado con pg_constraint).
-- Un DELETE SQL directo sobre qualitas_cotizacion NO cascadea nada solo:
-- hay que borrar cada tabla dependiente a mano, en el orden correcto.
--
-- Orden de borrado (hijos antes que padres, según las FK reales):
--   qualitas_leadoperationalinfo  → depende de lead
--   qualitas_leadactionevent      → depende de lead, cotizacion
--   qualitas_whatsappmessage      → depende de lead, cotizacion, self (trigger_message)
--   qualitas_lead                 → depende de cotizacion, asegurado, polizaemitida
--   qualitas_polizaemitida        → depende de asegurado, cotizacion
--   qualitas_asegurado            → depende de cotizacion
--   qualitas_cotizacionrespuestaxml → depende de cotizacion
--   qualitas_cotizacion
--   n8n_chat_histories / whatsapp_sessions (tablas de n8n, no Django)

BEGIN;

DELETE FROM qualitas_leadoperationalinfo
WHERE lead_id IN (
    SELECT l.id FROM qualitas_lead l
    JOIN qualitas_cotizacion c ON l.cotizacion_id = c.id
    WHERE c.telefono = 'TELEFONO_REPLACE'
);

DELETE FROM qualitas_leadactionevent
WHERE cotizacion_id IN (SELECT id FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE')
   OR lead_id IN (
        SELECT l.id FROM qualitas_lead l
        JOIN qualitas_cotizacion c ON l.cotizacion_id = c.id
        WHERE c.telefono = 'TELEFONO_REPLACE'
   );

DELETE FROM qualitas_whatsappmessage
WHERE phone_number LIKE '%TELEFONO_REPLACE%';

DELETE FROM qualitas_lead
WHERE cotizacion_id IN (SELECT id FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE');

-- polizaemitida ANTES que asegurado: polizaemitida.asegurado_id la referencia (NO ACTION).
DELETE FROM qualitas_polizaemitida
WHERE cotizacion_id IN (SELECT id FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE');

DELETE FROM qualitas_asegurado
WHERE cotizacion_id IN (SELECT id FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE');

DELETE FROM qualitas_cotizacionrespuestaxml
WHERE cotizacion_id IN (SELECT id FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE');

DELETE FROM qualitas_cotizacion WHERE telefono = 'TELEFONO_REPLACE';

-- Tablas de n8n (mismo Postgres de STG). LIKE en vez de = por si el prefijo
-- de país quedó como 52 o 57 (ver Bug #2 / hallazgo NumeroPruebaWhatsapp sin resolver).
DELETE FROM n8n_chat_histories WHERE session_id LIKE '%TELEFONO_REPLACE';
DELETE FROM whatsapp_sessions WHERE session_id LIKE '%TELEFONO_REPLACE';

COMMIT;
