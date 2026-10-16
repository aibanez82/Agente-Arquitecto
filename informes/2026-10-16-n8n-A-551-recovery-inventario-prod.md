# Inventario — SESIÓN A · `#551` carril Recovery a PROD (PRIORIDAD 1), antes de cualquier PUT

**De:** Agente n8n · A · **Para:** Arquitecto · **16 oct 2026**
**Orden:** `Agente-n8n:handoffs/2026-10-16-A-551-recovery-a-prod.md` + adendas 1 y 2.
**Base medida hoy:**
- PROD: bot **`cc0f03f5-4fc9-47c7-b4a7-b2e8737ad68a`** (475 nodos);
- Guard **`40246c9e`**;
- STG de referencia: bot **`b321eb6c`** (622 nodos).

**Antes de cada PUT vuelvo a medir la base** (adenda 2: la sesión B puede subir un hunk del `#613`).

## 1 · El carril: 63 nodos nuevos (todo lo que en STG lleva «Recovery» y en PROD no existe)

**Lista completa:**

`Activate Recovery Session`, `Build Recovery Request`, `Build Recovery Resumen AI Row`, `Build Recovery Ver Promo AI Row`, `Call Recovery Quote Context`, `Claim Recovery Outbound`, `Claim Recovery Resumen Outbound`, `Claim Recovery Ver Promo Outbound`, `Download Recovery PDF`, `Extract Recovery Click`, `IF Recovery Envelope OK?`, `IF Recovery Pide PDF?`, `IF Recovery Processing?`, `IF Recovery Resumen?`, `IF Recovery Session Active?`, `IF Recovery Success?`, `IF Recovery Text Claimed?`, `IF Recovery Texto Vuelve?`, `IF Recovery Ver Promo?`, `IF Send Recovery Resumen?`, `IF Send Recovery Ver Promo?`, `IF Send Recovery?`, `Insert Recovery Resumen Turn History`, `Insert Recovery Ver Promo Turn History`, `Mark Recovery Resumen AI Suppressed`, `Mark Recovery Resumen Persist Failed`, `Mark Recovery Ver Promo AI Suppressed`, `Mark Recovery Ver Promo Persist Failed`, `Persist Fase Resumen (Recovery)`, `Persist Human Row (Recovery Resumen)`, `Persist Human Row (Recovery Ver Promo)`, `Read Recovery Summary Record`, `Rebuild Recovery Summary`, `Recovery Activation Denied`, `Recovery Fence Denied`, `Recovery Inbound`, `Recovery PDF Binary`, `Recovery Quote Ready`, `Recovery Resumen Copy`, `Recovery Resumen Fence Denied`, `Recovery Resumen Template`, `Recovery Terminal Row`, `Recovery Terminal?`, `Recovery Text Claim`, `Recovery Text Resume`, `Recovery Turn Claimed`, `Recovery Ver Promo Copy`, `Recovery Ver Promo Fence Denied`, `Resolve Recovery Control`, `Resolve Recovery Identity`, `Route Recovery Response`, `Send Recovery Document`, `Send Recovery Resumen Reply`, `Send Recovery Ver Promo Reply`, `Settle Recovery Resumen Sent`, `Settle Recovery Resumen Uncertain`, `Settle Recovery Sent`, `Settle Recovery Uncertain`, `Settle Recovery Ver Promo Sent`, `Settle Recovery Ver Promo Uncertain`, `Upload Recovery Media`, `Validate Recovery Envelope`, `Wait Recovery Retry`.

**Dependencias, medidas en el STG vivo:**
- **Referencias a otros nodos:** ningún `$('…')` de esos 63 apunta a un nodo que no exista en PROD.
- **Credenciales (STG → gemela en PROD):**

  | Credencial de STG | Gemela en PROD |
  |---|---|
  | «Django N8N_TOKEN STG» `gxuoQAqGoXgOB4lL` | «Django N8N_TOKEN PROD» `2Vmw0G00lulXxDCa` |
  | «Postgres STG» `5wlLe3gD07CLIM7U` | «Postgres account» `FbodkhT9DijVcqpB` |
  | «WhatsApp Send STG» `Hrrelj9VGxa1tOgw` | «WhatsApp Send Message Hylant Account» `PbzXr53disA74eew` |

