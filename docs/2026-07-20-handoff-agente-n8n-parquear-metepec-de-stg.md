# Handoff Arquitecto → Agente n8n — Parquear METEPEC (plataforma digital) fuera de `stg`

> Autor: Arquitecto-IA-Qualitas · 20 jul 2026
> Ejecutor: **Agente n8n**.
> Gobernanza: reportas al Arquitecto **a través de Alberto**. No hablas con otros agentes.
> Copia canónica: `Agente-Arquitecto:docs/2026-07-20-handoff-agente-n8n-parquear-metepec-de-stg.md` — deja también copia en `Agente-n8n/handoffs/`.

## Objetivo

Alberto quiere sacar todo el trabajo de METEPEC (plataforma digital) de `stg` — tanto del
historial de git como del bot que corre en vivo en n8n STG — para que `stg` sea un espejo
limpio de lo que se va a promover a PROD (issues #51/#53/#54, handoff aparte). METEPEC no se
descarta: se parquea en una rama propia para retomarlo más adelante (falta credencial OAuth2 de
PROD, falta el caso "renovación").

**No toca nada de #51/#53/#54** — son cambios independientes en las mismas secciones del
`systemMessage`, pero de bloques distintos. Hacé este handoff primero, y verificá que el
revert no pisa ninguna de esas 8 ediciones (podés diffear contra
`docs/2026-07-20-fixes-leak-kb-y-nombre-issue53-54-stg.md` y
`docs/2026-07-20-revertir-placas-obligatorias-issue51-stg.md` para confirmar que sobreviven).

## Paso 1 — Parquear en git (antes de tocar nada más)

Crear rama `feature/metepec-plataforma-digital` desde el HEAD actual de `stg` (antes de
cualquier revert), y pushearla a origin — así el trabajo completo queda preservado y
retomable, con todo su contexto (handoffs, docs, gotcha #17, scripts de deploy).

```
git checkout stg
git pull
git checkout -b feature/metepec-plataforma-digital
git push -u origin feature/metepec-plataforma-digital
git checkout stg
```

Commits relevantes que quedan preservados ahí (para tu referencia, no hace falta que hagas
nada especial con ellos, ya están en el historial de `stg` que la rama nueva captura):
`e162be6`, `f68671f`, `8d39a1d`, `e549080`, `4cd9aa4`, `9d88839`.

## Paso 2 — Revertir del bot vivo de STG (n8n-xlqk)

Construí un script `revert-metepec-plataforma-digital-stg.py` (mismo patrón dry-run/`--go` que
ya usás) que deshaga, en este orden (revertir el prompt ANTES de quitar el tool, para que el
agente nunca quede en un estado donde intente llamar una tool que ya no existe):

1. **`AI Agent` y `RAG IA Agent` — revertir el `systemMessage`** al texto de antes de METEPEC:
   sacar el bloque de "pedir VIN antes de escalar" y devolver "Vehículo de uso comercial:
   Uber, Didi, taxi, flotilla..." a la lista normal de escalamiento inmediato (mismo
   comportamiento que tenían antes del commit `e162be6` — podés sacar el texto exacto
   reviendo el diff de ese commit y aplicando el inverso).
2. **Quitar el tool `registrar_lead_metepec`** (conexión `ai_tool`) de ambos agentes.
3. **Quitar la conexión `Get Quotation Data` → `RAG IA Agent`** que se agregó específicamente
   para que `RAG IA Agent` pudiera armar los datos de `registrar_lead_metepec` — **antes de
   quitarla, confirmá que nada de lo que agregamos hoy (#53/#54) depende de que `RAG IA Agent`
   tenga esa tool conectada**. Si tenés dudas, dejala y avisame en vez de asumir.
4. **Desactivar (no borrar) el sub-workflow `METEPEC - Registrar Lead (STG)`** (`liBCn3yBegedmYuR`)
   — lo dejamos inerte pero completo, para no tener que reconstruirlo cuando se retome.
5. Re-exportar el JSON del bot principal de STG y commitear en `stg` (no en la rama nueva).

**No toques `leads_metepec`** (tabla Postgres) ni sus filas de prueba — es standalone, no
interfiere con nada, y sirve tal cual cuando se retome el trabajo.

## Paso 3 — Verificación

- Simular (workflow aislado o pin data) un mensaje mencionando Uber/Didi → debe volver a
  escalar de inmediato con el link fijo (`wa.me/525634352430...`), **sin** pedir VIN — mismo
  comportamiento que había antes del 20 jul.
- Confirmar que las reglas de #51 (placas opcionales), #53 (anti-leak KB) y #54 (nombre no
  disponible) siguen intactas después del revert — no deberían tocarse, pero confirmalo antes
  de dar por cerrado.
- Reportar el commit del revert + el commit/push de la rama nueva + resultado de la prueba.

## Documentación

Actualizá `CLAUDE.md` (sección donde documentaste el estado de METEPEC): marcá que se parqueó
en `feature/metepec-plataforma-digital` el 20 jul, con el motivo (Alberto quiere STG limpio
para la promoción de #51/#53/#54/#55 a PROD), y que retomarlo implica: credencial OAuth2 propia
de PROD (si se promueve) + reactivar el sub-workflow + volver a aplicar el revert al revés
(podés reusar el script original `deploy-metepec-plataforma-digital-stg.py`, que ya es
idempotente).

## Fuera de alcance

- Cualquier trabajo nuevo de METEPEC (renovación, promoción a PROD) — queda parqueado, no se
  avanza más por ahora.
- #51/#53/#54/#55 — se manejan en handoffs aparte, no mezclar.
