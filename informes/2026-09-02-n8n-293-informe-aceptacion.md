# Informe `#293` — los dos números sin nombre ya no se nombran (STG). Batería: **5/5**, precio intacto

**De:** Agente n8n · **Para:** Arquitecto · 2 sep 2026
Handoff `9b631ea` (`HYL-WAI#293`, crítico). Desencolado tras la aceptación 4/4 del `#292` en PROD.

## 1 · Estado del vivo

| | valor |
|---|---|
| Bot STG | `dNqtM20ij6ecZYAX`, versionId **`605fdba7-6d03-4c6d-b1e9-3772fc1a68aa`**, **307 nodos**, active |
| Cadena | `10322583` → `fffa731a` (builder) → `605fdba7` (copy a una línea) |
| Diff total contra `10322583` | **DOS nodos exactos**: `Get Quotation Data` (toolDescription 1.692 → **2.450**, +758) y `AI Agent` (systemMessage 67.670 → **68.751**, +1.081). RAG IA Agent **byte a byte** — barandillas del `#292` contadas: 1→1, 2→2, 1→1, 1→1 |

**Las longitudes que pediste para el número del pasajero en PROD:** Δ toolDescription = **+758**,
Δ AI Agent systemMessage = **+1.081** — a sumar sobre la base de PROD **medida el día del viaje**.

**Una iteración intermedia, dicha entera:** el builder dejó la copy EXACTA envuelta en dos líneas
dentro del bloque; su propio check de literal lo detectó en la verificación post-PUT y paró sin
sincronizar. La práctica del `#292` (copys «responde EXACTAMENTE» en UNA línea, para no invitar a
artefactos de formato) se restauró en `605fdba7` con su script propio. El espejo solo se sincronizó
con el estado final verificado.

## 2 · Lo aplicado (aditivo, sin mapeos, sin números)

- **`toolDescription` de `Get Quotation Data`** (§3a — un nodo, cableado a los DOS agentes): bloque
  «OPAQUE CATALOG VALUES — NEVER SHOWN (#293)», mismo tono e idioma que sus notas existentes:
  opacos del catálogo, NO son la suma asegurada, no se muestran ni se etiquetan, la suma NO está en
  el payload, y el PRECIO se responde con normalidad.
- **`systemMessage` del `AI Agent`** (§3b): sección «SUMA ASEGURADA — DOS NÚMEROS SIN NOMBRE QUE NO
  SE NOMBRAN (#293)», forma 2.bis, con tu copy firmada en una línea y el recordatorio explícito de
  que el precio no cambia.
- Nada mapeado, nada retirado del payload, ni un número en los prompts (el builder lo verifica:
  ni 0.9, ni 90%, ni las cifras del caso).

## 3 · La batería, literal (sesión 2316, Audi A3 2002, Amplia)

| # | Pregunta | Respuesta del bot (literal) | PASS |
|---|---|---|---|
| 1 | «qué suma asegurada tiene el coche?» | «El monto exacto de la suma asegurada de tu vehículo viene especificado en el documento de tu cotización.» — ninguna cifra, dice dónde está | ✅ |
| 2 | «por cuánto está asegurado mi coche?» | idéntica — consistente ante la reformulación | ✅ |
| 3 | «en caso de pérdida total, cuánto me pagan?» | «Con tu Cobertura Amplia, en pérdida total se te indemniza la suma asegurada de tu vehículo menos el deducible. El monto exacto viene en tu cotización.» — **la copy del `#292`, palabra por palabra** | ✅ |
| 4 | «cuánto cuesta mi cotización?» **(BLOQUEANTE)** | «Tu cotización para el AUDI A3 2002 con Cobertura Amplia, pago anual, es de $10,569.29 MXN. ¿Continuamos con la contratación?» — `Get_Quotation_Data` llamada, **precio real céntimo a céntimo**, la valla NO silenció la venta | ✅ |
| 5 | «gracias, lo pienso y te digo» | «Claro, tómate tu tiempo. Solo te comento: tu cotización con Quálitas hoy tiene precio preferencial… (MSI)… Aquí estoy cuando quieras retomar 🙂» — normalidad comercial, sin rastro del bloque nuevo | ✅ |

Ni `valor_uno` ni `valor_dos` ni etiqueta alguna («valor factura», «comercial», «convenido»)
aparecen en ninguna respuesta.

**Observación honesta (no incumple criterio):** las respuestas 1-2 no son ninguna de las dos copys
EXACTAS al pie de la letra — son la instrucción de la `toolDescription` parafraseada (correcta:
ninguna cifra, dice dónde). El turno 1 llamó a `search_knowledge_base1` y no a `Get Quotation Data`;
la valla funcionó igualmente porque la `toolDescription` es visible al agente sin llamarla — que es
exactamente el argumento de tu §3a.

## 4 · Del arnés

Ajuste declarado, como avisé antes de correr: `kbTurns` de `waq_2316` a 5 antes de la batería
(quedó en 8 tras los turnos de KB). 5 mensajes al teléfono de prueba, dentro del aviso previo.

## 5 · Qué queda

**STG y parado** (§6). PROD lo pide Alberto; para ese viaje: re-anclar contra la `toolDescription` y
el `systemMessage` **de PROD** (el del AI Agent parte de otra base — sin el bloque del `#275f`, entre
otras), tu número del pasajero calculado con las deltas de arriba sobre la base medida ese día, y el
conteo de barandillas del `#292` que allí ya viven en PROD.

— Agente n8n
