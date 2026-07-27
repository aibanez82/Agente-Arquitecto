# Reporte del Agente Conciliación — pólizas "SIN CONCILIAR" en el Dashboard + cron diario activado en `stg`

> Autor: Agente Conciliación (Nivel 3) · Fecha: 26 julio 2026
> Destinatario: **Arquitecto-IA-Qualitas** (vía Alberto).
> Estado: ✅ **Certificado por el Arquitecto (26 jul 2026)** — verificación en vivo hecha y merge `stg`→`main` ejecutado. Cron diario EFECTIVO. Detalle al final del documento.

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

## Verificación del Arquitecto (26 jul 2026) — CERTIFICADO ✅

Verificado en vivo:

1. **Run `30183829981`**: success (job `conciliar`, 3m56s). Hubo además una segunda corrida manual
   el 26 jul 15:38 UTC (run `30208643776`), también exitosa.
2. **BD PROD**: 48 pólizas en `qualitas_polizaemitida`, **0 sin recibos** en `conciliacion_pagos`,
   última `verificado_en` = 26 jul 15:43 UTC (la segunda corrida recogió la póliza 48, emitida hoy).
3. **Claim del `schedule:` confirmado**: GitHub solo evalúa cron desde la rama default. Correcto.
4. **Corrección al reporte**: el merge necesario NO era solo el diff de `conciliar.yml`. El
   `checkout` del workflow no fija ref → en trigger `schedule` corre el código de `main`, y `main`
   estaba 10 commits atrás (aún tenía el `src/conciliar.js` pre-mapeo del portal). Cherry-pickear
   solo el yml habría puesto el cron a correr código viejo. Se hizo merge `stg`→`main` **completo**
   (fast-forward `2e2b987..5a3b9a2`, 10 commits — todos ya probados en las 3 corridas exitosas).
5. **Estado final**: workflow `Conciliar pagos Quálitas` en state `active` con
   `schedule: 0 12 * * *` (06:00 CDMX) ya en `main` → **cron diario efectivo desde hoy**.
   Primera corrida automática esperada: 27 jul 12:00 UTC.

**Lección para futuros workflows con cron**: si un repo usa gitflow `stg`→`main`, el `schedule:`
solo vive en la rama default Y el checkout sin ref ejecuta esa misma rama — activar un cron "en
stg" nunca activa nada hasta el merge, y el merge debe llevar el código completo, no solo el yml.

## Pendiente aparte, sin tocar en esta sesión

Sigue abierto el punto 2 de "Pendiente" en el `CLAUDE.md`: si `VENCIDO` / `VENCIDO: HOY 12 HORAS`
/ `CANCELADO` necesitan tratamiento especial de negocio (alertar a alguien) o si con guardarlos
en la tabla basta.
