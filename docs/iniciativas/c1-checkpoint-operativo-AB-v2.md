# Checkpoint operativo C1 (A+B) — HYL-WAI#132 · NO ejecutable

> Sobre el candidato A+B **`464dbd497a3653404c228ddc4aee4b88a44c2d1b`** (verificado independiente: 231/231, runner OK, inercia confirmada — la CLI real sin flags no emite ni un PUT/POST/DELETE). Comandos literales = salida verbatim de la CLI (`node scripts/c1/tools/instalar-clones.js`, se regeneran del plan). **Este documento NO es GO.** Su ejecución exige comentario explícito posterior del accountable en #132. **C2 fuera.**

## 0. Objeto
Instalar y **verificar** las dos barreras C1 en STG:
- **Barrera A** — plano vivo default-deny por `PUT` de contención sobre los 7 workflows vivos (alcanzable-sin-gate 56→0).
- **Barrera B** — 7 clones aislados `active:false` (`POST` nuevos; el ID lo asigna n8n, se acredita por GET).

No ejecuta C2 ni prueba viva Dual. No toca PROD. **No muta ninguna BD** (ni la SQLite interna de n8n ni el Postgres del bot) → **sin backup/restore de BD**.

## 1. SHAs, targets e IDs
| Frente | Artefacto | Efecto en esta ventana |
|---|---|---|
| n8n | PR `aibanez82/Agente-n8n#3` @ `464dbd497` · base `stg@40fe572` · n8n pin **2.28.7** (`955be3ef`) | instala A+B en `n8n-xlqk.srv1810257.hstgr.cloud` |
| Dashboard | Vercel proyecto **`insurmind-dashboards`**, env **stg**, deployment de PR #2 `1373d1a` | **CERO acción** — congelado |
| Django | app **`hyl-wai-stg`**, release activo esperado **v212** (`4f0e7416`). PR #145 `c373ab11` fuera, sin merge | **CERO acción** — solo `manage.py migrate --check --noinput` (verificación de que no hay migración pendiente) |

**7 workflows vivos — barrera A opera por `PUT`; fingerprint anti-TOCTOU (pre-imagen del vivo, guarda inmediata previa a cada PUT):**

| # orden PUT (Main 1º, callees 6–7: invariantes) | ID vivo | fingerprint anti-TOCTOU |
|---|---|---|
| 1 Bot principal | `dNqtM20ij6ecZYAX` | `9380710bba25bc2df7de4ce1feff2f1732eb087b62c1a7cf519f2b330c9dc4bc` |
| 2 Atención Humana | `HAMIxqhZd2TEy6NB` | `28249f3883d4e31ef9ff04277fc9f8766b3ec8e9a37aa36385f482d3c790dc64` |
| 3 Payment Confirmation | `Ob5JYHYbc23SLp0A` | `3ebada900d3ef3c5d79a6619661f85426987c638774a68a33d497714dbeee9c2` |
| 4 Metepec Liberar | `biWlbwq4NQdZadwg` | `064000c2666461e69296aa6c8981bbbf87bafdf75864ef557c7b18fbb9fb0e9c` |
| 5 Retomar Conversación | `nYRaRzU83qDLuEWI` | `b671934c0c9776123cdaf2be30106a0db5ab165a59a1f9320f395031f2a76313` |
| 6 Issue Policy Guard (callee) | `PuogahK4qv9YOiF4` | `fa40ade2a5d24de7cc3483e984bb51a516c10bed429ae9048561ae33fde5aef7` |
| 7 METEPEC Registrar (callee) | `liBCn3yBegedmYuR` | `5e3dc266bc4090d88af4d23d598906222525f522e0b7a3969de94699706d773a` |

> La verificación **post-`PUT`** de la barrera A NO es un fingerprint global: la hace la CLI **por partes** por GET (contenido + `settings` por semántica de fusión + `active` + publicación + `activeVersionId`), porque n8n fusiona settings y el objeto final no es predecible desde el payload.

**7 clones barrera B — nombre destino + fingerprint destino (verificado por GET post-`POST`, con `active===false`):**

