# Checkpoint operativo C1 (A+B) — HYL-WAI#132 · NO ejecutable

> Reescrito tras el FAIL `5149896236` (borrador de trabajo; **NO posteado aún** — pendiente de las dos piezas marcadas ⏳ y del OK de Alberto). Sobre el candidato A+B `601a845` (219/219 verificado; **el SHA se actualizará al del instalador vivo real cuando el ejecutor lo entregue**). **Este documento NO es GO.** Su ejecución exige comentario explícito posterior del accountable en #132. **C2 fuera.**

## 0. Objeto
Instalar y **verificar** las dos barreras C1 en STG:
- **Barrera A** — plano vivo default-deny por `PUT` de contención sobre los 7 workflows vivos (alcanzable-sin-gate 56→0).
- **Barrera B** — 7 clones aislados `active:false` (`POST` nuevos; el ID lo asigna n8n).

No ejecuta C2 ni prueba viva Dual. No toca PROD.

## 1. SHAs, targets e IDs

| Frente | Artefacto | Efecto en esta ventana |
|---|---|---|
| n8n | PR `aibanez82/Agente-n8n#3` @ `601a845` ⏳(→ SHA del instalador vivo real) · base `stg@40fe572` · n8n pin **2.28.7** (`955be3ef`) | instala A+B en instancia n8n STG `n8n-xlqk.srv1810257.hstgr.cloud` |
| Dashboard | Vercel proyecto **`insurmind-dashboards`**, environment **stg**, deployment de PR #2 `1373d1ab95f2e18f4758ad7d1d571e9dcf5f6fcc` | **CERO acción** — congelado, no forma parte de esta instalación |
| Django | app **`hyl-wai-stg`**, release activo esperado **v212** (`4f0e7416`, C1 ya efectivo). PR #145 `c373ab11` = tooling CAS, **fuera**, sin merge | **CERO acción** — solo `manage.py migrate --check --noinput` (target-guarded, verificación de que no hay migración pendiente) |

**7 workflows vivos — barrera A opera por `PUT`; fingerprint anti-TOCTOU (del vivo) + fingerprint del artefacto de contención (lo que se deja):**

| # (orden PUT) | ID vivo | fingerprint vivo (anti-TOCTOU) | fingerprint artefacto contenido |
|---|---|---|---|
| 1 Bot principal | `dNqtM20ij6ecZYAX` | `9380710bba25bc2df7de4ce1feff2f1732eb087b62c1a7cf519f2b330c9dc4bc` | `e405aff5d1800b69088ea8f3f0c71988f3bad197685c0982bb73d6718dddcc95` |
| 2 Atención Humana | `HAMIxqhZd2TEy6NB` | `28249f3883d4e31ef9ff04277fc9f8766b3ec8e9a37aa36385f482d3c790dc64` | `a967cb49aa47760b7c18bf9f5573d524a7c50da09ffbe0a80de17d4e35220230` |
| 3 Payment Confirmation | `Ob5JYHYbc23SLp0A` | `3ebada900d3ef3c5d79a6619661f85426987c638774a68a33d497714dbeee9c2` | `637b128005d2e165edab995f08106a6ede6d90145735484561bee0a0f997eb18` |
| 4 Metepec Liberar | `biWlbwq4NQdZadwg` | `064000c2666461e69296aa6c8981bbbf87bafdf75864ef557c7b18fbb9fb0e9c` | `1951fc7116f30bbe323083d7d78ab409c64088a4348d6b23789411906c196d73` |
| 5 Retomar Conversación | `nYRaRzU83qDLuEWI` | `b671934c0c9776123cdaf2be30106a0db5ab165a59a1f9320f395031f2a76313` | `e968acb815180ca72f0fa510e99a1e90462a733c7a29648a10a248427281a214` |
| 6 Issue Policy Guard (callee) | `PuogahK4qv9YOiF4` | `fa40ade2a5d24de7cc3483e984bb51a516c10bed429ae9048561ae33fde5aef7` | `a7aef0f23addf239836217f7736b47a6205b20539788f2db081968f92d86b02f` |
| 7 METEPEC Registrar (callee) | `liBCn3yBegedmYuR` | `5e3dc266bc4090d88af4d23d598906222525f522e0b7a3969de94699706d773a` | `ea5c327e0c1d0434dda9aedd19ca331e7f9d317a9b6f3ddca3f13e2ebdc7412a` |