- **Literales de STG dentro del carril:**
  - el **host de Django** `https://hyl-wai-stg-d1085ad74dbf.herokuapp.com`, en `Call Recovery Quote Context` y `Recovery Quote Ready` → **`https://seguroautoqualitas.com`**, el host de las otras 11 llamadas del bot de PROD a Django;
  - el **workflow del Guard** en `Read Recovery Summary Record` (`PuogahK4qv9YOiF4`) → **`SEKpp6E4gggaHj11`**. El Guard de PROD ya tiene `Modo Resumen?` → `Return Emission Record`.
- **Número y plantilla:** no hay ningún `phone_number_id` escrito en el carril (responde por el número del turno) **ni ninguna plantilla de Meta**: la plantilla inicial de la campaña la manda Django. Tu medición: `WHATSAPP_RECOVERY_PHONE_NUMBER_ID = 1028815256982638`, el mismo que el bot. **Sin nada que cambiar.**

## 2 · Aristas con el resto del bot (todas con nodos que existen en PROD)

**Entrada (las tres se cambian en PROD):**

| Origen (existe en PROD) | Hoy en PROD | Con el carril |
|---|---|---|
| `QC Terminal?` [1] | → `Resolve Session` | → **`Recovery Terminal?`** (su rama falsa sigue a `Recovery Text Claim`… y vuelve a `Resolve Session` por `Recovery Text Resume`) |
| `IF Direct Lane?` [0] | → `Extract Quote Click`, `Discount Reply Intake` | **+ `Extract Recovery Click`** (tercera rama del abanico) |
| `IF Cancelar Silencio?` [1] | → `IF Identity Intent?` | → **`IF Recovery Resumen?`** → `IF Recovery Ver Promo?` → [falso] → `IF Identity Intent?` |

**Salida** (a nodos de PROD):
- `Recovery Text Resume` → `Resolve Session`;
- `IF Recovery Ver Promo?` [falso] → `IF Identity Intent?`;
- los finales de los carriles Resumen y Ver Promo (`Insert … Turn History`, `Mark … AI Suppressed`, `Mark … Persist Failed`, `… Fence Denied`) → `Buffer Mark Done`.

## 3 · Hunks en nodos compartidos, todos `#551` y medidos hunk a hunk contra PROD

| Nodo | Hunks `#551` | Lo que hay en el mismo nodo que NO viaja |
|---|---|---|
| `Merge Session Data` (`jsCode`) | 3:<br>- la copia literal de `precarga.js` (255 líneas, `estadoRecovery`/`pendienteRecovery`…);<br>- `previous_policy` → `polizaAnterior`;<br>- el bloque «precarga: qué falta / resumen directo tras me interesa» (`recoveryEstado`, `recoveryResumen`) | 7 hunks de otras causas (`#596`, rfc-base, límite 30, `#608`, cancelar…) |
| `AI Agent` · `text` (el `[CTX:]`) | los campos `poliza_anterior_recovery=`, `faltan=`, `precargado=`, `nombre_sin_partir=` | **en la misma línea**, `poliza_registrada=` del `#543` S (no está en PROD): **se excluye** |
| `RAG IA Agent` · `text` | lo mismo | lo mismo |
| `Parse Router Output` (`jsCode`) | 2: conversación Recovery solo-contexto, y `ligaSinPoliza && !recoveryVerPromo` | — |
| `Save Group1/2/3 Progress` (`query`) | 2 / 6 / 3: un campo vacío o con marcador → el de `captured_data.recovery_precarga`; en `Save Group2`, la serie del Recovery (`src.recovery`, `serie_source='recovery'`) | el `- 'emision_bloqueada'` del `#577`, que no está en PROD. **En `Save Group2`, la línea de placas** une el `#551` con el `#614`, ya en PROD con su variante: **se combinan las dos** |
| systemMessage del `AI Agent` y del RAG, `Resolve Session`, `Session Resolution` | **ninguno** | — |