| origen vivo | nombre destino | fingerprint destino |
|---|---|---|
| `dNqtM20ij6ecZYAX` | C1-AISLADO — WhatsApp Insurance Quotation Bot_stg | `934148533ce98baa09efc62c4d4696d13772624e887668b098b25c10fcc19724` |
| `Ob5JYHYbc23SLp0A` | C1-AISLADO — …Payment Confirmation_stg | `97f76c7786628592bd467ae8419d79177dda32ecbe171cebdc18ef5d5e6de0ec` |
| `nYRaRzU83qDLuEWI` | C1-AISLADO — Retomar Conversacion_stg | `e2e9839f86395055aae9e85273ec2bc3f2b81df038942bf2fcf08414cec81ae8` |
| `HAMIxqhZd2TEy6NB` | C1-AISLADO — Atencion Humana (STG) | `b0de560f222b3ef364baebb1eb22234cc47842afc973ea2b7a151c614365f718` |
| `liBCn3yBegedmYuR` | C1-AISLADO — METEPEC - Registrar Lead (STG) | `238a00ec00b38752cce62d397644375ac0b2fb40cf09040ef6d4a8eca4e3858d` |
| `biWlbwq4NQdZadwg` | C1-AISLADO — Metepec Liberar (STG) | `06e07c101a29ab2ab6eb5af8acc4ded5286f66d927ba2efd91f589c8611456bc` |
| `PuogahK4qv9YOiF4` | C1-AISLADO — Issue Policy Guard (STG) | `e542ccec76bb4d2fedce974bf794b822a7e96af5b8b513f724fb327244459a76` |

## 2. Orden e distinción de verbos
`PUT` de contención (A, 7 vivos) · `POST` de clones (B, 7 nuevos) · verificación por GET · (activación NO ocurre). **Orden barrera A — llamadores primero:** invariantes verificados (Main 1º; los dos callees puros —Issue Policy Guard, METEPEC Registrar— últimos); el orden de los 4 con ingress lo computa `ordenPorDependencias` (no load-bearing) y se re-verifica contra el grafo vivo. Barrera B (7 `POST`) independiente, no toca los vivos.

## 3. Backup, fingerprints y verificación
- **NO hay backup de BD** — A+B no muta ninguna BD (ni SQLite interna de n8n —workflows/ejecuciones/credenciales— ni Postgres del bot —`whatsapp_sessions`/`n8n_chat_histories`, cred `5wlLe3gD07CLIM7U`—).
- **Antes de cada `PUT`:** guarda anti-TOCTOU con el fingerprint de §1 (`comprobar-fingerprint.js`: `0`=coincide · `1`=DISCREPANCIA → parar · `3`=INCIERTO → parar).
- **Después:** verificación **por partes** por GET, integrada en la CLI (falla si no cuadra); barrera B: GET, `active===false`, fingerprint destino = tabla.

## 4. Comandos literales (salida verbatim de la CLI), operador/guardia, ventana
```bash
# 0. PREFLIGHT DE VENTANA — modo de publicación (target-guarded, fail-closed).
#    Identifica el contenedor por IMAGEN y confirma la versión preguntando al binario (no al tag).
export C1_IMAGEN_N8N="${C1_IMAGEN_N8N:-n8nio/n8n:2.28.7}"   # ajustar si el despliegue usa otro tag
MODO_PUBLICACION="$(scripts/c1/tools/preflight-publicacion.sh)" || exit 1
echo "modo de publicación acreditado: $MODO_PUBLICACION"

# 1. GUARDA ANTI-TOCTOU — head vivo de los 7 (sólo lectura); una línea por workflow, encadenables
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/dNqtM20ij6ecZYAX" | node scripts/c1/tools/comprobar-fingerprint.js 9380710bba25bc2df7de4ce1feff2f1732eb087b62c1a7cf519f2b330c9dc4bc || exit 1
#  … (Atención Humana, Payment, Metepec Liberar, Retomar, Issue Policy Guard, METEPEC Registrar — mismos fingerprints de §1) …

# 2. DRY-RUN (no escribe nada; demuestra que el plan es el esperado)
node scripts/c1/tools/instalar-clones.js --barrera ab

# 3. BARRERA A — PUT de contención sobre los 7 vivos, orden por dependencias
C1_INSTALADOR_VIVO=1 node scripts/c1/tools/instalar-clones.js \
  --barrera a --vivo --publicacion-observada "$MODO_PUBLICACION" \
  --ventana "2026-08-03T09:30-06:00" --garante "Juan (@oilycoyote)" \
  --autorizacion "<ID del comentario de GO del accountable — existe recién al dar el GO>"

# 4. BARRERA B — POST de los 7 clones active:false
C1_INSTALADOR_VIVO=1 node scripts/c1/tools/instalar-clones.js \
  --barrera b --vivo --publicacion-observada "$MODO_PUBLICACION" \
  --ventana "2026-08-03T09:30-06:00" --garante "Juan (@oilycoyote)"

# 5. VERIFICACIÓN — la CLI hace GET post de cada acción; fingerprints destino en §1 (barrera B)
# 6. ROLLBACK por acción, orden inverso (A: repone preimagen con GET/guarda previa; B: borra sólo clones creados)
C1_INSTALADOR_VIVO=1 node scripts/c1/tools/instalar-clones.js \
  --barrera ab --vivo --rollback --publicacion-observada "$MODO_PUBLICACION" \
  --ventana "2026-08-03T09:30-06:00" --garante "Juan (@oilycoyote)" --autorizacion "<ID del GO>"
```
> **Inercia (verificado):** cualquiera de las 5 guardas que falte → DRY-RUN, cero escrituras. Sin `--vivo`, sin `C1_INSTALADOR_VIVO=1`, sin cliente-de-contención, sin `{ventana, garante}`, o sin `n8n_esperado` acreditado (versión **y** modo de publicación) → no se emite ni un PUT/POST/DELETE.
> **`--autorizacion`** es el ID del **propio comentario de GO** del accountable; por definición sólo existe al darlo — se rellena en el momento de ejecutar, no es un pendiente del checkpoint.