**7 clones barrera B — nombre destino `C1-AISLADO — <workflow>` + fingerprint destino (el ID lo asigna n8n en el `POST`, se acredita por GET):**

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
Cuatro verbos, registrados por separado: **`PUT` de contención** (barrera A, los 7 vivos) · **`POST` de clones** (barrera B, 7 nuevos) · verificación por **GET** · (activación NO ocurre).

**Orden de contención barrera A — llamadores primero.** Invariantes **verificados** (test + grafo congelado, confirmado por el Arquitecto): el **Main va el primero** y los **dos callees puros sin ingress** (Issue Policy Guard, METEPEC Registrar) van **los últimos**. Los cuatro con ingress propio (Atención Humana, Payment, Metepec Liberar, Retomar) van en medio en el orden que **computa `ordenPorDependencias`** (determinista, no fijado por test — su orden relativo no es load-bearing: son entradas independientes). La numeración de §1 refleja esa salida del computador. Razón del invariante: gatear un callee con su llamador vivo hace que el llamador invoque un sub cerrado → el bot se rompe por dentro. **Se re-computa y re-verifica contra el grafo vivo en la ventana.**

## 3. Backup, fingerprints y verificación
- **NO hay backup de BD** — A+B **no muta ninguna base de datos** (ni la SQLite interna de n8n —workflows/ejecuciones/credenciales— ni el Postgres del bot —`whatsapp_sessions`/`n8n_chat_histories`, cred `5wlLe3gD07CLIM7U`—). El "backup/restore de BD" queda expresamente **fuera de alcance**.
- **Antes de cada `PUT`:** guarda anti-TOCTOU con el fingerprint vivo de §1 — `comprobar-fingerprint.js`: `0`=coincide · `1`=DISCREPANCIA (el vivo se movió → parar) · `3`=INCIERTO (respuesta no legible → parar). Distinguir 1 de 3.
- **Después:** verificación **por partes** (no fingerprint global — n8n fusiona `settings` y poda con `removeDefaultValues()`): contenido + `settings` (semántica de fusión) + `active` + publicación + `activeVersionId`. Barrera B: GET de los 7 clones, `active===false`, fingerprint destino = tabla. Verificación integrada en la CLI viva (no el runner offline, que no ve el plano instalado).

## 4. Comandos, operador/guardia/suplente, ventana
⏳ **Comandos literales del instalador vivo real: pendientes de la entrega del ejecutor** (`--vivo` para PUT/POST, GET post y rollback; inerte por defecto tras `C1_INSTALADOR_VIVO=1` + cliente-de-contención + `{ventana, garante}` + `n8n_esperado` completo). Se insertan aquí tal cual los entregue, con los flags reales.
- **Operador:** Alberto. **Guardia doble:** Arquitecto (stop conditions en vivo vía monitores/API) + Juan (`@oilycoyote`). **Suplente:** Juan. Cualquiera puede invocar stop.
- **Ventana:** **lunes 3 ago 2026, 09:30 CDMX (15:30 UTC)** (propuesta de Alberto; a confirmar por Juan).

