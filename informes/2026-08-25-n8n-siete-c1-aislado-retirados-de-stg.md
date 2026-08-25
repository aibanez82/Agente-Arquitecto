# Informe — Los 7 `C1-AISLADO` retirados de STG. Borrar no movió a nadie.

**De:** Agente n8n · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 2026-08-25 (UTC)
**Handoff:** `2026-08-25-retirar-los-siete-c1-aislado-de-stg.md` (orden de Alberto: «eliminemos el ruido puro»)

## Respaldo fresco (§4.1)

Rama **`backup/2026-08-25-stg-pre-borrado-c1`** en origin: GET fresco de los 7 tomado
inmediatamente antes de borrar, **ficheros nombrados por `id`** (esquiva de raíz la trampa del
U+2014 de tu §3) + `INDICE.json` con id → nombre/nodos/versionId. El respaldo del repo
(`c1-aislado-archivado-2026-08/`) queda además intacto donde estaba.

## Re-verificación §2 (sobre el GET fresco, antes de borrar)

7/7 `active: false` con id y nodos exactos a tu tabla · **cero referencias cruzadas** a los 7 ids
en el resto de la instancia · `errorWorkflow` de los 6 vivos que lo declaran → `nT6395r2jjMUqVyF`
(el Error Handler STG no declara ninguno, correcto: es el manejador).

## Los borrados (§4.3)

| id | DELETE |
|---|---|
| `m7W48rrpa6u4RggL` | **HTTP 200** |
| `8vl0xaVm0fMkUBZN` | **HTTP 200** |
| `cmHfIkDFqmeO4m99` | **HTTP 200** |
| `jamPPWpAyA4OygQc` | **HTTP 200** |
| `CfdYS9tuUwHV6dCy` | **HTTP 200** |
| `8XGTTULot5Lgl0Kg` | **HTTP 200** |
| `w8Nzwmyb0WvNhhNN` | **HTTP 200** |

## Aceptación §5

| # | Comprobación | Resultado |
|---|---|---|
| 1 | Workflows tras el borrado | ✅ **9** (lista HTTP 200) |
| 2 | Ninguno `C1-AISLADO` | ✅ 0 |
| 3 | Los 7 activos siguen activos | ✅ 7/7 |
| 4 | `versionId` de los 9 supervivientes | ✅ **idéntico uno a uno** al pre-borrado |
| 5 | Los 2 Metepec | ✅ presentes, inactivos, sin tocar |
| 6 | Bot STG | ✅ `dNqtM20ij6ecZYAX`, 233 nodos, `55597fe6-…` |
| 7 | PROD | ✅ HTTP 200, `8c43fdd0-…`, 229 nodos — ni tocado ni comparado, solo esta lectura |

## Inventario final de STG (9)

| id | nombre | active | nodos | versionId |
|---|---|---|---|---|
| `dNqtM20ij6ecZYAX` | WhatsApp Insurance Quotation Bot_stg | ✅ | 233 | `55597fe6-a87f-44ca-9b13-97a6ac2fe48a` |
| `Ob5JYHYbc23SLp0A` | …Payment Confirmation (STG) | ✅ | 16 | `4594e0a8-1748-4ae4-a671-47c4231c6213` |
| `nYRaRzU83qDLuEWI` | Retomar Conversacion_stg | ✅ | 27 | `3eb8eccc-0b6f-4c09-b3b0-2e8b373bb9c9` |
| `HAMIxqhZd2TEy6NB` | Atencion Humana (STG) | ✅ | 19 | `5bb5755b-5aa7-4ba5-b712-90f9059b1224` |
| `PuogahK4qv9YOiF4` | Issue Policy Guard (STG) | ✅ | 5 | `c674a58f-65b5-4b24-9bc8-c618e1a4c262` |
| `DeCguAaVtCuW2CUj` | Discount Application Poller Candidate v1 | ✅ | 62 | `2ea5e20c-795c-4207-91bc-e1e0f4c12c5f` |
| `nT6395r2jjMUqVyF` | Error Handler STG | ✅ | 7 | `1aaa4e54-1b85-4be1-9d03-efc3b0573dbb` |
| `liBCn3yBegedmYuR` | METEPEC - Registrar Lead (STG) | ⛔ | 19 | `52e64fd9-8a45-4293-b8a9-e33fa9c81f3a` |
| `biWlbwq4NQdZadwg` | Metepec Liberar (STG) | ⛔ | 4 | `f1455211-96dc-498b-bd24-a1277805a0a3` |
