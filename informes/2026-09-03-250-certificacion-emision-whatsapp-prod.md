# `#250` — certificación de cierre: la emisión por WhatsApp funciona en PROD

**Fecha:** 3 sep 2026 · **Ámbito:** PROD (Django `9105f92`, n8n `bf44e0bb`) · **Issue:** aguayo-co/HYL-WAI#250 — **cerrado**

No lo doy por bueno por la suite ni por el merge: lo acredito por el camino completo, medido contra PROD.

## La cadena, extremo a extremo

| Eslabón | Medición | Fuente |
|---|---|---|
| El bot sigue mandando `M`/`INE` | `$fromAI('genero', "Gender (M or F)")` · `$fromAI('tipo_identificacion', "ID type (INE, Pasaporte, etc.)")` | grafo **vivo** de PROD, `versionId bf44e0bb`, nodo `Issue Policy` — **n8n no se tocó** |
| Y lo mandó de verdad en una emisión que funcionó | `"genero": "M", "tipo_identificacion": "INE"` en el input de la tool | ejecución **`22894`**, 1 sep 23:21:29Z |
| Django lo tradujo | asegurado **1906**: `genero='0'`, `tipo_identificacion='1'` | `qualitas_asegurado` en PROD |
| Y salió póliza | **7620102003**, 1 sep 23:21:50Z — 20 s después de la llamada | `qualitas_polizaemitida` |

**La huella del adaptador se ve por contraste**, sin depender de ninguna interpretación:

| Asegurado | Póliza | Cuándo | `genero` | `tipo_identificacion` |
|---|---|---|---|---|
| 1904 | 7620101467 | 24 ago (antes de que el form validara) | **`M`** | **`INE`** |
| 1905 | 7620101920 | 31 ago 09:38 CDMX | **`0`** | **`1`** |
| 1906 | 7620102003 | 1 sep 17:21 CDMX | **`0`** | **`1`** |

El bot manda lo mismo que mandaba en agosto y en la base quedan códigos de catálogo: entre los dos solo está `normalize_external_emission_catalog_values`. Y no es solo que el dato esté traducido — **es que hay póliza**, que con `M`/`INE` sin adaptador era imposible (`400 invalid_emission_data`).

**Las tres pólizas salieron por el camino del bot**, no por otro: `origen='WhatsApp IA'` lo escribe un único sitio en el código desplegado, `views.py:1127`, dentro de la rama de éxito de `api_emitir_externo`.

## La ventana rota, cerrada y con su coste medido

- **Entró en PROD** el **28 ago 17:34 CDMX** (release 369, `Deploy 38190539` — el primero que ya contiene `df013b0`; el 366 todavía no lo llevaba).
- **Último fallo observado:** 30 ago 20:16 CDMX, sesión `waq_3520_bfc2a46c955e`, con el `tool` literal `{"code":"invalid_emission_data","fields":["genero","tipo_identificacion"]}` y el aviso honesto al cliente.
- **Se arregló** el **30 ago 23:45 CDMX** (release **375**, `Deploy 1dfeafdc`, que trae el merge #267 con `4d0d661`). Ojo al detalle por si alguien mira el historial: **no fue el release 382**, que es dos días posterior.
- **Duración: 2 días y 6 horas. Ventas reales perdidas dentro: cero.** La única sesión que llegó a emisión en esa ventana es de pruebas (`test@test.com`, teléfono de pruebas). Ámbito de esa afirmación: `whatsapp_sessions` de PROD con `last_activity` dentro de la ventana y fase en `summary_confirmation`/`policy_issuance`/`payment_pending`/`completed`.

**La primera emisión con el adaptador vivo fue de un cliente real** — no una prueba nuestra: póliza 7620101920, 31 ago 09:38 CDMX, BYD SONG PLUS, primer pago $20,673.46. Es la mejor evidencia posible de que el camino volvió a estar abierto: lo recorrió alguien que no sabía que había estado roto.

## Lo que queda fuera de este issue

Las dos pólizas están en `estatus_pago = PENDIENTE`. Eso **no es de aquí** —la emisión es lo que se certifica— pero lo dejo dicho para que no se lea como cabo suelto: el cobro va por `#281`/cobranza.

## Método: lo que iba a hacer y por qué no hizo falta

Tenía preparada una sonda sintética contra `/api/emitir-externo/` en PROD —un payload con `genero=M`/`INE` y un **email inválido como freno duro**, para llegar al adaptador y detenerse en `DatosEmisionForm` sin crear lead ni invocar a Quálitas—, con su control negativo (`genero=X`) delante. No fue necesaria: **el caso real de producción ya estaba en la base**, y vale más que cualquier ensayo. Lección repetible: antes de fabricar un caso, mirar si el sistema ya lo vivió.

---

*Ámbito de todo lo anterior: PROD, medido el 3 sep 2026. Horas en CDMX salvo donde marco `Z` (UTC).*

Agente: Arquitecto-IA-Qualitas
