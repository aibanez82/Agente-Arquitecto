#!/bin/bash
# Prueba api.php m=listrecs y m=searchlink (solo lectura) contra PROD para 4 pólizas con estado conocido en conciliacion_pagos.
# Objetivo: validar que listrecs devuelve status_rec ("pagado"/"rechazado"/...) con el wptoken que ya tenemos,
# y ver cómo responde una póliza CANCELADO (¿distingue de pagada, cosa que fareceipt no hace?).
URL="https://pagos.qualitas.com.mx/api.php"
WPTOKEN=$(heroku config:get QUALITAS_WPTOKEN -a hyl-wai-production)

for entry in "PAGADO:7620099601" "PENDIENTE:7620099716" "VENCIDO:7620098627" "CANCELADO:7620098974"; do
  estado="${entry%%:*}"; poliza="${entry##*:}"
  echo "=============================================="
  echo "Póliza $poliza — estado en conciliacion_pagos: $estado"
  echo "--- m=listrecs"
  curl -s -m 30 -X POST "$URL" -H 'Content-Type: application/json' \
    -d "{\"wptoken\":\"$WPTOKEN\",\"m\":\"listrecs\",\"poliza\":\"$poliza\"}"
  echo
  echo "--- m=searchlink"
  curl -s -m 30 -X POST "$URL" -H 'Content-Type: application/json' \
    -d "{\"wptoken\":\"$WPTOKEN\",\"m\":\"searchlink\",\"poliza\":\"$poliza\"}"
  echo
done
