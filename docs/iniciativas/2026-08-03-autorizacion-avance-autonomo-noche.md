# Autorización — avance autónomo del Arquitecto (Alberto durmiendo, 3 ago ~04:2X UTC)

Alberto autorizó explícitamente (chat): *"me voy a dormir. avanza todo sin mí. toma decisiones y ejecuta además de hacer ejecutar a los demás agentes."*

## Alcance que asumo
- **Ejecuto yo mismo** el trabajo OFFLINE del arnés C2 (autoría del SHA sucesor vía subagente-ejecutor + verificación independiente + entrega/puente al monitor), además de coordinar.
- **Tomo decisiones de nuestro lado** (implementación, verificación, cuándo entregar, iterar sobre FAILs).

## Límites que NO cruzo (gobernanza de Juan, no anulable por Alberto)
Nada vivo: STG/PROD, `--execute` contra STG real, import a n8n, activar workflows, merge/deploy/PR #145, Meta/IA real, secretos, `dual`/`enforced`, C3–C9 vivos, DDL/flags STG.
**Ventana viva C2:** requiere Alberto presente (humano) + 7 condiciones frescas (`5154662330`) — dormido NO puede ocurrir; no se intenta.
**Criterios de producto** (M7, divergencias): se escalan al monitor/Juan, no los decido yo.

## Modo de operación
Bucle autónomo: (sub)ejecutor implementa el SHA sucesor offline → verifico independiente con los canarios CORRECTOS (`--execute` instrumentado, no solo `--ensayo-local`) → entrego + puenteo al monitor → dictamen → si FAIL, transcribo + re-implemento; si PASS, avanzo. Tablero + este registro al día. Updates a Alberto por chat (los ve al despertar); sin push notifications.
