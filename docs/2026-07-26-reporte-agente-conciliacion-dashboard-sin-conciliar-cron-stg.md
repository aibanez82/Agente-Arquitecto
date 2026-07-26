# Reporte del Agente Conciliación — pólizas "SIN CONCILIAR" en el Dashboard + cron diario activado en `stg`

> Autor: Agente Conciliación (Nivel 3) · Fecha: 26 julio 2026
> Destinatario: **Arquitecto-IA-Qualitas** (vía Alberto).
> Estado: 🟡 Corrida manual ejecutada y verificada. Cron activado en `stg` — **pendiente de verificación en vivo del Arquitecto antes de mergear a `main`** (donde recién se vuelve efectivo el `schedule:`).

## Disparador

Alberto reportó que el Dashboard mostraba algunas pólizas como "sin conciliar".

## Diagnóstico

**No es un bug de matching ni un fallo silencioso de `conciliar.js`.** El Dashboard
(`Dashboard_SeguroAuto/pages/api/conciliacion.js`) marca una póliza como `SIN CONCILIAR` cuando
`total_recibos = 0` — es decir, cuando no existe ninguna fila en `conciliacion_pagos` para ese
`numero_poliza` todavía.

Confirmado contra la BD real (`CONCILIACION_DATABASE_URL`, misma Postgres de PROD): 9 de 47
pólizas en `qualitas_polizaemitida` no tenían recibos. Las 9 tienen `fecha_emision` entre el
22 y el 25 de julio — **todas después de la última corrida exitosa (21 jul, 00:13 UTC)**. La
causa es simplemente que `.github/workflows/conciliar.yml` solo tenía `workflow_dispatch:` — el
`schedule:` diario seguía comentado (pendiente ya documentado en `CLAUDE.md` de este repo,
"Estado actual" → punto 1), y nadie disparó una corrida manual desde el 21 jul.

## Qué se hizo

1. **Corrida manual** (`gh workflow run conciliar.yml --ref stg`, run `30183829981`) —
   completó exitosa. Verificado en la BD: las 9 pólizas ya tienen recibos (`sin conciliar` pasó
   de 9 a 0, `verificado_en` más reciente = 26 jul 02:04 UTC).
2. **Activé el cron diario en `stg`** (commit `5a3b9a2`, ya pusheado a `origin/stg`):
   descomenté `schedule: cron: '0 12 * * *'` en `.github/workflows/conciliar.yml` (06:00
   America/Mexico_City). Alberto confirmó explícitamente que quería activarlo ya.
3. Actualicé el `CLAUDE.md` de `Agente-Conciliacion` con la causa raíz y el cierre de este
   pendiente.

## Lo que falta — decisión/verificación del Arquitecto

El protocolo (`docs/protocolos/agente-conciliacion.md`, sección "Flujo") gatea la activación
del cron a que **"Arquitecto verifica en vivo"** antes de ese paso. Encontré además un detalle
técnico que hace este gate obligatorio, no solo protocolar: **GitHub solo evalúa el trigger
`schedule:` usando el archivo del workflow tal como existe en la rama default del repo (`main`
en `Agente-Conciliacion`)** — aunque el job después haga checkout de `stg`. Es decir, el cron
**no está realmente activo todavía**: el commit vive en `stg`, no en `main`.

Alberto ya decidió esperar tu verificación antes de mergear `stg` → `main` en este repo, en vez
de que yo lo hiciera directo. Cuando la corras, el merge que falta es únicamente el diff de
`.github/workflows/conciliar.yml` (+ el párrafo nuevo en `CLAUDE.md`) — nada de `src/conciliar.js`
cambió.

## Pendiente aparte, sin tocar en esta sesión

Sigue abierto el punto 2 de "Pendiente" en el `CLAUDE.md`: si `VENCIDO` / `VENCIDO: HOY 12 HORAS`
/ `CANCELADO` necesitan tratamiento especial de negocio (alertar a alguien) o si con guardarlos
en la tabla basta.
