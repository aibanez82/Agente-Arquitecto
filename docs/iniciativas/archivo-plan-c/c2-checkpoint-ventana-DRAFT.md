> **SUPERSEDED (4 ago 2026):** el plan C2–C9 fue sustituido por Contract-First S1–S5 (enmienda `#140 c.5174994247`). Este doc queda como registro histórico; el candidato `1161dcf` se conserva solo como insumo. Prep vigente: `docs/iniciativas/s2-prep-offline.md`.

# C2 · Checkpoint de VENTANA (DRAFT) — matriz núcleo Dual, corrida única `shadow`

> **DRAFT preparado por el Arquitecto; candidato entregado `40d031b` a reauditoría del monitor v3 (bridge #132 `5160065195`).** No es GO ni activación.
> Se finaliza (SHA/hashes definitivos + id de "condiciones satisfechas") cuando el monitor dé PASS técnico de C2.
> **Aplica la lección dura de C1: el operador ejecuta el tramo de precondición COMPLETO — ningún paso se omite.**
> Estructura conforme a `5154752604 §4` (los 7 puntos) + `5154662330` (7 condiciones de autorización condicional).

## 1. Identidad congelada (a fijar en el PASS)
- n8n C2: `aibanez82/Agente-n8n@40d031b` (rama `feature/c2-matriz-nucleo-dual`; informe en `main` `80e9591e5`). Cierra los 4 P1 de `5159817682` + decisión `5159942624` (M5 opción B + S1-S11). C1 (`416d1987`) intacta.
- Hashes verificados por el Arquitecto (tarball limpio): `dual-core-c2.json 4d34e889…`, `core-matrix.json da8b64c3…`. M5: huella espejo `723e363…` / fuente propuesta `575167b4…`. **Verificación independiente:** C2 99/99, C1 377/377, `--simular` exit 0 (8 bloques verdes), cleanup 18 por lista exacta.
- **Dependencia de ventana (bloqueante M5 vivo):** `clones-con-fix-m5` — los 7 clones de `c1-20260802T051054-0453` se congelaron ANTES del fix; la ventana necesita clones construidos con la fuente propuesta `575167b4…`. Acción viva NO autorizada aún.
- Plano: los 7 clones aislados de la corrida C1 `c1-20260802T051054-0453`, resueltos **por NOMBRE** `C1-AISLADO — …`. IDs vivos reales (verificados): Bot `w8Nzwmyb0WvNhhNN` · Payment `8XGTTULot5Lgl0Kg` · Retomar `CfdYS9tuUwHV6dCy` · Atención Humana `m7W48rrpa6u4RggL` · Metepec Liberar `jamPPWpAyA4OygQc` · Metepec Registrar `cmHfIkDFqmeO4m99` · Issue Policy `8vl0xaVm0fMkUBZN`. Todos `active:false`.
- Dashboard `1373d1a` / Django `hyl-wai-stg` `4f0e7416`: cero acción.

## 2. Precondición dura — YA VERIFICADA (esquema objetivo en STG)
`whatsapp_sessions` de STG **sin índice único de teléfono** (verificado read-only, `pg_indexes`) + columnas objetivo presentes (`metepec_derived_at`/`human_takeover_control_id`/`metepec_op_lock_id`/`status`/`conversation_phase`) → **esquema OBJETIVO**. C2 puede sembrar; S3/S4 comparten teléfono. **Re-acreditar en ventana antes del 1er INSERT.**

## 3. TRAMO DE PRECONDICIÓN COMPLETO (obligatorio, en orden — la lección de C1)
El operador ejecuta y **pega la evidencia de CADA paso**; nada se da por hecho:
1. **Target/versión:** `N8N_BASE_URL` = STG exacto, clave 200. Django `hyl-wai-stg` release `4f0e7416`.
2. **Guardas inmediatas frescas:** 0 ejecuciones en vuelo; UI n8n STG cerrada (atestación humana); Alberto disponible; los 7 clones `active:false` por GET; C1 sin drift (fingerprints vivos = freeze).
3. **Productores/destinos (como en C1, frescos):** Django followups `false/false/true`; Dashboard default-deny (opción A); Meta = sink físico; Humano/Metepec cerrados.
4. **M0 pre (`verify-final-get-only.js --fase pre`):** SHA/tree/manifests/hashes = freeze; modo `shadow`; plano C1 + fingerprints; cero drift; root/activeVersion = manifest; 7 clones por nombre e inactivos.
5. **Esquema objetivo re-acreditado** (§2).
6. **`--preflight`:** las 9 consultas de **cero colisiones** (cotizaciones `990201-990210`, leads `990211-990221`, conversaciones `waq_9902%`) verdes antes del 1er INSERT.

**Solo con TODO lo anterior en verde → la corrida.**

## 4. Corrida única (`shadow`, un solo `--execute`)
```bash
export VENTANA="sync-inmediata-c2-<autorizacion>"  GARANTE="Alberto-@aibanez82"  AUTORIZACION="<id de condiciones-satisfechas del monitor / 5154662330>"
node scripts/c2/run-core-matrix.js --preflight --target stg --expect-mode shadow --manifest <sha256> --fixtures <sha256> --json-out <ruta>
node scripts/c2/run-core-matrix.js --execute  --one-shot --target stg --expect-mode shadow --run-id <nuevo> --manifest <sha256> --fixtures <sha256> --json-out <ruta>
node scripts/c2/verify-final-get-only.js --target stg --run-id <mismo> --fase post --manifest <sha256> --json-out <ruta>
node scripts/c2/cleanup-run.js --run-id <mismo> --manifest <sha256> --verify
```
Ejecuta M0-M8. **Meta = sink físico; cero conectores reales; cero PROD; Humano/Metepec cerrados.** Un solo `--execute`.

## 5. STOP / RTO / rollback (de `5154752604 §4` + canónico)
STOP al primer P0/P1, cruce, `updated_count>1`, más de una `active`, conector no allowlisted, claim/derivación, drift, cleanup incompleto o `uncertain`. **No se compensa con otra corrida.**
Rollback exacto del mismo run-id: denegar/desactivar solo ingress del plano C2, reconciliar por GET, `cleanup-run.js` por el mismo run-id, clones C2 inactivos, fingerprints verdes; **no tocar los 7 vivos**. RTO: deny/STOP ≤5 min, restore/reconciliación ≤20 min.

## 6. Operador y evidencia
Operador humano **Alberto** (o el Agente QA con handoff — el plan C2 designa QA para el E2E vivo); Arquitecto vigila STOP. Al terminar: evidencia sanitizada por bloque (resultado, IDs sintéticos del run-id, efectos observados, confirmación de **cero efecto real** + `efectos_reales=0`, conteos de cleanup por tabla, run-id, tiempos), sin secretos/PII. Ambos run-id (si aplica pausa) o el run-id de matriz + el journal.

## 7. Pendiente para finalizar (al PASS del monitor)
- Fijar `<SHA-PASS>` + hashes definitivos + `--autorizacion` (id de "condiciones de autorización humana satisfechas").
- Handoff a QA (si ejecuta QA) con esta secuencia exacta.
- Resolver el hallazgo M5 (`5159302243`) si Juan lo marca bloqueante (hoy va rodeado, no bloquea).
