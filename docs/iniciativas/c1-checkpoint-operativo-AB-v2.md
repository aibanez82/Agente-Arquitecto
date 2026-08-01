# Checkpoint operativo C1 (A+B) — HYL-WAI#132 · NO ejecutable

> Sobre el candidato A+B **`1c30a00b6`** (verificado independiente: 248/248, runner OK, inercia confirmada; rollback recuperable, STOP con exit≠0, target guard atado a `N8N_BASE_URL`). Comandos = salida verbatim de la CLI. **Este documento NO es GO.** Su ejecución exige comentario explícito posterior del accountable en #132. **C2 fuera.**

## 0. Objeto
Instalar y **verificar** las dos barreras C1 en STG, en **una corrida, orden B→A**:
- **Barrera B** (primero) — 7 clones aislados `active:false` (`POST`; ID asignado por n8n, acreditado por GET).
- **Barrera A** (después) — plano vivo default-deny por `PUT` de contención sobre los 7 vivos (56→0). *B va antes: los clones salen de los exports congelados y su guarda anti-TOCTOU exige que el vivo siga coincidiendo con el freeze; si A fuera antes, sus gates moverían los vivos y esa comprobación fallaría. Si B no queda limpia, la CLI PARA y no toca ni un workflow vivo.*

No ejecuta C2 ni prueba viva Dual. No toca PROD. **No muta ninguna BD** → sin backup/restore de BD.

## 1. SHAs, targets e IDs
| Frente | Artefacto | Efecto |
|---|---|---|
| n8n | PR `aibanez82/Agente-n8n#3` @ `1c30a00b6` · base `stg@40fe572` · n8n pin **2.28.7** (`955be3ef`) | instala A+B en `n8n-xlqk.srv1810257.hstgr.cloud` |
| Dashboard | Vercel **`dashboard-seguroautoqualitas`** (`prj_CU5Qqp3BK2B31HVytLeEOBuSlnrU`, scope `albers-projects-52295059`), deployment inmutable **`dpl_E5yQGegYSXZqbNy38TBi4j69U2gK`** (Preview, domain `dashboard-seguroautoqualitas-8xb7zsprm-albers-projects-52295059.vercel.app`) = commit `1373d1a` verificado en panel | **CERO acción** |
| Django | app **`hyl-wai-stg`**, release activo esperado **v212** (`4f0e7416`). PR #145 fuera, sin merge | **CERO acción** — solo `migrate --check` |

**7 workflows vivos — barrera A por `PUT`; fingerprint anti-TOCTOU (guarda previa a cada PUT):**

| # orden PUT | ID vivo | fingerprint anti-TOCTOU (pre-imagen del vivo) | hash del artefacto ENVIADO (contenido del PUT de contención) |
|---|---|---|---|
| 1 Bot principal | `dNqtM20ij6ecZYAX` | `9380710bba25bc2df7de4ce1feff2f1732eb087b62c1a7cf519f2b330c9dc4bc` | `8f59f647297a3f1f91729ec96f60c84a1e84300b33a154c41464d9088d90605b` |
| 2 Atención Humana | `HAMIxqhZd2TEy6NB` | `28249f3883d4e31ef9ff04277fc9f8766b3ec8e9a37aa36385f482d3c790dc64` | `d04386b12828a87a6f8d8e09ef30fe11a5bd990f76fbbd8d9455cdee4ed76e0e` |
| 3 Payment Confirmation | `Ob5JYHYbc23SLp0A` | `3ebada900d3ef3c5d79a6619661f85426987c638774a68a33d497714dbeee9c2` | `e0671fa632c9832a3c3ea5ea92f83b9aba7c66d1f5c49747f992177cbd942a05` |
| 4 Metepec Liberar | `biWlbwq4NQdZadwg` | `064000c2666461e69296aa6c8981bbbf87bafdf75864ef557c7b18fbb9fb0e9c` | `3d6c6ab46ea02f6d59b4b2c5d69d0c6c0268b0f5b88d691f4354ea7c2c2c5d61` |
| 5 Retomar Conversación | `nYRaRzU83qDLuEWI` | `b671934c0c9776123cdaf2be30106a0db5ab165a59a1f9320f395031f2a76313` | `a22e2cb4638b59676387eb575cb624d953b72c0820096d5f0d575e23add4340a` |
| 6 Issue Policy Guard (callee) | `PuogahK4qv9YOiF4` | `fa40ade2a5d24de7cc3483e984bb51a516c10bed429ae9048561ae33fde5aef7` | `7026992ddbcf78978f79e9a3a3c3256f8963e2480bc2e1858580ed71332f3ed0` |
| 7 METEPEC Registrar (callee) | `liBCn3yBegedmYuR` | `5e3dc266bc4090d88af4d23d598906222525f522e0b7a3969de94699706d773a` | `4279b82ab271508c0be2448ff02d4dd6279595b0d7e49c8604fb49493d0c8417` |

