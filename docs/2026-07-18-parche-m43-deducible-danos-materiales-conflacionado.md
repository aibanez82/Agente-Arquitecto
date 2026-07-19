# Parche M43 — KB conflaciona el deducible de Daños Materiales con Robo Parcial/Equipo Especial/Neumáticos

> Origen: Alberto, revisando en vivo una conversación real de PROD (lead "Honda 2020",
> `525541000103`, cotización 2980, 18 jul). Diagnosticado directo por el Arquitecto.
> Nodo objetivo: KB del `RAG IA Agent`, sección `coberturas`.

## Qué pasó

Cliente real preguntó si el deducible de Daños Materiales era 5% (dato correcto de su propia
cotización). El bot respondió con seguridad: *"El deducible en Daños Materiales es del 25%, no
5%"* — el cliente insistió, el bot se disculpó pero no corrigió el dato con precisión, solo dijo
"si tu cotización dice 5%, confía en tu cotización".

## Causa raíz, verificada contra el trace real y el PDF de Condiciones Generales

`search_knowledge_base1` recuperó 4 chunks para la query "deducible porcentaje 5% daños
materiales cobertura" — **3 de ellos mencionan "25%", pero ninguno es el deducible general de
Daños Materiales**:

1. *"La cobertura de Daños Materiales para **Neumáticos** se limita a 2 eventos por año... El
   deducible es del 25%..."* — sub-cobertura específica de neumáticos, no Daños Materiales en
   general (aunque el texto sí dice "Daños Materiales", crea confusión).
2. *"El deducible es del 25%... (**Cláusula 2 BIS**, sección 2 BIS.2 Deducible)."* — verificado
   en el PDF: la Cláusula 2 BIS es **ROBO PARCIAL**, no Daños Materiales. Este chunk no menciona
   "Robo Parcial" en su texto, solo cita el número de cláusula — el modelo (y cualquier lector)
   no tiene forma de saber que es de otra cobertura sin cruzar el PDF.
3. Un tercer 25% (sección 9.2 del PDF, **Equipo Especial**) — otra cobertura distinta.

**El deducible real de Daños Materiales (Cláusula 1 BIS.2 del PDF) NO es un porcentaje fijo:**

> "...deberá contribuir invariablemente con una cantidad denominada deducible, siendo éste **el
> porcentaje que se establece en la carátula de la póliza**."

Es decir: varía por póliza (puede ser 5%, 10%, 15%, 20%, 25%, según vehículo/opciones) — el
cliente con 5% tenía razón, el bot no.

## Fix — 2 cambios en `kb_chunks`

**1. Chunk nuevo** (`section: 'coberturas'`, `source_clause: '1 BIS.2'`):

- `question`: "¿Cuál es el deducible de la cobertura de Daños Materiales?"
- `content`: "El deducible de Daños Materiales **no es un porcentaje fijo** — varía según tu
  póliza específica y se establece en la carátula de tu cotización (Cláusula 1 BIS.2 de las
  Condiciones Generales). Puede ser 5%, 10%, 15%, 20%, 25% u otro valor, según el vehículo y las
  opciones elegidas — consulta tu cotización para el porcentaje exacto que te corresponde. Nota:
  si el conductor estaba en estado de ebriedad o bajo el efecto de drogas no prescritas al
  momento del siniestro, el deducible se duplica (mínimo 10%)."

**2. Corregir el chunk de "Cláusula 2 BIS" (identificarlo por el texto exacto citado arriba)** —
agregar contexto explícito de que es Robo Parcial, no Daños Materiales, para que no se confunda
en futuras búsquedas:

> "El deducible de la cobertura de **Robo Parcial** es del 25% sobre el monto total del
> siniestro en cada evento (Cláusula 2 BIS, sección 2 BIS.2 Deducible) — esto es distinto del
> deducible de Daños Materiales, que varía por póliza."

El chunk de Neumáticos (#1 arriba) ya menciona "Neumáticos" explícitamente — revisar si vale la
pena aclarar igual que es una sub-cobertura distinta del deducible general, a criterio de quien
aplique.

## Verificación de no-conflicto

- No modifica ningún otro chunk de coberturas ya curado.
- Consistente con el patrón ya usado hoy para `kb_chunks.id=38` (Auxilio Vial) — separar
  contenido conflacionado, agregar chunk nuevo específico.

## Caso de prueba de referencia

Repetir la pregunta real: "¿el deducible de daños materiales es X%?" (cualquier porcentaje) y
confirmar que el bot responde que varía por póliza y remite a la cotización, sin afirmar un
porcentaje fijo incorrecto.

## Verificación antes de aplicar

**Aplicar primero en STG**, verificar retrieval directo contra Postgres antes de promover a
PROD — mismo estándar que `kb_chunks.id=38` hoy.
