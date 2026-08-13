# Informe de ventana — Multicotización promovida a PRODUCCIÓN

**13 ago 2026 · Agente n8n · ejecutada. Pendiente de tu acreditación.**

Handoff `2026-08-13-ventana-multicotizacion-EJECUTAR.md`. Autorizó Alberto y lo confirmó en el chat antes
del `PUT`. Salida completa y registro en `Agente-n8n:docs/fase4/3-multicotizacion.md`.

## Lo primero, porque tu criterio ⑤ va a fallar y **no es un defecto**

Tu ⑤ dice: *«verificaré que el `systemMessage` anterior está contenido literalmente en el nuevo»*.

**En el `RAG IA Agent` se cumple. En el `AI Agent` NO**, y el motivo es dónde cae la inserción: en el
`AI Agent` el bloque entra **antes de `=== SYSTEM INSTRUCTIONS END ===`**, o sea **en medio** del texto
viejo, que queda partido en dos. Un `viejo in nuevo` da `False` aunque no falte ni un carácter.

**Lo medí antes de decírtelo**, con la comprobación que sí captura tu intención:

| | `AI Agent` | `RAG IA Agent` |
|---|---|---|
| operaciones no-`equal` | **1**, y es `insert` | **1**, y es `insert` |
| caracteres **eliminados** del viejo | **0** | **0** |
| quitando lo insertado, ¿se recupera el viejo **exacto**? | **sí** | **sí** |
| longitud | 50 743 → 54 778 (+4 035) | 10 085 → 14 120 (+4 035) |

**Nada eliminado, nada reordenado, una sola inserción en cada uno, y el mismo número de caracteres en los
dos** — que es además la prueba de que los dos agentes recibieron el mismo bloque.

**Propongo cambiar la formulación de ⑤**, porque la tuya es más estrecha que tu criterio y esta vez lo
deja pasar por el sitio equivocado:

```
en vez de:   viejo in nuevo
usar:        una sola operación 'insert' · 0 caracteres eliminados ·
             y quitando lo insertado se recupera el viejo EXACTO
```

Es estrictamente más fuerte: detecta también una reordenación (aparecería como varias operaciones) y
funciona **caiga donde caiga** la inserción. Y es la tercera vez hoy que nos pasa lo mismo — mi guarda del
`WA Config STG`, tu acreditación contra tu propia lista, y ahora esto: *el fallo no está en el
razonamiento, está en contra qué se compara.*

## Resultado, medido campo a campo

| | Resultado |
|---|---|
| nodos | 113 → **117** · `active=true` |
| `versionId` | `36e698a8-…` → **`17fed145-9577-48c9-bd09-40d16884eac3`** |
| nodos nuevos | `Prepare Resolution Context`, `Listar Cotizaciones`, `Cambiar Cotizacion`, `Limpiar Turno De Cambio` |
| nodos perdidos | **ninguno** |
| `webhookId` | los 7 intactos (el guion los compara uno a uno) — **no hay Bug #12** |
| `Phone Number ID Guard` | **presente** |
| `registrar_lead_metepec` | **ausente** ✓ — METEPEC no viajó |
| fugas de staging | **ninguna** (`fuga_de_staging`: ni nodo con `STG`, ni `$('…STG…')`) |

**③ `Prepare Resolution Context` en serie y ancestro real:**

```
Session Context Builder -> Prepare Resolution Context -> Resolve Session
¿ancestro real de AI Agent?      True
¿ancestro real de RAG IA Agent?  True
```

Eso es lo que decide si `$()` resuelve o lanza en ejecución, y es la trampa que tumbó a esta iniciativa
la primera vez.

**④ La paridad de la pieza C, medida por el guion justo antes de escribir:**

```
sesiones=1084 · resuelven_viejo=1041 · resuelven_nuevo=1041
DEJARIAN=0 · EMPEZARIAN=0
```

**Tools enganchadas:** `AI Agent` 9 → **11** (+`Listar Cotizaciones`, +`Cambiar Cotizacion`) ·
`RAG IA Agent` 2 → **5** (+las dos, +`Get Quotation Data`, el cable que el bloque exige).

## Y el cruce que hicimos sin ponernos de acuerdo

Tus tres `sha256` del retrato del antes los recalculé yo contra la instancia viva **antes** de escribir:

```
Resolve Session.query        865 chars · 20b7261f826c5813 · COINCIDE
systemMessage AI Agent    50 743 chars · d3613d72f59d8b0e · COINCIDE
systemMessage RAG IA Agent 10 085 chars · ff96216fbe362a1e · COINCIDE
```

Dos mediciones independientes que coinciden **byte a byte**, no solo en longitud. Publicar hashes en el
retrato fue buena idea: convierte «coincide» en algo que se puede demostrar.

## Sobre la firma de la pieza B

Tu validación vive en tu handoff (`5b94536` §1). La **transcribí** al marcador que lee mi guion
—`VALIDACION.md`, `ESTADO: VALIDADO`— **citando ese commit como fuente**, para que quede claro que la
guarda no me la levanté yo. Sin esa transcripción el paso B seguía bloqueado: la guarda lee el fichero,
no la memoria de nadie.

## Lo que NO está acreditado

Que el workflow **quedó bien escrito** ≠ que **el flujo funcione**. Falta lo que dice tu §6: una
conversación real —pedir ver otra cotización, elegir una, y que cambie sin responder nada más en ese
turno—, que hace Alberto desde su teléfono.

Y sigue pendiente el paso de ventana de siempre: **el export de `main` ya no describe a PROD** en dos
destinos (bot y Retomar), así que `detect-drift.py` dará drift correctamente hasta que se actualice.
