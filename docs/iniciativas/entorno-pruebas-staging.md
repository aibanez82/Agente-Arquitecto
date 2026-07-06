# Iniciativa — Entorno de pruebas / staging end-to-end

> Estado: **RETOMADA 6 jul 2026 — Fase 1 con runbook listo.** Topología reabierta y decidida tras el Bug #12.
> Guardado en git (no en memoria local) para persistir entre las 3 laptops de Alberto.

## Objetivo

Staging end-to-end para replicar bug fixes antes de subir a prod (gitflow: rama `stg` → `main`). El staging del 2 jul era parcial (ejecución manual con datos "pineados", no conversación WhatsApp real). Se busca cubrir **landing → conversación WhatsApp real → captura → emisión sandbox**.

## Principio rector

Stack paralelo completo; cada componente de staging apunta SOLO a gemelos de staging, nunca a prod. Riesgo #1 = un componente de staging escribiendo/disparando contra prod (p. ej. staging Django disparando al n8n de prod → WhatsApps reales a leads reales; o staging n8n escribiendo en la BD de prod, o llamando al Django de prod).

## Mapa prod → staging (actualizado 6 jul)

| Componente | Producción | Staging |
|---|---|---|
| Backend/landing | `hyl-wai-production` (`main`) | `hyl-wai-stg` (deploy desde `stg`) — ya existe |
| Base de datos | Heroku Postgres prod | Postgres addon PROPIO en `hyl-wai-stg` (jamás la BD prod) |
| n8n (bot WA) | Instancia Hostinger (`n8n.srv1325340.hstgr.cloud`), 3 workflows prod | **INSTANCIA n8n SEPARADA** (decisión 6 jul — ver abajo). NO más `_STG` en la misma instancia |
| Número WhatsApp | Número real (phoneNumberId `1028815256982638`) | **Segunda Meta App + número de test** de Cloud API (gratis, hasta 5 destinatarios verificados) |
| Quálitas | Endpoint productivo | Sandbox vía `QUALITAS_AMBIENTE_FLAG` — **pendiente confirmar con Juan** |
| Dashboard | Vercel prod (`main`) | **Vercel Preview con `DATABASE_URL`→BD stg** (decisión 6 jul) — entra en F2 |
| Pago | Link real Quálitas | Simular el webhook de confirmación (curl), no pagar |

## Decisiones tomadas

### 6 jul 2026 (al retomar)

1. **n8n = instancia SEPARADA (no misma instancia con `_STG`).**
   **Por qué cambió:** la decisión previa (4 jul) era "workflow `_STG` en la misma instancia". El **Bug #12** demostró que ese patrón es peligroso: los duplicados `_STG` compartían el `webhookId 18c1b498` con prod; al activar/desactivar un `_STG`, n8n des-registraba la ruta compartida y dejaba prod **huérfano** (`active:true` sin webhook). Fue el 2º apagón silencioso de inbound en una semana. El 5 jul se borraron los 12 duplicados y la instancia quedó solo con los 3 workflows de prod. Reintroducir `_STG` ahí repetiría el fallo recién erradicado.
   **Beneficio de instancia separada:** aislamiento total — sin `webhookId` compartido, sin credenciales globales compartidas (en n8n las credenciales son globales a la instancia). Elimina de raíz la clase de fallo del Bug #12.
   **Sub-decisión pendiente (implementación, la elige Alberto para arrancar):** dónde vive la instancia separada. Opciones, de más barato/rápido a más aislado:
     - (a) **n8n Cloud** (trial/tier bajo) — cero mantenimiento de infra, aislado por diseño. Recomendado para arrancar F1.
     - (b) Segundo contenedor n8n en el mismo VPS Hostinger, puerto/subdominio distinto — más barato pero comparte host.
     - (c) Otro VPS — máximo aislamiento, más setup.

2. **Dashboard test = Vercel Preview → BD stg.** Un Deploy Preview del dashboard con `DATABASE_URL` apuntando a la Postgres de staging. Es la única forma de que vea las conversaciones de staging y no las de prod. (Se mantiene en **F2** según el fasing.)

### 4 jul 2026 (previas, vigentes)

- **WhatsApp:** staging usa una **Meta App distinta** → webhook distinto → no choca con el trigger de prod. (Con instancia separada esto es aún más limpio.)
- **Quálitas:** existe la variable `QUALITAS_AMBIENTE_FLAG`, pero el flag ≠ las credenciales sandbox.

## Hueco pendiente (dependencia externa)

**Quálitas sandbox — confirmar con Juan** (Alberto envía el mensaje; el Arquitecto lo redacta cuando lo pida):
(a) qué valor de `QUALITAS_AMBIENTE_FLAG` = sandbox; (b) si `hyl-wai-stg` ya tiene cargadas las credenciales sandbox (no solo el flag); (c) si el sandbox cubre cotización (tarifas) Y emisión. **Es la dependencia con más plazo externo** → bloquea solo el paso de emisión del runbook, no el resto.

