# Duda de diseño — la base del RFC que calcula el grafo, en el contexto del turno

**De:** Agente n8n · **Para:** Arquitecto · **9 oct 2026 (UTC)**
**Sobre:** tu decisión (2) de la parte A: «Juan Prado Gómez», RFC 1/5. Va delante de la parte B. Nada construido.

## Lo medido

- **El algoritmo:** `scripts/545/rfc-base.js` (`rfcBase({nombre, paterno, materno, fecha})`). Es el mismo que lleva dentro `Calcular Base RFC` del IPG, verificado byte a byte en el paso 0 del viaje 4. Hoy solo corre en la **emisión**, dentro del IPG.
- **Los datos de entrada:** `captured_data.grupo1` (`nombre`, `apellido_paterno`, `apellido_materno`, `fecha_nacimiento`). El Grupo 1 se guarda (`Save_Group1_Progress`) varios turnos **antes** del de la factura. `Session Resolution` → `sessionRow.captured_data` lo trae al empezar cada turno.
- **Por dónde le llega el contexto al modelo:** el `text` del AI Agent (la línea `[CTX: … ]`) concatena campos de `Merge Session Data`, como `poliza_anterior_recovery`.

## Propuesta

1. **Dónde se calcula:** en `Merge Session Data`, con el algoritmo copiado **literal** de `rfc-base.js` (sin la línea `module.exports`) y con un comentario-puntero al `Calcular Base RFC` del IPG, como el puntero del `#477`: si cambias uno, cambia el otro.
   - Campo nuevo: `rfcBase`, una cadena de 10 caracteres o `null`.
   - **Solo se rellena si** el Grupo 1 tiene nombre, paterno y fecha válidos **y** materno.
2. **En qué nodo entra:** en el `text` del **AI Agent**, `... | rfc_base=PAGJ921203` (solo si `rfcBase` no es null), junto a `poliza_anterior_recovery`. No toca el `systemMessage` del RAG, porque la factura la lleva el AI Agent.
3. **El prompt:** en RFC Y FACTURA, en lugar de «Calcula el RFC base automáticamente (10 caracteres)» con su fórmula, una sola línea: «Usa la base del RFC que te da el sistema en `rfc_base` del contexto; NUNCA la calcules tú.»
   - ¿Quito la fórmula y el ejemplo PEGJ921203, o los dejo como referencia? Con la línea nueva sobran, y dejarlos es lo que invita al modelo a calcular.
4. **Si faltan datos** (`rfc_base` ausente):
   - **(a) Falta un dato del Grupo 1:** el modelo no muestra ninguna base y pide el dato que falta.
   - **(b) Sin materno:** el `#545` decidió no tocar la base en la emisión, porque ninguna variante está medida contra un caso real. Aquí propongo lo mismo: **sin `rfc_base`**, y el modelo pide al cliente su **RFC completo** (13), en vez de la homoclave sola.
   - ¿Vale (b)? La alternativa sería calcular con la regla X del SAT y marcarla como «sin verificar».
5. **Aceptación:**
   - «Juan Prado Gómez» 5/5 con `PAGJ921203` en el resumen, en el arnés sin envíos;
   - **controles:** un caso sin materno (pide el RFC completo, sin inventar la base) y un caso con un dato que falta (lo pide);
   - y que la base del contexto coincide con la que `Calcular Base RFC` pondría en la emisión, sobre el corpus de 88 del #545.

¿Sigo con 1-5, y con (b) para el caso sin materno?

Agente: Agente-n8n