(El *hash del artefacto enviado* es lo que el `PUT` de contención transmite; la verificación **post**-`PUT` es por partes por la fusión de settings — ver §3.)

Verificación post-`PUT` (A): **por partes** por GET (contenido + settings por fusión + active + publicación + activeVersionId), no fingerprint global.

**7 clones barrera B — fingerprint destino (GET post-`POST`, `active===false`):** Bot `934148533ce98baa09efc62c4d4696d13772624e887668b098b25c10fcc19724` · Payment `97f76c7786628592bd467ae8419d79177dda32ecbe171cebdc18ef5d5e6de0ec` · Retomar `e2e9839f86395055aae9e85273ec2bc3f2b81df038942bf2fcf08414cec81ae8` · Atención Humana `b0de560f222b3ef364baebb1eb22234cc47842afc973ea2b7a151c614365f718` · METEPEC Registrar `238a00ec00b38752cce62d397644375ac0b2fb40cf09040ef6d4a8eca4e3858d` · Metepec Liberar `06e07c101a29ab2ab6eb5af8acc4ded5286f66d927ba2efd91f589c8611456bc` · Issue Policy Guard `e542ccec76bb4d2fedce974bf794b822a7e96af5b8b513f724fb327244459a76`.

## 2. Orden e distinción de verbos
`POST` de clones (B, primero) · `PUT` de contención (A, después) · verificación por GET · (activación NO ocurre). **Orden A — llamadores primero:** Main 1º y los dos callees puros (Issue Policy Guard, METEPEC Registrar) últimos (invariantes verificados); el orden de los 4 con ingress lo computa `ordenPorDependencias` (no load-bearing), re-verificado contra el grafo vivo.

## 3. Backup, fingerprints y verificación
- **NO hay backup de BD** — A+B no muta ninguna BD (ni SQLite interna de n8n ni Postgres del bot —`whatsapp_sessions`/`n8n_chat_histories`, cred `5wlLe3gD07CLIM7U`—).
- Anti-TOCTOU antes de cada `PUT` (§1); `comprobar-fingerprint.js`: `0`=coincide · `1`=DISCREPANCIA → parar · `3`=INCIERTO → parar.
- Verificación post por partes (A) / GET + `active===false` + fingerprint destino (B), integrada en la CLI (falla si no cuadra).

