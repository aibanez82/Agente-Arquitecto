-- Tabla propia de seguimiento de leads entregados a METEPEC (contact center de Highland).
-- Nunca escribe en tablas de Django (qualitas_lead, qualitas_cotizacion, qualitas_polizaemitida)
-- -- referencia laxa por id, sin FK real, misma filosofía que conciliacion_pagos
-- (Agente-Conciliacion:migrations/001_create_conciliacion_pagos.sql).
--
-- Aplicar primero en STAGING. Contexto completo:
-- docs/iniciativas/2026-07-20-leads-metepec-seguimiento-comisiones.md

CREATE TABLE IF NOT EXISTS leads_metepec (
  id                             bigserial PRIMARY KEY,

  -- Referencia laxa al lead/cotización original en Postgres compartida (Django).
  -- Sin FK real a propósito: esta tabla no debe depender del ciclo de vida de Django.
  lead_id                        integer,
  cotizacion_id                  integer,

  -- Snapshot de datos del lead al momento de la entrega a METEPEC (puede divergir
  -- del dato vivo en Django si éste cambia después).
  nombre                         text,
  telefono                       text NOT NULL,
  email                          text,
  vehiculo_descripcion           text,           -- ej. "Nissan Versa 2022"
  codigo_postal                  text,

  fecha_oportunidad_creada       timestamptz,    -- cuándo nació el lead en nuestro funnel
  monto_poliza_cotizado          numeric(12,2),  -- precio cotizado al momento de la entrega
  fecha_entrega_metepec          timestamptz NOT NULL DEFAULT now(),
  motivo_entrega                 text,           -- por qué no lo pudimos cerrar nosotros

  -- Seguimiento del resultado en METEPEC. Valores esperados de estado_metepec:
  -- 'pendiente' | 'vendida' | 'no_vendida' | 'declinada' -- sin CHECK constraint todavía,
  -- por si aparece un estado no previsto (mismo criterio que conciliacion_pagos.estado).
  estado_metepec                 text NOT NULL DEFAULT 'pendiente',
  fecha_cierre_metepec           date,
  monto_cierre_metepec           numeric(12,2),

  -- Seguimiento de la negociación de comisión con Highland por estas ventas.
  considerada_en_comision        boolean NOT NULL DEFAULT false,
  fecha_considerada_en_comision  timestamptz,

  notas                          text,
  creado_en                      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_leads_metepec_lead_id       ON leads_metepec (lead_id);
CREATE INDEX IF NOT EXISTS idx_leads_metepec_cotizacion_id ON leads_metepec (cotizacion_id);
CREATE INDEX IF NOT EXISTS idx_leads_metepec_estado        ON leads_metepec (estado_metepec);
