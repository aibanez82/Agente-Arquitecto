# Borrador de checkpoint operativo C1 (HYL-WAI#132) — NO ejecutable

> Preparado por el Arquitecto bajo la luz verde de Juan (`HYL-WAI#140` c.`5149044773`, 1 ago 2026): "preparar, sin ejecutar". **Este borrador NO es GO.** Su ejecución exige un comentario posterior y explícito del accountable en #132. Cubre los 9 puntos que Juan fijó como mínimo. C2 queda **explícitamente fuera** (punto 9).

## 0. Objeto y alcance

Instalar y **verificar** las barreras de contención C1 en STG (los tres frentes ya aceptados offline en #140 c.`5149044773`). El checkpoint **instala/verifica C1; no ejecuta la matriz C2** ni ninguna prueba viva Dual. No toca PROD.

## 1. SHAs exactos, targets y IDs inmutables

| Frente | SHA/artefacto congelado | Target |
|---|---|---|
| n8n | PR `aibanez82/Agente-n8n#3` @ `4e2118c39ab39a9cda536df44ed42689931fc1dc` (base `stg@40fe572`) | rama `stg` de Agente-n8n; workflows STG (IDs abajo) |
| Dashboard | PR `aibanez82/Dashboard_seguroautoqualitas#2` @ `1373d1ab95f2e18f4758ad7d1d571e9dcf5f6fcc` (base `stg@e50e3ad`) — **congelado, sin pushes** | rama `stg` de Dashboard; app STG en Vercel |
| Django | C1 efectivo ya en `stg@4f0e7416` (PASS/CI registrado). PR #145 `c373ab11` es tooling CAS futuro y **NO forma parte de instalar C1** — permanece sin merge | `hyl-wai-stg` (Heroku) |

**Workflow IDs STG inmutables** (del C0 freeze, GET vivo 30 jul): `dNqtM20ij6ecZYAX` (Bot principal), `Ob5JYHYbc23SLp0A` (Payment Confirmation), `HAMIxqhZd2TEy6NB` (Atención Humana), `PuogahK4qv9YOiF4` (Issue Policy Guard sub), `liBCn3yBegedmYuR` (METEPEC Registrar), `biWlbwq4NQdZadwg` (Metepec Liberar), `nYRaRzU83qDLuEWI` (Retomar Conversación).
**App/BD:** Django STG `hyl-wai-stg`; BD STG `dei0jssp8kr5kv` @ RDS; instancia n8n STG `n8n-xlqk.srv1810257.hstgr.cloud`. **Ningún target apunta a PROD.**

## 2. Orden de integración/instalación y distinción merge / auto-deploy / import / activación

Secuencia propuesta, un frente a la vez con verificación entre pasos:

1. **Django** — ya en `stg@4f0e741`, no requiere merge nuevo. Verificar release activo y que **no hay migraciones pendientes** (`migrate --check --noinput`; la release phase de Heroku ejecuta migraciones al hacer `config:set`/deploy — no tocar config).
2. **Dashboard** — merge de PR #2 a `stg`. ⚠️ **El merge dispara auto-deploy Vercel** (Preview del push + el deploy de `stg` según config del proyecto). Distinción explícita: *merge* = integrar código; *auto-deploy* = efecto automático de Vercel que NO configura gates ni origins (siguen fail-closed sin `ALLOWED_ORIGINS`/`GATE_*`).
3. **n8n** — merge de PR #3 a `stg` (integración git) **≠** *import* a la instancia n8n STG. El import es paso manual aparte (API o UI), sobre los workflow IDs inmutables de arriba, sin activar. *Activación* = tercer acto distinto, NO incluido en C1 (los workflows quedan como estén; C1 instala barreras, no enciende tráfico).

**Los cuatro verbos son distintos y se registran por separado:** merge · auto-deploy · import · activación.

## 3. Backup fresco, fingerprints y verificación post-acción

- **Antes:** backup fresco de BD STG `dei0jssp8kr5kv`; capturar fingerprint target-guard (`074fffb71fc19f0c` es el del C0 baseline — reconfirmar en vivo), `root`/`activeVersion` de cada workflow STG antes de tocar.
- **Después:** re-capturar fingerprints/activeVersion y diff contra el pre; correr el runner C1 (`4e2118c`) contra el plano instalado y confirmar `RESULTADO: OK — plano contenido`.

## 4. Comandos exactos, operador/guardia/suplente y ventana

- **Comandos:** a rellenar con Alberto en la sesión de ventana (merge vía UI GitHub o `gh pr merge --merge`; import n8n vía script idempotente `Agente-n8n:scripts/import-stg-workflow.py` con el gotcha de `settings` documentado; verificación vía runner). **Se listan literal antes de ejecutar, no se improvisan.**
- **Operador:** Alberto. **Guardia/suplente:** a designar (Juan como observador en #132). **Ventana:** a pactar — propuesta: bloque de ~2h en horario laboral con ambos disponibles.

## 5. Cero ejecuciones en vuelo, producers pausados, destinos denegados

- Confirmar **0 ejecuciones n8n en vuelo** en STG (C0 registró 0) antes de importar.
- **Producers pausados:** followups STG ya apagados (flags C0); confirmar que ningún Schedule Trigger STG está activo.
- Destinos/conectores externos **denegados** durante la instalación (WhatsApp Send sin credencial de prod — ya es el estado del import STG; los 2 nodos WhatsApp quedan sin credencial a propósito).

## 6. Gates/origins actuales y efectos automáticos de Vercel

- **Estado actual (confirmar en vivo antes):** `GATE_TAKE_ENABLED`/`GATE_DISPATCH_ENABLED`/`GATE_METEPEC_ENABLED` **sin provisionar** en STG → fail-closed 403. `ALLOWED_ORIGINS` **sin provisionar** → origin guard deniega. **C1 se instala con los gates apagados; encenderlos NO es parte de este checkpoint.**
- **Efecto automático Vercel:** cada push/merge a `stg` genera deployment automático (Preview + entorno stg). Declarado y clasificado en #140 c.`5148002777`; el merge de C1 lo repetirá — es esperado, no acción manual.

## 7. Stop conditions, `uncertain`, RTO y rollback por repositorio

- **Stop conditions:** cualquier fingerprint post ≠ esperado; runner ≠ `OK — plano contenido`; migración pendiente detectada; cualquier ejecución en vuelo aparecida; error de import no idempotente.
- **`uncertain`:** si una acción no confirma su estado final (p. ej. respuesta ambigua del API n8n), se marca `uncertain` y se **detiene** — no se reintenta a ciegas.
- **RTO objetivo:** < 30 min por frente.
- **Rollback por repo:** Django → redeploy del release previo (`stg@4f0e741` ya es el baseline, sin cambio); Dashboard → revertir merge en `stg` (Vercel redespliega el previo); n8n → re-import del export baseline `stg@40fe572` sobre los mismos IDs + restore de BD STG desde el backup del punto 3.

## 8. Evidencia sanitizada y confirmación cero DDL/migraciones/flags/secretos

- Evidencia post publicada **sanitizada** (sin PII, sin secretos, sin IDs de credencial — solo conteos, fingerprints, resultado del runner), con el estándar de redacción por vocabulario cerrado ya validado en `4e2118c`.
- **Confirmación explícita:** este checkpoint NO ejecuta DDL, NO migraciones, NO configura flags, NO provisiona secretos ni origins. Si algo de eso resultara necesario, es checkpoint aparte.

## 9. C2 fuera — límite explícito

Este checkpoint **instala y verifica C1**. NO ejecuta la matriz núcleo Dual M1–M6 (C2), NO E2E vivo, NO `dual`, NO activación de tráfico. C2 requiere su propio GO del accountable, posterior y separado.

---

**Estado:** borrador NO ejecutable. Pendiente de: (a) OK de Alberto para publicarlo en #132; (b) revisión del accountable; (c) comentario explícito de GO del accountable en #132 antes de cualquier ejecución.
