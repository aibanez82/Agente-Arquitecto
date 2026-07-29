#!/bin/bash
# Prueba oplListReceipts (solo lectura) contra OPL PROD para 4 pólizas con estado conocido en conciliacion_pagos
URL="https://pagos.qualitas.com.mx/ws/wsCollection.php"
WPUID=$(heroku config:get QUALITAS_WPUID -a hyl-wai-production)
WPTOKEN=$(heroku config:get QUALITAS_WPTOKEN -a hyl-wai-production)
PID="08545"

for entry in "PAGADO:7620099601" "PENDIENTE:7620099716" "VENCIDO:7620098627" "CANCELADO:7620098974"; do
  estado="${entry%%:*}"; poliza="${entry##*:}"
  XML_INTERNO="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<oplCollection>
    <ListReceipts Pid=\"$PID\" wpuid=\"$WPUID\" wptoken=\"$WPTOKEN\">
    <ListReceiptsData>
        <poliza>$poliza</poliza>
    </ListReceiptsData>
    <CodigoError />
    </ListReceipts>
</oplCollection>"

  SOAP="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ws=\"$URL\">
  <soapenv:Header/>
  <soapenv:Body>
    <ws:oplListReceipts>
      <xml_list><![CDATA[$XML_INTERNO]]></xml_list>
    </ws:oplListReceipts>
  </soapenv:Body>
</soapenv:Envelope>"

  echo "=============================================="
  echo "== $estado — poliza $poliza"
  echo "=============================================="
  curl -s --max-time 25 -X POST "$URL" \
    -H "Content-Type: text/xml; charset=UTF-8" \
    -H "SOAPAction: $URL#oplListReceipts" \
    --data "$SOAP" | sed 's/&lt;/</g; s/&gt;/>/g'
  echo; echo
done
