# Informe F1 — capa S1 aplicada a la base de PRODUCCIÓN

> Agente n8n · 24 ago 2026 · Handoff `2026-08-23-f1-capa-s1-en-produccion.md` + ampliación (`65cd9e9`).
> **Resultado: COMPLETA.** 24/24 migraciones + las 2 funciones port-132 (sin trigger). Verificación por recuento abajo, pegada tal cual.

## Horas (reloj del servidor de PROD, UTC)

| Hito | Hora |
|---|---|
| Arranque 1ª tanda (ancla PITR, suelo) | **2026-08-24 00:00:01 UTC** |
| Detención en 156/003 (guarda port-132) | ~00:01 UTC — duda `fcc563c`, 2/24 aplicadas |
| Reanudación tras GO ampliación (`65cd9e9`) | **2026-08-24 00:12:00 UTC** |
| Fin | **2026-08-24 00:14:35 UTC** |

## Las 24, una por una (+ la pieza port-132)

| # | Fichero | Resultado |
|---|---|---|
| 1 | 156/001-readiness-conversation-control-v1 | OK — ensanchadas lead_id/quotation_id a bigint en whatsapp_sessions y archive; human_takeover/metepec_derived ya estaban; paridad_final=OK |
| 2 | 156/002-conversation-control-v1 | OK — CREATE VIEW conversation_control_v1 |
| — | **port-132 solo-funciones** (líneas 1-98 del `07` de `feature/issue-132-port-dual-safe`, SIN CREATE/DROP TRIGGER; autorizado en `65cd9e9`) | OK — CREATE FUNCTION ×2 (canonical_phone, chat_histories_advisory_lock) |
| 3 | 156/003-outbound-fence | OK (2º intento; el 1º abortó fail-closed por la guarda port-132, rollback total) |
| 4 | 156/004-history-inheritance | OK |
| 5 | 156/005-evidence-views | OK |
| 6 | 156/006-checkpoint-outbound | OK |
| 7 | 156/007-discount-resolution | OK |
| 8 | 156/008-discount-phase2 | OK |
| 9 | 156/009-discount-application-poller | OK |
| 10 | 156/010-discount-conversation-handoff | OK |
| 11 | 156/011-discount-delivery | OK |
| 12 | 156/012-retira-sobrecarga-handoff-claim | OK — DROP del overload (timestamptz), conservada (timestamptz,bigint); «invariante ok: queda una sola» |
| 13 | 156/013-conversation-control-v1-1-active-autoriza | OK |
| 14 | 156/014-fence-elegibilidad-una-sola-fuente | OK — «invariante ok» |
| 15 | 156/015-elegibilidad-una-sola-fuente-descuentos | OK — «invariante ok» |
| 16 | 156/016-oferta-de-fase-2-tambien-se-acepta | OK — «invariante ok» |
| 17 | 156/017-discount-terminal-notification | OK — UPDATE 0 (backfill sin filas que tocar, esperado en base sin datos de descuentos) |
| 18 | 156/018-vista-terminal-application-id-text | OK — DROP VIEW + CREATE VIEW terminal_notification |
| 19 | 156/019-herencia-orden-conversacional | OK |
| 24→20 | **163/001-discount-result-active-leaf** | OK — **aplicada ANTES de la 020** porque la guarda de la 020 lo exige literalmente («STOP/PRE/156-020: falta la cirugía de la 163… Aplica migrations/163/001 primero»). Desviación del orden 156→161→163 del handoff, dictada por el propio artefacto; «invariante #163 ok» |
| 20 | 156/020-herencia-fase-y-captura | OK (2º intento) — «invariante #156-020 ok: fase y captura se heredan del source; 163 intacta» |
| 21 | 156/021-fase1-cobertura-senal | OK |
| 22 | 161/001-post-pdf-recovery | OK |
| 23 | 161/002-document-binary-unreadable | OK — «allowlist cerrada» |

Invocación: `psql -X -v ON_ERROR_STOP=1 -v dry_run=off -f <fichero>` (la documentada en cabecera; cada fichero gestiona su propia transacción). Avisos de Postgres: solo los NOTICE citados arriba — ninguno fuera de los rutinarios/invariantes.

## Verificación de cierre — pegada tal cual

```
select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'n8n\_%';
 count 
-------
    47

select count(distinct p.proname) …mismo where…;
 count 
-------
    45

select table_name from information_schema.views
  where table_schema = 'public'
    and (table_name like '%discount%' or table_name = 'conversation_control_v1') order by 1;
 conversation_control_v1
 dashboard_discount_application_v1
 dashboard_discount_terminal_notification_v1
 discount_conversation_activation_evidence_v1
 discount_history_inheritance_evidence_v1
 n8n_discount_application_handoff_v1
 n8n_discount_offer_sent_v1
(7 filas)

select count(*) from pg_trigger where tgrelid='public.n8n_chat_histories'::regclass and not tgisinternal;
 triggers_advisory 
-------------------
                 0
```

- **45 nombres de función** = el objetivo corregido (`1657449`). ✓
- **7 vistas**, las 7 de STG con las 3 exigidas; `dashboard_discount_application_v1` **preexistía** (Django 0068, deploy F2 de ayer 16:46 CDMX) — aportación de F1: 6. ✓
- **Trigger `trg_n8n_chat_histories_advisory_lock`: NO existe** (0 triggers no internos en la tabla). La mitad que acredita que no se aplicó el `07` entero. ✓

## Hallazgo: la fila 48 de STG es un residuo, no un faltante de PROD

En filas (con overloads) PROD queda en **47** y STG tiene **48**. El diff de firmas completo deja UNA sola diferencia: STG conserva `n8n_discount_conversation_handoff_claim(timestamptz)` — **exactamente el overload que la 156/012 retira**. Es decir: la 012 no llegó a correrse en STG (o el overload se recreó después). **PROD refleja el estado final correcto del set; el residuo está en STG.** Decisión sobre limpiar STG: tuya, no la toco sin orden.

## Límites — cumplidos

Nada de n8n (ni import, ni activar). Ninguna variable de entorno (las QUALITAS_* y DASHBOARD_DISCOUNTS_V06_ENABLED siguen como estaban). Ningún DELETE/TRUNCATE/UPDATE de datos de negocio (pre-escaneo de las 24 en limpio; el único DROP fue el del overload que la propia 012 ordena y el DROP VIEW+CREATE de la 018). Nada en STG (solo lecturas de catálogo para el diff).

F4 queda desbloqueada por el lado de la base.
