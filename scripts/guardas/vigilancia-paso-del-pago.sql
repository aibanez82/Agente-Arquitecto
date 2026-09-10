-- Vigilancia del paso del pago — Arquitecto-IA-Qualitas, 9 sep 2026
-- Responde una sola pregunta: ¿hay alguna póliza emitida y sin pagar que NO tenga
-- ninguna liga de pago viva? Ésa es la forma exacta en que perdimos la venta del BYD.
-- Solo lectura. Ejecutar a diario mientras haya pauta.
--
-- ACOTADA A 30 DIAS a proposito. Sin ese limite marca 36 polizas, y las de julio
-- llevan meses muertas: una poliza emitida sin pagar CADUCA SOLA, asi que su ventana
-- ya se cerro y no hay nada que rescatar. Una alarma que grita con el caso normal se
-- acaba ignorando, y entonces no avisa del caso que importa.
WITH poliza AS (
  SELECT p.id, p.numero_poliza, p.precio_total, p.estatus_pago,
         p.fecha_emision::date AS emitida, c.email, c.telefono
  FROM qualitas_polizaemitida p
  LEFT JOIN qualitas_lead l ON l.poliza_id = p.id
  LEFT JOIN qualitas_cotizacion c ON l.cotizacion_id = c.id
  WHERE p.numero_poliza IS NOT NULL AND p.estatus_pago <> 'PAGADO'
    AND p.fecha_emision >= now() - interval '30 days'
), liga AS (
  SELECT policy_number_snapshot AS pol,
         count(*) FILTER (WHERE deactivated_at IS NULL
                            AND status NOT IN ('expired','failed','superseded')) AS vivas,
         count(*) AS intentos,
         max(status) FILTER (WHERE status = 'failed') AS hubo_fallo
  FROM qualitas_receiptpaymentlink GROUP BY 1
)
SELECT
  po.numero_poliza, po.emitida, po.precio_total,
  coalesce(li.intentos,0)  AS intentos_de_liga,
  coalesce(li.vivas,0)     AS ligas_vivas,
  CASE
    WHEN coalesce(li.intentos,0) = 0 THEN 'SIN INTENTO — nadie le generó liga'
    WHEN coalesce(li.vivas,0)   = 0 THEN 'SIN VIA DE PAGO — se intentó y no quedó ninguna viva'
    ELSE 'ok'
  END AS veredicto,
  po.email
FROM poliza po LEFT JOIN liga li ON li.pol = po.numero_poliza
WHERE coalesce(li.vivas,0) = 0
ORDER BY po.emitida DESC;
