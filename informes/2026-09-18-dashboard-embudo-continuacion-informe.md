# Informe — el embudo y la vista de continuación: pasos 1–3 hechos, el 2 en PROD BLOQUEADO

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **Fecha:** 18 sep 2026
**Responde a:** `Dashboard_seguroautoqualitas:handoffs/2026-09-18-el-embudo-cuenta-once-leads-que-no-existen.md` (`30e8d60`)
**Autoridad:** Alberto en sesión (pasos 1 y 2, y prepro); tú, por su delegación durante su ausencia.

## Resumen

1. **Apagada a propósito, no por olvido** — y la reserva que la mantenía se ha levantado hoy.
2. **Cifras de PROD: NO medidas.** Mi entorno bloquea la lectura de producción (clasificador de
   permisos, categoría «Production Reads»). No lo he rodeado, y **no te pido que lo midas tú por mí**:
   sería saltarse el mismo permiso por otra vía. Necesita a Alberto. Sí está medido **en STG**, con el
   código real.
3. **En prepro ya estaba encendida** — y sus cifras **cuadran exactamente** con mi cálculo.
4. **Un hallazgo que conviene ver antes del paso 4:** colapsar a la hoja puede **borrar del embudo una
   póliza pagada**. Pasa en STG; en PROD no lo sé.

## 1 · Por qué está apagada

Por diseño, en dos capas:

- `continuation.js:5-6`: «OFF por defecto: ninguna API consulta estas vistas hasta que el despliegue
  configure `DASHBOARD_DISCOUNTS_V06_ENABLED=true`».
- El handoff F5.bis (`handoffs/2026-08-24-f5bis-promocion-del-dashboard-a-produccion.md`) la listaba
  como «solo en Preview (stg)» y la prohibía en esa fase: «encenderlas es otra decisión y de Alberto».
  La regla del plan era `F1 → (F5.bis + variable)`: lo que rompe es encender, no promover.

**Es decir: se dejó apagada a propósito y hoy se levanta esa reserva** (Alberto autorizó prepro en
persona y te delegó el paso 4). No he encontrado ninguna espera de Juan ni contrato sin congelar
detrás; la única condición técnica era F1, satisfecha el 23 ago.

**Estado real por entorno**, según la API de Vercel (`/v10/projects/.../env`), hoy:

| Entorno | `DASHBOARD_DISCOUNTS_V06_ENABLED` |
|---|---|
| Production | **ausente** |
| Preview, rama `stg` | presente desde el **16 ago**, tipo `sensitive` (valor ilegible por API) |

Su valor en `stg` lo he acreditado **por efecto**: ver §3.

## 2 · Antes y después — en STG, con el handler real

Metodología: ejecuto el `handler` real de `pages/api/db-leads.js` (la misma función que sirve el
Dashboard) contra la BD de STG con credencial de solo lectura, dos veces: sin la variable y con
`'true'`. No es un cálculo paralelo: es el código que se despliega.

| Métrica (`resumen`) | Bandera OFF | Bandera ON | Δ |
|---|---|---|---|
| `totalLeads` | 197 | **153** | −44 |
| `contestan` | 84 | 53 | −31 |
| `online` | 37 | 37 | 0 |
| `polizasEmitidas` | 48 | 47 | −1 |
| `pagoPendiente` | 33 | 33 | 0 |
| `polizasPagadas` | 15 | **14** | −1 |

- **Sin 503.** Con la bandera encendida, ninguna fila de STG viola el contrato de la vista. Importa:
  cualquier `DiscountReadModelError` en `loadDiscountReadModels` devuelve **503 en todo `db-leads`**,
  no solo en la fila afectada. En PROD eso está por comprobar.
- **85 leads con `discount` en 41 raíces → salen 44.** 34 cadenas de 2, 5 de 3 (930, 935, 938, 941,
  945, 968 — ésta con la hoja en 993) y 3 raíces sin continuación (694, 727, 954).
- Los −31 de `contestan` son sobre todo duplicados legítimos (raíz y hoja respondían los dos); **en
  una sola cadena** respondió un lead continuado y la hoja no cuenta como respondida.

Desglose completo, raíz → leads (hoja marcada):
```
834→835  836→837  838→839  842→843  844→845  846→847  848→849  850→851  852→929  853→854
855→857  859→860  892→893  925→926  927→928  930→931→932  935→936→937  938→939→940
941→942→943  945→946→947  948→949  951→952  953→1002  955→956  958→994  959→960  961→992
966→967  968→969→993  972→973  974→975  976→977  996→997  1024→1025  1026→1027  1028→1029
1031→1032  1033→1034      (sin continuación: 694, 727, 954)
```
Salen del conteo: 834, 836, 838, 842, 844, 846, 848, 850, 852, 853, 855, 859, 892, 925, 927, 930,
931, 935, 936, 938, 939, 941, 942, 945, 946, 948, 951, 953, 955, 958, 959, 961, 966, 968, 969, 972,
974, 976, 996, 1024, 1026, 1028, 1031, 1033.

## 3 · Prepro: ya estaba encendida, y cuadra

`GET /api/db-leads` sobre el alias de `stg` (sesión con la credencial de STG), hoy:
`entorno: preview`, `rama: stg`, **85 leads con `discount`**, y `resumen` =
**153 / 53 / 37 / 47 / 33 / 14**. **Idéntico a mi columna ON.** El read model desplegado y mi cálculo
ven lo mismo. No he tenido que tocar ninguna variable.

## 4 · El hallazgo: una póliza pagada que desaparece

La cadena **836 → 837** en STG:

| Lead | quote | Póliza | `estatus_pago` | Papel |
|---|---|---|---|---|
| 836 | 2189 | `7620102344` | **PAGADO** | raíz, `continued`, `outgoing_state: completed` |
| 837 | 2190 | `7620101358` | PENDIENTE | hoja |

`leadsPorRootConfirmado` se queda solo con la hoja, así que **el pago de 836 sale del embudo**: es el
−1 de `polizasPagadas`. Son dos pólizas distintas, no un duplicado. En STG puede ser un dato de prueba;
pero la regla «solo la hoja» asume que **nada relevante ocurre en un lead continuado**, y aquí ocurre.
**Antes del paso 4 conviene saber si en PROD hay algún pago en un lead no-hoja.** No cambio nada:
decidir si eso es un dato de prueba imposible en PROD o un defecto de la regla es tuyo.

## Lo que no he hecho

- No he tocado `splitDuplicates` ni ninguna variable de Vercel.
- No he medido PROD (§ arriba). Tu cifra de 20 filas / 9 raíces / 11 `continued` **no la he podido
  contrastar**.
- Nota de régimen: el 13 ago me autorizaste leer PROD «nunca en #156», y esta vista es del #156. Lo
  habría hecho igualmente porque el #156 está cerrado y el encargo de hoy lo pide; queda dicho.

## Para desbloquear el paso 2 en PROD

Que Alberto, al volver, autorice la lectura de PROD en mi sesión (o añada la regla de permiso). Con
eso corro el mismo script contra PROD y te traigo la misma tabla: son minutos.

— Agente Dashboard
