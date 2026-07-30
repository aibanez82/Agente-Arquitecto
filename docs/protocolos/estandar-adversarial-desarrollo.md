# Estándar adversarial de desarrollo — checklist anti-partido-de-tenis

> Origen: dos NO-GO consecutivos de Juan sobre el port #132 (29 jul 2026). Diagnóstico del
> Arquitecto: nosotros construíamos para demostrar que el fix funciona (tests positivos);
> Juan revisa para demostrar que no alcanza (revisión negativa). Este doc destila sus
> heurísticas — que son estables entre auditorías — en un estándar que todo ejecutor debe
> autocertificar ANTES de entregar, y que el Arquitecto ataca en una pasada adversarial
> propia ANTES de notificar a Juan.

## Proceso (obligatorio para fases con auditoría externa)

1. El handoff del Arquitecto referencia este doc.
2. El ejecutor implementa y **autocertifica punto por punto** la checklist en su reporte
   (tabla: punto → cómo se cumple → test que lo demuestra).
3. El Arquitecto NO notifica al auditor externo al recibir: primero corre las suites
   (reproducción) **y una pasada adversarial** — revisores independientes con mandato de
   romper el paquete usando esta checklist. Hallazgos → vuelven al ejecutor.
4. Solo cuando el paquete sobrevive la pasada adversarial se notifica al auditor.
5. Cada hallazgo del auditor externo se generaliza a su CLASE, se convierte en test de
   regresión, y si revela una heurística nueva, se añade aquí.

## La checklist (heurísticas de auditoría negativa)

**1. Clase, no instancia.** Un bug reportado sobre el valor X obliga a enumerar el dominio
COMPLETO de esa variable y decidir cada valor. Si el dominio es finito (estados, tipos,
códigos), la resolución es una tabla exhaustiva publicada, no un parche sobre X.

**2. Allowlist sobre blocklist.** Todo gate/filtro se expresa como "lo admitido" (fail-closed
ante valor desconocido o futuro), nunca como "lo prohibido conocido". Un valor nuevo que
aparezca mañana debe caer del lado seguro sin tocar código.

**3. NULL es un valor.** Toda comparación considera explícitamente NULL en cada lado
(`IS NOT DISTINCT FROM` / `COALESCE` decidido y documentado). "No pensé en NULL" = bug.

**4. Identidad completa.** Revalidar identidad = comparar TODAS las columnas que la definen
(catalogadas contra el DDL), no las que alguien mencionó en el último bug. Si se añade una
columna de identidad al esquema, hay UN punto del código que actualizar, no ocho.

**5. Toda llamada externa tiene TRES resultados.** Éxito, fallo, e INCIERTO
(timeout/4xx-5xx inesperado/respuesta sin el campo esperado). El incierto NUNCA se colapsa a
éxito ni a "nada que hacer"; se reporta como incierto y requiere verificación explícita.

**6. Verificar por definición, no por nombre.** Que exista un objeto llamado igual
(trigger, índice, constraint, función) no prueba nada: comparar definición normalizada,
firma, estado de habilitación, y que las piezas se invoquen ENTRE SÍ como se espera.

**7. Atomicidad o compensación.** Toda operación multi-paso sobre sistemas externos: o es un
solo paso atómico con los MISMOS bytes ya verificados (sin releer/regenerar entre verificación
y aplicación — TOCTOU), o cada paso tiene compensación probada y el estado parcial es
detectable.

**8. Tests que intentan engañarse.** Toda verificación (readiness, fingerprint, contraste)
tiene tests negativos con FAKES deliberados: el objeto homónimo pero vacío, la definición
casi-correcta, el estado deshabilitado que parece habilitado. Un checker sin test de fake es
un checker no probado. Además: el assert debe fallar por el motivo correcto (verificar el
mensaje/razón, no solo el booleano).

**9. Fail-first probado.** Cada fix lleva un test que FALLA contra el código pre-fix
(verificado con stash/checkout, no supuesto) y cuyo assert discrimina exactamente el síntoma.

**10. Carreras: la fila viva manda.** En concurrencia con locks, todo predicado se evalúa
sobre el estado POST-espera (fila viva, EPQ), nunca sobre el snapshot pre-lock; los tests de
carrera usan dos conexiones reales con el lock tomado en medio, no simulación secuencial.
Corolario cross-tabla (hallazgo Juan, 6.8.2→6.8.3): EPQ solo re-evalúa filas que la sentencia
toca — si la autoridad vive en OTRA tabla (claims), el fencing debe forzar el conflicto de
fila (FOR UPDATE / versión-epoch en la fila que la sentencia sí toca), no confiar en el
snapshot.

**11. El artefacto construido se valida contra el schema real del consumidor.** Todo artefacto
generado (JSON de workflow, SQL, payload) se contrasta contra fixtures REALES del sistema que
lo consumirá (exports de n8n, backups, respuestas de API) — la referencia casi siempre ya está
en el repo. Un test de integración que selecciona a mano la rama/valor que el consumidor
debería computar NO es un test de integración: hay que emular la evaluación del consumidor
(condición del IF, parser del endpoint) o validar el schema exacto. Casos que motivaron esta
regla: fingerprint calibrado contra fixtures inventados en vez de los backups de Fase 0
(6.8.1/A2) y los IF v2.3 serializados planos con tests que elegían `branchIndex` a mano
(6.8.2→6.8.3/H1).

## Ámbito

Aplica a: fases del port #132 y sucesoras, cambios de workflows n8n con SQL/concurrencia,
runbooks de deploy, y cualquier entregable que vaya a auditoría de Juan. Para cambios de copy
o docs, no aplica (el coste no se justifica).