## 5. Cero ejecuciones en vuelo, producers pausados, destinos denegados — prechecks ACTUALES en la ventana
Prechecks target-guarded a correr **al abrir la ventana** (no el inventario C0 histórico):
- 0 ejecuciones n8n en vuelo en STG (GET `/executions?status=running`).
- Followups STG apagados; ningún Schedule Trigger STG activo (GET workflows, verificar).
- **Exclusión operativa concreta** (instancia n8n STG única — `instanceCount 1`, un solo main leader, `executionMode regular`: no hay segundo proceso que edite en paralelo; el único editor concurrente es **una persona con la UI abierta**): el **garante confirma que nadie tiene la UI de STG abierta** al abrir la ventana y **se re-comprueba antes del `PUT` del Main**.
- WhatsApp Send sin credencial de prod (los 2 nodos WhatsApp sin credencial a propósito).

## 6. Versión/config de n8n
- **Versión: `2.28.7`** — observada por Alberto en About n8n de la instancia STG (evidencia + confirmada por el debug info) y re-verificada contra el tag `n8n@2.28.7` (`955be3ef`). El pin protege **5 hechos** (id/active readOnly; PUT con `publishIfActive`+`forceSave`; settings se FUSIONAN; `resolveNodeWebhookId` solo asigna si falta; `N8N_USE_WORKFLOW_PUBLICATION_SERVICE` default false), con fichero:línea en `c1.config.json`.
- ⏳ **Modo de publicación (`N8N_USE_WORKFLOW_PUBLICATION_SERVICE`): pendiente.** No se expone por HTTP. Pedido a Juan (que tiene el 2FA de Hostinger) correr la consulta de solo lectura (`docker inspect <contenedor> … | grep -i PUBLICATION`) — sin salida → default `false` → publicación **síncrona**. El instalador **falla en cerrado** hasta que `publicacion` esté declarada y acreditada.
- Sin auto-deploy Vercel/Heroku asociado a esta instalación (los `PUT`/`POST` van a la API de n8n, no a git).

## 7. Stop conditions, `uncertain`, RTO, rollback
- **Stop:** anti-TOCTOU `1`/`3`; verificación por partes que no cuadre; `settings` ajenos aparecidos; edición concurrente detectada; ejecución en vuelo/UI abierta; `n8n_esperado` incompleto/distinto.
- **`uncertain` sin retry ciego** en ida Y vuelta: `PUT` que aplica y pierde respuesta → GET lo acredita; que no aplicó → `fallido`; rollback no acreditable → `incierto`. Ninguno se reintenta solo.
- **RTO:** < 30 min/frente.
- **Rollback por acción (NO global):** A → reponer preimagen por workflow en orden inverso, solo lo aplicado, con GET/guarda previa; **NO restaura el `versionId`** (crea/publica otra versión con el contenido previo). B → `DELETE` solo de los clones creados y confirmados por el journal, GET previo. **NUNCA** reimport de los 7 vivos ni restore de BD.

## 8. Evidencia sanitizada y cero DDL/migraciones/flags/secretos
- Evidencia post sanitizada (conteos, fingerprints, resultado; sin PII/secretos/IDs de credencial), redacción por vocabulario cerrado.
- **Confirmación:** NO DDL, NO migraciones, NO flags, NO secretos/origins. Django ya en `stg@4f0e741` (v212, sin cambio; solo `migrate --check`).

## 9. C2 fuera
Instala/verifica C1 (A+B). NO M1–M6 (C2), NO E2E vivo, NO `dual`, NO activación de tráfico. C2 requiere GO posterior y separado.

---
**Pendiente de:** ⏳ (a) comandos reales del instalador vivo (ejecutor) — actualiza §1 SHA y §4; ⏳ (b) valor de `N8N_USE_WORKFLOW_PUBLICATION_SERVICE` (Juan) — §6; ⏳ (c) ref del contenedor para el `docker inspect` (ejecutor/Alberto); (d) OK de Alberto para postear; (e) revisión + GO de Juan.
**Fuera de alcance, apuntado para el rollout a PROD:** PROD corre n8n **2.6.3** (22 minors por debajo de STG); 2 de los 5 hechos del instalador no existen en 2.6.3 → los artefactos no son portables a PROD tal cual (o subir n8n en PROD, o reescribir para 2.6.3). No es C1.