---

## RUNBOOK — Fase 1 (MVP)

> Cubre: landing stg → conversación WhatsApp real (número test) → captura → emisión sandbox.
> Bugs que permite replicar antes de prod: **#9 (emisión 400), #7 (pago), #8 (teléfono en XML)**. (El **#10** ya está resuelto del lado n8n; staging servirá para regresión.)

**Orden de ejecución (cada paso deja el anterior verificado):**

1. **Postgres staging.** Provisionar addon Postgres PROPIO en `hyl-wai-stg` (nunca la BD prod). Correr migraciones Django. Verificar: `hyl-wai-stg` levanta y `DATABASE_URL` de stg ≠ la de prod.

2. **Backend `hyl-wai-stg`.** Confirmar deploy desde rama `stg`. Verificar landing accesible y que el webhook de "lead creado" apunta a la **instancia n8n de staging** (no a la de prod). ⚠️ Config var del webhook n8n en `hyl-wai-stg` debe ser la URL de la instancia separada.

3. **Instancia n8n separada.** Levantar según sub-decisión (a/b/c). Importar los **3 workflows de prod** (`WhatsApp Insurance Quotation Bot`, `Payment Confirmation`, `Retomar Conversacion`) desde `docs/n8n-workflows/`.

4. **Repuntar TODAS las credenciales a gemelos de staging** (checklist abajo). Ningún nodo puede quedar apuntando a prod.

5. **Número WhatsApp test.** Crear 2ª Meta App + número de test de Cloud API. Registrar el `phoneNumberId` de test en la cred `WhatsApp Test`. Configurar el WhatsApp Trigger de staging con su **webhook propio** (de la Meta App de test). Verificar los hasta 5 destinatarios verificados.

6. **Quálitas sandbox.** *(BLOQUEADO hasta respuesta de Juan.)* Setear `QUALITAS_AMBIENTE_FLAG` = valor sandbox en `hyl-wai-stg`; cargar credenciales sandbox; repuntar el nodo `Issue Policy` para que llame al `/api/emitir-externo/` de **`hyl-wai-stg`** (no a `seguroautoqualitas.com` de prod).

7. **Prueba E2E:** enviar "hola" desde un número verificado → conversación real → captura de datos → serie/VIN → emisión sandbox → simular webhook de pago (curl). Verificar en BD stg que se escribieron `qualitas_lead`/`qualitas_cotizacion`/`whatsapp_sessions`/`n8n_chat_histories`.

### Checklist de auditoría de credenciales (nodo por nodo)

Con instancia separada el riesgo de `webhookId` compartido desaparece, pero SIGUE siendo obligatorio verificar que ningún nodo apunte a un recurso de prod:

- [ ] **Postgres** (`Check Session Exists`, `Load Session`, `Update Activity`, `Postgres Chat Memory`, INSERT proactivo) → cred `Postgres STG` (BD stg), NUNCA `Postgres account` de prod.
- [ ] **WhatsApp Send** (bot + workflow proactivo) → cred `WhatsApp Test` (phoneNumberId de test), NUNCA `1028815256982638`.
- [ ] **WhatsApp Trigger** → webhook de la Meta App de test.
- [ ] **`Issue Policy` (httpRequest)** → URL de `hyl-wai-stg`, NUNCA `seguroautoqualitas.com`.
- [ ] **Claude (Anthropic)** — puede reusar la key de prod (solo hace llamadas LLM, sin efectos secundarios) o una key separada para trackear coste. Decisión menor.
- [ ] Config var del webhook n8n en `hyl-wai-stg` → instancia n8n de staging.
- [ ] Ningún workflow de staging activo comparte `webhookId` con la instancia de prod (con instancia separada es imposible por construcción; verificar igual).

---

## Fases

- **F1 (MVP):** pasos 1–7 de arriba → replica Bugs #9/#7/#8 y regresión de #10.
- **F2:** Dashboard **Vercel Preview → BD stg** (para "Tomar conversación", Kommo, tarjetas).
- **F3:** simulación del webhook de pago + GA4 test.

## Próximos pasos al retomar

1. Alberto elige dónde vive la instancia n8n separada (sub-decisión a/b/c) → arranca el paso 3.
2. Alberto pide al Arquitecto redactar el mensaje a Juan (Quálitas sandbox) → desbloquea el paso 6.
3. Con eso, F1 es ejecutable de principio a fin. Relacionado: Bug #10 y su plan (en `CLAUDE.md`), Bug #12 (`docs/2026-07-05-consolidacion-workflows-n8n.md`).