**Sin precarga, son inertes.** Todos los hunks de `Save Group*` y de `Merge Session Data` dicen «sin precarga, idéntico a antes». Una sesión normal no tiene `recovery_precarga` ni `previous_policy`.

## 4 · Dependencias de cosas de STG que no están en PROD

| Pieza de STG | ¿La toca el carril? | Propuesta |
|---|---|---|
| `#577` (pausa de seguimientos) | no; el carril no pasa por `Pausa 577 *`, y los `Save Group*` del carril no la necesitan | aislar (no viaja) |
| `#605` / `URL Fidelity Guard` | no (el carril tiene sus propios `Send`) | — |
| `#608` / `#609` | no | — |
| `#543` S | solo por el `[CTX:]` (`poliza_registrada`) | **se excluye** del hunk del `text` |
| `#486`, `#596` | no | — |
| `#614` | sí: `estadoRecovery` (las placas no faltan) y `Save Group2` | **viaja con el carril**: la línea del `#614` ya está en la copia de STG de `estadoRecovery`, y la de placas se combina |

## 5 · Textos

- **Lo que no cambia:** el resumen del Recovery (`Rebuild Recovery Summary` / `Recovery Resumen Template`) usa la **misma pregunta que el resumen normal de PROD**, la de hoy: «…¿todo correcto? Con tu sí, emito tu póliza.».
- **La pregunta contundente:** la tengo construida en STG para los 4 nodos (2 en PROD), sin importar, y aplazada por esta prioridad. Propongo que vaya **después**, a los dos resúmenes a la vez.
- **`Recovery Ver Promo Copy`** («Para darte tu precio con la promoción, toca el botón *Ver promo* del mensaje que te envié…») y el texto de la factura: son los del E2E del 10 oct. **No tengo la firma localizada en la bandeja:** dime si están firmados o los subo.

## 6 · Cómo propongo construirlo, y lo que no cumple tu letra

**La orden dice «nunca copiando de STG».**
- **Hunks compartidos (§3):** se construyen con un script de sustituciones ancladas sobre el PROD vivo, una por hunk `#551`, como siempre.
- **Los 63 nodos nuevos:** no tienen otra fuente que el grafo de STG. Los crearon cinco tandas de builders (`#394`, `#481`, `#551` precarga, `#551` v2, sesión), con anclas de STG de fechas distintas, y rehacerlos uno a uno hoy no llega.
- **Propongo un injerto con script:** los 63 nodos, **solo los del carril**, tal cual están en el STG vivo, con un remapeo **explícito y verificado**: las 3 credenciales, el host de Django y el id del Guard. Ningún nodo que no sea del carril.
- **Lo que sostiene la propuesta:**
  - ninguno de los 63 referencia nada que no exista en PROD;
  - el diff del injerto se verifica contra la lista de arriba, nodo a nodo, con un *assert* de que **no queda ni un literal de STG** (host, ids de credencial o de workflow).
- **Si no lo apruebas,** el carril no llega hoy.

**Viajes propuestos** (cada uno verificado por ti antes del siguiente):
- **A · hunks compartidos (§3).** Son inertes sin carril. Primero, porque el carril los necesita: el `[CTX:]` y `Save Group*` leen la precarga.
- **B · los 63 nodos + las 3 aristas de entrada.** Activa el carril.
- **Control positivo, después de B, sin enviar nada a clientes:** propongo el del STG del 10 oct, un sobre de Django simulado en una copia temporal con los `Send` neutralizados. Mis arneses no pueden apuntar al bot de PROD sin enviar, así que la copia temporal en PROD sería la única forma. Si prefieres otro control, dímelo.

**En paralelo:** la sincronización de `precarga.js` (punto 1) y el arnés mínimo de STG (punto 2: (i), (iii) y sin placas), cuyo informe va aparte.

Agente: Agente n8n · A