## 4. Comandos literales (salida verbatim de la CLI)
```bash
# 0. PREFLIGHT — modo de publicación (target-guarded: contenedor por imagen + versión al binario)
export C1_IMAGEN_N8N="${C1_IMAGEN_N8N:-n8nio/n8n:2.28.7}"
MODO_PUBLICACION="$(scripts/c1/tools/preflight-publicacion.sh)" || exit 1

# 1. GUARDA ANTI-TOCTOU — head vivo de los 7 (sólo lectura)
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/dNqtM20ij6ecZYAX" | node scripts/c1/tools/comprobar-fingerprint.js 9380710bba25bc2df7de4ce1feff2f1732eb087b62c1a7cf519f2b330c9dc4bc || exit 1
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/HAMIxqhZd2TEy6NB" | node scripts/c1/tools/comprobar-fingerprint.js 28249f3883d4e31ef9ff04277fc9f8766b3ec8e9a37aa36385f482d3c790dc64 || exit 1
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/Ob5JYHYbc23SLp0A" | node scripts/c1/tools/comprobar-fingerprint.js 3ebada900d3ef3c5d79a6619661f85426987c638774a68a33d497714dbeee9c2 || exit 1
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/biWlbwq4NQdZadwg" | node scripts/c1/tools/comprobar-fingerprint.js 064000c2666461e69296aa6c8981bbbf87bafdf75864ef557c7b18fbb9fb0e9c || exit 1
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/nYRaRzU83qDLuEWI" | node scripts/c1/tools/comprobar-fingerprint.js b671934c0c9776123cdaf2be30106a0db5ab165a59a1f9320f395031f2a76313 || exit 1
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/PuogahK4qv9YOiF4" | node scripts/c1/tools/comprobar-fingerprint.js fa40ade2a5d24de7cc3483e984bb51a516c10bed429ae9048561ae33fde5aef7 || exit 1
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/liBCn3yBegedmYuR" | node scripts/c1/tools/comprobar-fingerprint.js 5e3dc266bc4090d88af4d23d598906222525f522e0b7a3969de94699706d773a || exit 1

# 2. DRY-RUN (no escribe nada)
node scripts/c1/tools/instalar-clones.js --barrera ab

# 3. INSTALACIÓN A+B en UNA corrida (orden B→A impuesto por la herramienta). Anota el run-id.
#    exit 0 = verde; exit != 0 = errores/inciertos -> NO seguir, mirar el journal. Si B no queda limpia, NO toca los vivos.
C1_INSTALADOR_VIVO=1 node scripts/c1/tools/instalar-clones.js \
  --barrera ab --vivo --publicacion-observada "$MODO_PUBLICACION" \
  --ventana "2026-08-03T09:30-06:00" --garante "Juan (@oilycoyote)" \
  --autorizacion "<ID del comentario de GO del accountable — existe recién al darlo>"

# 4. CORRIDAS (de dónde revertir, también tras un corte)
node scripts/c1/tools/instalar-clones.js --listar-corridas

# 5. VERIFICACIÓN — la CLI hace GET post de cada acción; fingerprints destino B en §1.
# 6. ROLLBACK — consume una corrida CONCRETA; nunca re-aplica la ida; recupera una ventana cortada.
#    Orden inverso: borra clones (B), luego repone preimágenes de los vivos (A), con GET/guarda previa.
C1_INSTALADOR_VIVO=1 node scripts/c1/tools/instalar-clones.js \
  --barrera ab --vivo --rollback-from "<run-id>" --publicacion-observada "$MODO_PUBLICACION" \
  --ventana "2026-08-03T09:30-06:00" --garante "Juan (@oilycoyote)" --autorizacion "<ID del GO>"
```
> **Inercia (verificado):** falta cualquiera de las 5 guardas (`--vivo`, `C1_INSTALADOR_VIVO=1`, cliente-de-contención, `{ventana, garante}`, `n8n_esperado` acreditado) → DRY-RUN, cero escrituras. **Target guard:** la CLI exige `N8N_BASE_URL == https://n8n-xlqk.srv1810257.hstgr.cloud`; con un host ajeno **no escribe nada** (`n8n-base-url-apunta-a-otro-host`). **`--autorizacion`** = ID del propio comentario de GO (existe al darlo, no es pendiente del checkpoint).

