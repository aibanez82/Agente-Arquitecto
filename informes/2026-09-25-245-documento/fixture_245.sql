-- fixture #245 — dos cotizaciones sintéticas: una CON documento y otra SIN él.
-- Handoff: handoffs/2026-09-25-245-ejercitar-el-cambio-que-viaja-de-polizon.md (4ec0838).
--
-- Qué decide el camino, leído en el backend (qualitas/views.py:1104):
--   documento_cotizacion.disponible = bool(pdf_cotizacion_url) AND autorizado
-- Así que el único campo que cambia entre las dos filas es `pdf_cotizacion_url`. Todo lo demás
-- —incluido el XML con las cifras— es idéntico, para que la comparación no arrastre otra variable.
--
-- El teléfono de la cotización es varchar(15), de ahí los identificadores cortos (sin dígitos igual).
-- Protocolo del handoff:
--   · clonar una real con INSERT … SELECT (origen: 2683, TOYOTA HIGHLANDER 2020, con XML y con PDF);
--   · sobreescribir toda la PII: correo y teléfono. NO se enlaza ningún asegurado;
--   · correos en `.invalid` (RFC 2606): no son example.com/.net/.org —que el fence de Juan bloquea
--     desde el release de hoy— y además no pueden entregarse a nadie;
--   · marca reconocible desde el Dashboard: el correo lleva `qa-suite-245`;
--   · borrado por IDs exactos y EN ORDEN FK al terminar: las FK son NO ACTION en Postgres aunque
--     models.py diga CASCADE, así que nada cascadea solo.

-- ── CREAR ────────────────────────────────────────────────────────────────────────────────────
WITH clon AS (
  INSERT INTO qualitas_cotizacion (
    fecha_creacion, email, telefono, codigo_postal, marca, nombre_marca, modelo, submarca, version,
    tarifa, clave_amis, nva_amis, transmision, ocupantes, valor_uno, valor_dos, categoria, forma_pago,
    paquete, serie_vehiculo, accion, monto_subsecuente, precio_total, primer_pago, subsecuentes_count,
    public_token, pdf_cotizacion_url, rc_suma_asegurada, pricing_source, qualitas_percentage
  )
  SELECT
    NOW(), v.email, v.telefono, c.codigo_postal, c.marca, c.nombre_marca, c.modelo, c.submarca,
    c.version, c.tarifa, c.clave_amis, c.nva_amis, c.transmision, c.ocupantes, c.valor_uno,
    c.valor_dos, c.categoria, c.forma_pago, c.paquete, c.serie_vehiculo, c.accion,
    c.monto_subsecuente, c.precio_total, c.primer_pago, c.subsecuentes_count,
    gen_random_uuid(), v.pdf, c.rc_suma_asegurada, c.pricing_source, c.qualitas_percentage
  FROM qualitas_cotizacion c
  CROSS JOIN (VALUES
    ('qa-suite-245-con@qa.invalid', 'QA-SUITE-CDF-C',
     'https://hyl-wai-www.s3.us-east-1.amazonaws.com/pdf_cotizacion/QA_SUITE_245_CON.pdf'),
    ('qa-suite-245-sin@qa.invalid', 'QA-SUITE-CDF-S', '')
  ) AS v(email, telefono, pdf)
  WHERE c.id = 2683
  RETURNING id, email, pdf_cotizacion_url
)
INSERT INTO qualitas_cotizacionrespuestaxml
  (cotizacion_id, xml_amplia_anual, xml_amplia_semestral, xml_amplia_trimestral, xml_amplia_mensual,
   xml_limitada_anual, xml_limitada_semestral, fecha_creacion)
SELECT clon.id, x.xml_amplia_anual, x.xml_amplia_semestral, x.xml_amplia_trimestral,
       x.xml_amplia_mensual, x.xml_limitada_anual, x.xml_limitada_semestral, NOW()
FROM clon, qualitas_cotizacionrespuestaxml x
WHERE x.cotizacion_id = 2683;

-- Verificación: dos filas, una con PDF y otra sin, ambas con XML.
SELECT c.id, c.email, c.nombre_marca, c.submarca, c.modelo,
       (c.pdf_cotizacion_url <> '') AS tiene_pdf,
       (x.cotizacion_id IS NOT NULL) AS tiene_xml
FROM qualitas_cotizacion c
LEFT JOIN qualitas_cotizacionrespuestaxml x ON x.cotizacion_id = c.id
WHERE c.email LIKE 'qa-suite-245-%@qa.invalid'
ORDER BY c.id;

-- ── LIMPIAR (orden FK; las FK son NO ACTION: nada cascadea solo) ─────────────────────────────
-- Sustituir <IDS> por los ids exactos que devolvió la verificación.
--
-- DELETE FROM n8n_chat_histories          WHERE session_id LIKE 'QA-SUITE-CDF-%';
-- DELETE FROM n8n_outbound_dispatch       WHERE session_id LIKE 'QA-SUITE-CDF-%';
-- DELETE FROM whatsapp_sessions           WHERE session_id LIKE 'QA-SUITE-CDF-%';
-- DELETE FROM qualitas_leadactionevent    WHERE cotizacion_id IN (<IDS>);   -- las crea el bot
-- DELETE FROM qualitas_cotizacionrespuestaxml WHERE cotizacion_id IN (<IDS>);
-- DELETE FROM qualitas_cotizacion         WHERE id IN (<IDS>);
