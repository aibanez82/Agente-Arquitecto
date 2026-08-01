# Checkpoint operativo C1 (A+B) — HYL-WAI#132 · NO ejecutable

> Preparado por el Arquitecto sobre el candidato único A+B `28167b6` (verificado independiente: 216/216, runner OK, los 6 puntos de hardening con test nombrado). Cubre el bloqueante 3 del FAIL de Juan (`5149704373`). **Este documento NO es GO.** Su ejecución exige un comentario posterior y explícito del accountable en #132. **C2 queda fuera.**

## 0. Objeto
Instalar y **verificar** las dos barreras de contención C1 en STG:
- **Barrera A** — plano vivo default-deny por `PUT` de contención sobre los 7 workflows vivos (alcanzable-sin-gate 56→0).
- **Barrera B** — 7 clones aislados `active:false` (`POST` nuevos, IDs asignados por n8n).

No ejecuta la matriz C2 ni prueba viva Dual. No toca PROD.

## 1. SHAs, targets e IDs inmutables

| Frente | Artefacto | Target |
|---|---|---|
| n8n | PR `aibanez82/Agente-n8n#3@28167b6e7e413cc3c011cb30bcf21bb61c341139` (base `stg@40fe572`) | instancia n8n STG `n8n-xlqk.srv1810257.hstgr.cloud` |
| Dashboard | PR #2 `1373d1ab95f2e18f4758ad7d1d571e9dcf5f6fcc` — **congelado, no forma parte de esta instalación** | — |
| Django | C1 ya efectivo en `stg@4f0e7416` (PASS/CI). PR #145 `c373ab11` = tooling CAS futuro, **fuera**, sin merge | `hyl-wai-stg` |

**7 workflows vivos (barrera A opera sobre ellos por `PUT`; IDs inmutables) + fingerprint anti-TOCTOU + fingerprint del artefacto de contención:**

| # | ID vivo | fingerprint vivo (anti-TOCTOU) | fingerprint artefacto contenido |
|---|---|---|---|
| 1 Bot principal | `dNqtM20ij6ecZYAX` | `9380710bba25bc2d…` | `e405aff5d1800b69…` |
| 2 Payment Confirmation | `Ob5JYHYbc23SLp0A` | `3ebada900d3ef3c5…` | `637b128005d2e165…` |
| 3 Atención Humana | `HAMIxqhZd2TEy6NB` | `28249f3883d4e31e…` | `a967cb49aa47760b…` |
| 4 Metepec Liberar | `biWlbwq4NQdZadwg` | `064000c2666461e6…` | `1951fc7116f30bbe…` |
| 5 Retomar Conversación | `nYRaRzU83qDLuEWI` | `b671934c0c977612…` | `e968acb815180ca7…` |
| 6 Issue Policy Guard (sub) | `PuogahK4qv9YOiF4` | `fa40ade2a5d24de7…` | `a7aef0f23addf239…` |
| 7 METEPEC Registrar (sub) | `liBCn3yBegedmYuR` | `5e3dc266bc4090d8…` | `ea5c327e0c1d0434…` |

**7 clones barrera B (nombre destino + fingerprint destino; el ID lo asigna n8n en el `POST` y se acredita por GET):** `C1-AISLADO — <workflow>`, fingerprints en `scripts/c1/manifests/plan-instalacion.json`. (Los `id_local_del_clon` del manifest son locales del build, NO se envían — la API rechaza `id` por `readOnly`.)

**BD STG:** `dei0jssp8kr5kv` @ RDS. **Ningún target apunta a PROD.**

## 2. Orden e distinción de verbos

Cuatro verbos distintos, registrados por separado: **`PUT` de contención** (barrera A, sobre los 7 vivos) · **`POST` de clones** (barrera B, 7 nuevos) · verificación por **GET** · (activación NO ocurre — C1 no enciende tráfico).

**Orden de contención de la barrera A — llamadores primero (computado del grafo, re-verificar en el checkpoint):**
1. `WhatsApp Insurance Quotation Bot_stg` (Main — único llamador de nivel superior) → **el primero**
2–5. los 4 con ingress propio: `Atencion Humana`, `Payment Confirmation`, `Metepec Liberar`, `Retomar Conversacion` (orden interno flexible; cada uno es entrada independiente)
6–7. **los dos callees puros sin ingress → los ÚLTIMOS:** `Issue Policy Guard`, `METEPEC - Registrar Lead`
> Razón (verificada por el Arquitecto contra el grafo congelado): gatear un callee mientras su llamador sigue vivo hace que el llamador invoque un sub ya cerrado → el bot se rompe por dentro pareciendo vivo. El orden exacto lo computa `ordenPorDependencias` y **se re-verifica contra el grafo vivo** antes de ejecutar.

La barrera B (7 `POST`) es independiente y no toca los vivos.

## 3. Backup, fingerprints y verificación
- **Antes:** backup fresco de BD STG `dei0jssp8kr5kv`. Guarda anti-TOCTOU por workflow **inmediatamente antes de cada `PUT`** (fingerprint vivo = tabla §1) — `comprobar-fingerprint.js`: `0`=coincide, `1`=DISCREPANCIA (el vivo se movió → parar), `3`=INCIERTO (respuesta no legible → parar). **Distinguir 1 de 3.**
- **Después:** verificación **por partes** (no fingerprint global — n8n fusiona `settings` y poda con `removeDefaultValues()`): contenido + `settings` (semántica de fusión) + `active` + publicación + `activeVersionId`. Barrera A: confirmar plano contenido (runner). Barrera B: GET de los 7 clones, `active===false`, fingerprint destino = tabla.