- **Operador:** Alberto. **Guardia:** Arquitecto (stop conditions en vivo vía monitores/API) + **Juan** (`@oilycoyote`, guardia activo desde #132). **Suplente (decisión de Alberto):** se reconoce **operador único** — no hay un segundo humano operativo en el ecosistema, así que en vez de un suplente ficticio se declara: operador Alberto, **Arquitecto como segundo técnico** (puede invocar stop y ejecutar rollback bajo dirección de Alberto) y Juan como guardia. `@oilycoyote`, indica si aceptas esta figura o requieres otra cosa.
- **Ventana:** **lunes 3 ago 2026, 09:30 CDMX (15:30 UTC)** — propuesta de Alberto; ⏳ **`@oilycoyote`, confirma para hacerla definitiva.**

## 5. Prechecks ACTUALES en la ventana (literales, no el C0 histórico)
```bash
# a) 0 ejecuciones en vuelo
test "$(curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/executions?status=running&limit=250" | jq '.data|length')" = 0 || { echo "STOP: ejecuciones en vuelo"; exit 1; }
# b) ningún Schedule Trigger activo
test "$(curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows?active=true" | jq '[.data[]|select((.nodes[]?.type//"")|test("scheduleTrigger|cron";"i"))]|length')" = 0 || { echo "STOP: schedule activo"; exit 1; }
# c) producers Django (followups/checkpoints) apagados en STG
heroku config --app hyl-wai-stg | grep -E "WHATSAPP_(FOLLOWUPS|CHECKPOINT)_" # todos false/dry-run, o STOP
# d) producer WhatsApp: los 2 nodos Send del bot vivo sin credencial de prod (no puede emitir)
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/dNqtM20ij6ecZYAX" | jq -e '[.nodes[]|select(.type|test("whatsApp";"i"))|.credentials]|all(.==null or .=={})' >/dev/null || { echo "STOP: WhatsApp Send con credencial"; exit 1; }
# e) producer webhook proactivo (Dashboard->n8n): Dashboard congelado, GATE_*/ALLOWED_ORIGINS sin provisionar -> fail-closed (cero acción, §1)
# f) destinos/conectores externos: los DENIEGA la barrera A (es su objeto); se re-verifica por GET post-PUT (§3)
# g) exclusión operativa: instancia STG única -> el garante confirma que NADIE tiene la UI de STG abierta al abrir la ventana, y RE-COMPRUEBA antes del PUT del Main.
# h) Django (target-guarded): release activo == v212 esperado, y sin migración pendiente
test "$(heroku releases --app hyl-wai-stg -n1 --json | jq -r '.[0].version')" = "v212" || { echo "STOP: release Django != v212"; exit 1; }
heroku run --app hyl-wai-stg -- python manage.py migrate --check --noinput
```

## 6. Versión/config de n8n
- **Versión `2.28.7`** — observada por Alberto en About n8n de STG (evidencia + debug info), re-verificada contra el tag `955be3ef`; protege 5 hechos (fichero:línea en `c1.config.json`).
- **Modo de publicación:** la CLI EXIGE `sincrona` (su verificación asume `activeVersionId` inmediato tras el `PUT`); el valor observado se acredita en la ventana por el preflight target-guarded (§4 paso 0); si `asincrona`, la CLI se niega. Sin salida → default `false` → síncrona.

## 7. Stop conditions, `uncertain`, RTO, rollback
- **Stop / exit≠0:** anti-TOCTOU `1`/`3`; verificación que no cuadre; `settings` ajenos; edición concurrente/UI abierta; ejecución en vuelo; `n8n_esperado` incompleto/distinto; publicación `asincrona`; `N8N_BASE_URL` ajeno; **B no limpia → no se toca el vivo**. La CLI cierra no-verde y **sale != 0**; verde solo si todo cuadró.
- **`uncertain` sin retry ciego** (ida y vuelta): PUT que aplica y pierde respuesta → GET lo acredita; que no aplicó → `fallido`; rollback no acreditable → `incierto`.
- **RTO:** < 30 min. **Rollback por corrida (`--rollback-from <run-id>`, estado durable que sobrevive un corte):** borra clones (B) y repone preimágenes (A) en orden inverso, con GET/guarda previa; **NO restaura el `versionId`**; NUNCA reimport de los 7 vivos en bloque ni restore de BD (la guarda del cliente prohíbe borrar/activar los 7 IDs vivos).

## 8. Evidencia sanitizada y cero DDL/migraciones/flags/secretos
Evidencia post sanitizada (conteos, fingerprints, resultado; sin PII/secretos/IDs de credencial). NO DDL, NO migraciones, NO flags, NO secretos/origins. Django ya en `stg@4f0e741` (v212; solo `migrate --check`).

## 9. C2 fuera
Instala/verifica C1 (A+B). NO M1–M6 (C2), NO E2E vivo, NO `dual`, NO activación. C2 requiere GO posterior y separado.

---
**Pendiente de:** aceptación de `@oilycoyote` a (a) la ventana lunes 3 ago 09:30 CDMX y (b) la figura de operador único; luego su GO. Todo lo demás, definitivo.
**Fuera de alcance, para PROD:** PROD corre n8n **2.6.3** (22 minors bajo STG); 2 de los 5 hechos del instalador no existen en 2.6.3 → artefactos no portables a PROD tal cual. No es C1.
