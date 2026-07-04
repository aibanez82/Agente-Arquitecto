# Iniciativa — Entorno de pruebas / staging end-to-end

> Estado: **diseño Fase 1 pausado** (4 jul 2026). Se retoma cuando Alberto lo pida.
> Guardado en git (no en memoria local) para persistir entre sus 3 laptops.

## Objetivo

Staging end-to-end para replicar bug fixes antes de subir a prod (gitflow: rama `stg` → `main`). El staging del 2 jul era parcial (ejecución manual con datos "pineados", no conversación WhatsApp real). Se busca cubrir **landing → conversación WhatsApp real → captura → emisión sandbox**.

## Principio rector

Stack paralelo completo; cada componente de staging apunta SOLO a gemelos de staging, nunca a prod. Riesgo #1 = un componente de staging escribiendo/disparando contra prod (p. ej. staging Django disparando al n8n de prod → WhatsApps reales a leads reales; o staging n8n escribiendo en la BD de prod).

## Mapa prod → staging (acordado)

| Componente | Producción | Staging |
|---|---|---|
| Backend/landing | `hyl-wai-production` (`main`) | `hyl-wai-stg` (deploy desde `stg`) — ya existe |
| Base de datos | Heroku Postgres prod | Postgres addon PROPIO en `hyl-wai-stg` (jamás la BD prod) |
| n8n (bot WA) | Instancia Hostinger, workflow prod | **Workflow separado en la MISMA instancia** (decisión de Alberto), carpeta `STAGING` + sufijo `_STG` |
| Número WhatsApp | Número real (phoneNumberId `1028815256982638`) | **Segunda Meta App + número de test** de Cloud API (gratis, hasta 5 destinatarios verificados) |
| Quálitas | Endpoint productivo | Sandbox vía `QUALITAS_AMBIENTE_FLAG` (estaba en `0` en prod) |
| Dashboard | Vercel prod (`main`) | Pestaña "Test" (ver hueco 1) |
| Pago | Link real Quálitas | Simular el webhook de confirmación (curl), no pagar |

## Decisiones tomadas

- **n8n:** workflow separado en la misma instancia, carpeta `STAGING` + sufijo `_STG`. El riesgo real NO es el nombre sino las **credenciales (globales a la instancia)**: crear creds etiquetadas `Postgres STG`/`WhatsApp Test`/`Quálitas Sandbox` y **auditar nodo por nodo** que ninguno use cred de prod. WhatsApp Trigger staging con webhook propio.
- **WhatsApp:** la restricción "un trigger WA por Facebook App" NO afecta porque staging usa una **Meta App distinta** → webhook distinto → coexiste en la misma instancia n8n.
- **Quálitas:** existe la variable `QUALITAS_AMBIENTE_FLAG`, pero el flag ≠ las credenciales sandbox.

## DOS HUECOS por rellenar antes del runbook de Fase 1

1. **Pestaña Test del dashboard: ¿a qué BD apunta?** Solo sirve si lee la Postgres de staging (Vercel Preview con `DATABASE_URL`→stg). Si es sección del dashboard de prod leyendo BD prod, NO verá las conversaciones de staging. **Pendiente confirmar con Alberto.**
2. **Quálitas sandbox — confirmar con Juan:** (a) qué valor de `QUALITAS_AMBIENTE_FLAG` = sandbox; (b) si `hyl-wai-stg` ya tiene cargadas las credenciales sandbox (no solo el flag); (c) si el sandbox cubre cotización (tarifas) Y emisión. Es la dependencia con más plazo externo.

## Fases

- **F1 (MVP):** Postgres stg + `hyl-wai-stg` + Quálitas sandbox + número test Meta + workflow staging n8n → cubre Bugs #10/#9/#7/#8.
- **F2:** Dashboard preview (para "Tomar conversación", Kommo, tarjetas).
- **F3:** simulación del webhook de pago + GA4 test.

## Próximo paso al retomar

Con los 2 huecos resueltos, generar el **runbook paso a paso de Fase 1** + checklist de auditoría de credenciales nodo-por-nodo. Relacionado: Bug #10 y su plan (en este `CLAUDE.md`).
