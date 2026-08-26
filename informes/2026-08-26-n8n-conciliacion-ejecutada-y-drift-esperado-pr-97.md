# Informe — Conciliación ejecutada por su vía, y el registro de deriva esperada en PR #97

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-26 (UTC)

## 1 · Conciliación (Enmienda 2 verificada en el fichero antes de tocar)

- **Cron apagado, acreditado por lectura de API**: `gh workflow list` → `Conciliar pagos Quálitas · disabled_manually`.
- **README**: rama `docs/cambio-de-oficio-ledger`, **PR aibanez82/Agente-Conciliacion#1** (sin
  mergear). Arriba del todo: el cambio de oficio (no «retirado» — Enmienda 1), la tabla declarada
  congelada al 18 ago, y la pregunta abierta de la `7620098864` con las dos lecturas y fechas
  (recibo `1-0306846095`, `PAGADO 2026-07-28`, leído el 18 ago — anterior a la avería — vs 0 en el ledger).
- **Tabla intacta y congelada, medida**: última escritura `verificado_en = 2026-08-18`, cero
  posteriores. **Total real: 320 filas, no las 308 del handoff** — discrepancia reportada, no
  promediada: ningún corte obvio da 308 (320 totales, 58 pólizas —tu 58/59 sí casa—, 121
  cancelados —tu 121 sí casa—). La propiedad exigida (nada borrado, nada nuevo) se cumple de sobra.
- Pendiente del oficio nuevo (propuesta de primer comando de reporte): es del Agente Conciliación
  cuando despierte, o de otra enmienda si decides otra cosa — no lo he tocado.

## 2 · Deriva esperada — dictamen ejecutado con tus dos condiciones (PR #97, sin mergear)

`docs/drift-esperado.json` + detector + arnés, en rama `fix/185-deriva-esperada` → **PR #97 a `stg`**.

- **Corrección de supuesto**: el monitor NO corre desde `main` — el cron de Actions ejecuta desde
  la rama por defecto (`stg`), y `.github/workflows/drift-monitor.yml` solo existe allí. Por eso el
  PR va a `stg`.
- **Condición A** (caducidad): cada entrada lleva `caduca` = `desde`+30 días; vencida → **rojo** con
  el mensaje literal «'aceptado' no puede degradar a 'olvidado'» hasta renovar o retirar.
- **Condición B** (supresión visible): el registro completo se imprime en **cada corrida** — motivo,
  ref, días restantes y estado (EN USO hoy / sin drift hoy, retirarla / CADUCADA) — junto al
  «17 destinos revisados».
- **Huella doble**: sha256 de `sustancia()` de cada lado; si cualquiera cambia, la entrada no casa
  y el target vuelve a rojo como `[DRIFT CAMBIADO]`. `ref` comprobable obligatoria.
- **Tres estados probados en local**: ámbar → exit 3; huella rota → `[DRIFT CAMBIADO]`, exit 2;
  caducada → `[DRIFT ESPERADO CADUCADO]`, exit 2; restaurado → 3.
- **El ámbar en Actions**: exit 3 → success **con anotación `::warning`** («deriva esperada
  (ámbar)») + el resumen completo en `$GITHUB_STEP_SUMMARY`. En la lista de runs se ve el triángulo
  amarillo — distinto de verde plano. Es lo más lejos que llega Actions sin conclusión `neutral`
  (retirada por GitHub); si no te basta como «distinto de verde», dímelo y le añadimos aviso
  Telegram ámbar semanal.
- **Sembradas las dos derivas vigentes**, ambas con ref: el export de PROD con el `#228`
  (`ecd569c`; PROD apagado por orden de Alberto) y el vivo de STG adelantado al candidato S1 por
  los PRs #93/#94/#96. Con el PR mergeado, la próxima corrida diaria del monitor pasa de rojo a
  ámbar con las dos listadas — y el día que Alberto importe PROD o mergee, esas huellas dejan de
  casar y el propio monitor pide retirar la entrada.
