# Duda · Agente n8n · A · #608 provisional: el texto (no está en la bandeja) y el diseño

**Orden:** `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, adenda 5 (l). **Construyo offline; no importo hasta tu paso** (QA en `327de5ea`).

## 1. El texto: falta el literal

La adenda dice: «se pasa a una persona con el enlace, avisando de que es para corregir el código postal sin perder su precio». En la bandeja **no hay ningún documento del `#608`**, y el issue tampoco trae un texto. **Propongo:**

> «Entiendo, tu código postal es otro. Para corregirlo sin que pierdas tu precio, te paso con una persona de nuestro equipo que te atiende por WhatsApp: [enlace]»

El enlace es el de `WA Config` (`#257`), como en la E de la retención. **¿Lo das por bueno o lo pasas a Alberto?** Lo construyo con este texto, y si cambia, cambia una constante.

**Una nota sobre «sin perder su precio»:** hoy no hay recotización con otro CP (es de Juan). La promesa la sostiene la persona que lo atiende. Si no puede garantizarlo, el texto promete algo que el sistema no hace (como el «te contacto» del límite de 30).

## 2. Lo medido en PROD (solo lectura)

- **Corpus:** los mensajes de cliente de PROD que mencionan el código postal (patrón `c\.? ?p\.?|c[oó]digo postal|postal`): **21**.
- **El detector propuesto salta en 6:**
  - 15557, la de `waq_4442`: «Como le hago para cambiar el código postal»;
  - **5 clientes que escriben su dirección con un CP distinto del cotizado:** h 4761, 5777, 12539, 12966 y 15545.
- **De esas sesiones:**
  - **2 terminaron con póliza emitida** (cotizaciones **2573** y **3662**). En la 3662, el CP del grupo 3 **no** es el cotizado;
  - en 5777, 12966 y 4442 el grupo 3 quedó con el CP cotizado, es decir, con una colonia del CP equivocado.

  **Hay al menos 2 pólizas emitidas con un domicilio que no casa con el CP.** No lo he medido más allá de este corpus.

## 3. Diseño (offline)

- **Detector** (`scripts/608/cp608.js`, batería 17/17, con la frase real de 15557):
  - **`cp_distinto`:** un CP de 5 dígitos, en un mensaje que habla del código postal, **distinto del cotizado**. No cuentan precios, miles, años ni la colonia «1».
  - **`pide_cambiar_cp`:** «cambiar/corregir el CP», «mi CP no es / está mal / es otro».
  - **No cuenta** un número suelto sin la palabra: «Tu pones 90», de `waq_4442`, se queda fuera.
- **`Resolve Session`:** + `qc.codigo_postal AS cotizacion_cp`, que hoy no llega al grafo.
- **Carril fijo** con el texto de arriba, **una vez por conversación**, mientras `hayAtencionHumana = true`.
  - **La marca:** `captured_data.cp608 = {motivo, cp_dicho, ts}`, que **no la borran los guardados de grupo**, porque el cliente sigue dando su dirección.
  - **El carril va directo a su `Send`, sin la cadena de pausa del `#577`.** Si quieres que pause los seguimientos, en rigor es `blocked_issuance`, porque la emisión queda bloqueada; dímelo.
- **Issue Policy Guard:** una comprobación previa nueva, **`Check CP 608`**. Si la sesión tiene la marca: `{status:"error", code:"cp_en_revision", msg:"No puedo emitir todavía: tu código postal está en revisión con una persona de nuestro equipo."}`. **No se emite**, y el agente la comunica (regla de errores de negocio).
- **Prompt (los dos agentes):** «Si el cliente dice que su código postal es otro, NO le ofrezcas colonias de otro CP ni le mandes a la web a rehacer la cotización: el sistema lo pasa con una persona.»
- **Sin `hayAtencionHumana`:** el carril no actúa. **¿Qué quieres en ese caso?** Hoy no hay a quién pasarlo.

**Una pregunta más:** la marca la debe quitar una persona, desde el Dashboard o en Django, cuando el CP esté corregido. ¿Lo dejo así, sin mecanismo en n8n (provisional), o prefieres algo?

— Agente n8n · A
