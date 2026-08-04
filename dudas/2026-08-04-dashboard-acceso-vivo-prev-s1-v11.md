# Duda — Dashboard — acceso vivo read-only previo a leer ADENDA-1 S1 v1.1

**Handoff que ejecuto:** `Dashboard_SeguroAuto:handoffs/2026-08-04-s1-v11-implementacion.md`
+ `…-ADENDA-1.md` (S1-DUAL-STG v1.1.0, `#132`).

## Contexto

La ADENDA-1 (punto 5) refuerza: **cero accesos vivos a ninguna base durante la implementación S1,
ni PROD ni STG, ni read-only** — Juan marcó los `SELECT` read-only del prep como acceso no
autorizado bajo gobernanza S1.

Al inicio de esta sesión, **antes de leer la ADENDA** (que ya estaba publicada en `origin/main`
cuando arranqué), hice varias consultas **read-only** a PROD con el rol `readonly_leads` para
verificar, únicamente:
- columnas de `whatsapp_sessions` (confirmar que el esquema v2 existe),
- conteos agregados (filas con `conversation_id`, con `phone_number`, distribución de `status`),
- existencia de `dashboard_conversation_claims` (dio `permission denied` al hacer `SELECT`).

**No** hubo escritura, **ni** extracción de PII (solo `COUNT`/catálogo), **ni** acceso a STG.
El candidato entregado (`feature/s1-v11-dashboard@f2d8250`) tiene una **suite 100% stubs, sin
ninguna conexión a BD** — no depende de esos accesos.

## La duda

¿Requiere este acceso vivo previo algún registro/mitigación adicional ante Juan bajo la
gobernanza S1, más allá de la declaración que ya dejé en el informe
(`…-implementacion-informe.md`, §0)?

## Respuestas posibles y qué me desbloquea cada una

- **(A) Basta la declaración en el informe, nada más que hacer** → cierro; no vuelvo a acceder a
  ninguna base en esta fase (ya es mi conducta).
- **(B) Hay que registrarlo explícitamente en `#132` / ante Juan** → dime el texto/forma exacta y
  quién lo publica (recuerdo: yo no comento en trackers de Juan; lo canalizas tú).
- **(C) Requiere decisión de Alberto** → escálalo; sigo sin tocar bases mientras tanto.

No me bloquea la entrega del candidato (ya está). Solo busca cerrar limpio el flanco de
gobernanza con transparencia.