## 4. Comandos, operador/guardia, ventana
Comandos literales target-guarded (requieren `N8N_BASE_URL`/`N8N_API_KEY` STG en entorno; ninguno los imprime):
```bash
cd ~/claude-projects/Agente-n8n/scripts/c1
# Guarda anti-TOCTOU (por los 7 vivos; encadenable con &&) — solo lectura
curl -sS -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_BASE_URL/api/v1/workflows/<ID>" | node tools/comprobar-fingerprint.js <fingerprint-vivo>
# Barrera B — plan (offline, no toca nada)
node tools/instalar-clones.js
node tools/instalar-clones.js --simular --rollback   # instalación+rollback contra cliente FALSO
# Barrera A — instalación viva: NO EXPUESTA. Requiere cambio de código (exponer modo vivo) con GO escrito
#   + C1_INSTALADOR_VIVO=1 + cliente-de-contención + {ventana, garante} + n8n_esperado fijado.
# Verificación
node runner/run-c1.js   # RESULTADO: OK — plano contenido
```
- **Operador:** Alberto. **Guardia doble:** Arquitecto (stop conditions en vivo vía monitores/API) + `@oilycoyote` (activo desde #132). Cualquiera puede invocar stop.
- **Ventana:** a pactar Alberto ↔ Juan.

## 5. Cero ejecuciones en vuelo, producers pausados, destinos denegados
- 0 ejecuciones n8n en vuelo en STG antes de actuar (C0 registró 0). Followups STG apagados; ningún Schedule Trigger STG activo.
- WhatsApp Send sin credencial de prod (estado del import STG; los 2 nodos WhatsApp sin credencial a propósito). Conectores externos denegados durante la contención (es el objeto de la barrera A).

## 6. Gates/origins y efectos automáticos
- Este frente es **n8n**; no hay auto-deploy Vercel/Heroku asociado a la instalación de las barreras (el `PUT`/`POST` van a la API de n8n, no a git). `GATE_*`/`ALLOWED_ORIGINS` del Dashboard siguen sin provisionar (fail-closed) — **no se tocan en este checkpoint** (Dashboard congelado).
- ⚠️ **Versión/config de n8n (punto crítico del hardening):** la API pública v1 de n8n **no expone la versión del servidor**. El instalador exige `n8n_esperado` y **falla en cerrado** (`version:null` por defecto). **Alberto debe fijar la versión/config real de la instancia STG por otra vía** (UI, `/rest/settings` con sesión, o el despliegue) antes de exponer el modo vivo — por el `publishIfActive` posiblemente asíncrono.

## 7. Stop conditions, `uncertain`, RTO, rollback
- **Stop:** guarda anti-TOCTOU `1` o `3`; verificación por partes que no cuadre; `settings` ajenos aparecidos; edición concurrente detectada; migración/ejecución en vuelo aparecida; `n8n_esperado` no fijado o distinto.
- **`uncertain` sin retry ciego** en ida Y vuelta: un `PUT` que aplica y pierde respuesta se acredita por GET; uno que no aplicó queda `fallido`; un rollback no acreditable queda `incierto` — ninguno se reintenta solo.
- **RTO:** < 30 min/frente.
- **Rollback por acción (NO global):**
  - Barrera A (`PUT`): reponer la **preimagen** por workflow, en **orden inverso**, solo lo aplicado por esta corrida, con GET/guarda previa; **declara que NO restaura el `versionId` anterior** (no es un undo perfecto — crea/publica otra versión con el contenido previo).
  - Barrera B (`POST`): `DELETE` solo de los clones creados y confirmados por el journal, GET previo de reconciliación.
  - **NUNCA** reimportar los 7 vivos en bloque ni restaurar la BD entera (Juan lo bloqueó; la guarda del cliente lo impide). Backup de BD solo como red última si apareciera una mutación de BD identificada (no la hay en C1).

## 8. Evidencia sanitizada y cero DDL/migraciones/flags/secretos
- Evidencia post sanitizada (conteos, fingerprints, resultado del runner; sin PII, sin secretos, sin IDs de credencial), con la redacción por vocabulario cerrado de `4e2118c`.
- **Confirmación:** NO DDL, NO migraciones, NO flags, NO secretos/origins. Django ya está en `stg@4f0e741` (sin cambio). Si algo de eso hiciera falta, es checkpoint aparte.

## 9. C2 fuera
Instala y verifica C1 (barreras A+B). NO ejecuta M1–M6 (C2), NO E2E vivo, NO `dual`, NO activación de tráfico. C2 requiere su propio GO posterior y separado.

---
**Estado:** borrador NO ejecutable. Pendiente de: (a) revisión del accountable; (b) que Alberto fije la versión/config de n8n STG (punto 6); (c) ventana pactada Alberto↔Juan; (d) exponer el modo vivo del instalador (cambio de código con GO escrito); (e) comentario explícito de GO del accountable en #132.