- **Operador:** Alberto. **Guardia doble:** Arquitecto (stop conditions en vivo vía monitores/API) + **Juan** (`@oilycoyote`). **Suplente:** Juan. Cualquiera invoca stop.
- **Ventana:** **lunes 3 ago 2026, 09:30 CDMX (15:30 UTC)** (propuesta de Alberto; a confirmar por Juan).

## 5. Prechecks ACTUALES en la ventana (no el C0 histórico)
- 0 ejecuciones n8n en vuelo (GET `/executions?status=running`).
- Followups STG apagados; ningún Schedule Trigger STG activo.
- **Exclusión operativa concreta:** instancia n8n STG única (`instanceCount 1`, un main leader, `executionMode regular` — no hay segundo proceso que edite en paralelo; el único editor concurrente es **una persona con la UI abierta**). El **garante confirma que nadie tiene la UI de STG abierta** al abrir la ventana y **re-comprueba antes del `PUT` del Main**.
- WhatsApp Send sin credencial de prod (los 2 nodos sin credencial a propósito).

## 6. Versión/config de n8n
- **Versión `2.28.7`** — observada por Alberto en About n8n de la instancia STG (evidencia + debug info) y re-verificada contra el tag `n8n@2.28.7` (`955be3ef`). El pin protege 5 hechos (fichero:línea en `c1.config.json`).
- **Modo de publicación:** el instalador **EXIGE `sincrona`** (su verificación asume que `activeVersionId` cambia en el acto tras el `PUT`; con publicación asíncrona esa verificación deja de ser concluyente). El valor **observado** se acredita **en la ventana** por el preflight target-guarded (§4 paso 0) y entra por `--publicacion-observada`; si la ventana acredita `asincrona`, la CLI **se niega**. Sin salida del preflight → variable ausente → default `false` → síncrona (el caso bueno).

## 7. Stop conditions, `uncertain`, RTO, rollback
- **Stop:** anti-TOCTOU `1`/`3`; verificación por partes que no cuadre; `settings` ajenos aparecidos; edición concurrente/UI abierta; ejecución en vuelo; `n8n_esperado` incompleto/distinto; publicación `asincrona`.
- **`uncertain` sin retry ciego** en ida Y vuelta: `PUT` que aplica y pierde respuesta → GET lo acredita; que no aplicó → `fallido`; rollback no acreditable → `incierto`. Ninguno se reintenta solo.
- **RTO:** < 30 min/frente.
- **Rollback por acción (NO global):** A → preimagen por workflow en orden inverso, sólo lo aplicado, con GET/guarda previa; **NO restaura el `versionId`**. B → `DELETE` sólo de los clones creados y confirmados por el journal. **NUNCA** reimport de los 7 vivos ni restore de BD (la guarda del cliente prohíbe borrar/activar los 7 IDs vivos).

## 8. Evidencia sanitizada y cero DDL/migraciones/flags/secretos
- Evidencia post sanitizada (conteos, fingerprints, resultado; sin PII/secretos/IDs de credencial).
- **Confirmación:** NO DDL, NO migraciones, NO flags, NO secretos/origins. Django ya en `stg@4f0e741` (v212; solo `migrate --check`).

## 9. C2 fuera
Instala/verifica C1 (A+B). NO M1–M6 (C2), NO E2E vivo, NO `dual`, NO activación de tráfico. C2 requiere GO posterior y separado.

---
**Pendiente de:** (a) revisión + GO del accountable en #132. *(El valor de publicación se acredita en la ventana por el preflight, no antes; el `--autorizacion` es el propio GO.)*
**Fuera de alcance, para el rollout a PROD:** PROD corre n8n **2.6.3** (22 minors bajo STG); 2 de los 5 hechos del instalador no existen en 2.6.3 → los artefactos no son portables a PROD tal cual. No es C1.
