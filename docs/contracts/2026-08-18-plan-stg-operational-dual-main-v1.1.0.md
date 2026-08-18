# Plan — `STG-OPERATIONAL-DUAL-MAIN@1.1.0`

> **Borrador del Arquitecto, 18 ago 2026.** Sustituye al contrato `@1.0.0`, cuya fuente aprobada
> (`70145cd7…`, commit `fb98f24`, 4 ago) dejó de describir el candidato.
> **No genera nada por sí mismo:** el artefacto lo produce el builder cuando este plan y el acta de
> autorización estén fijados por hash.

## 0. Autoridad y transición contractual

`@1.0.0` fijaba cuatro premisas por `sha256`: `plan`, `review`, `source` y `prodReference`. La
fuente cambió y el builder abortó con `SOURCE_DRIFT`. **Esa negativa fue correcta** y no se corrige
reponiendo el hash: se corrige emitiendo contrato nuevo.

**Diferencia deliberada respecto a `@1.0.0`: no hay revisión independiente.** Alberto autoriza
directamente (18 ago). Para que el expediente conserve sus cuatro patas y la trazabilidad diga la
verdad, la premisa `review` **se sustituye por `authorization`**: un acta firmada por Alberto, con
su propio `sha256`, que declara qué autoriza y qué no.

**Lo que se pierde y queda dicho:** una revisión independiente es un segundo par de ojos que no
participó en la construcción. Sin ella, el expediente acredita **autorización**, no **verificación
cruzada**. Quien lea el manifiesto debe poder distinguirlo, y por eso el campo cambia de nombre en
vez de reutilizar `review` con otro contenido.

## 1. Alcance cerrado

### Incluido

- **Los 102 nodos nuevos** que la fuente incorporó entre `fb98f24` (154 nodos) y `origin/stg`
  (256 nodos): el módulo de Descuentos `#156` completo — `C1 Gate — Create Discount Offer`,
  `Discount availability`, `Discount catalog`, `Discount offer outbound`, `Discount pending
  outbound` y el resto de su capa de contención `C1`.
- **Los 18 nodos con `parameters` modificados** respecto a la fuente aprobada.
- **El nuevo grafo de conexiones**, que difiere del aprobado.
- **El fix del Terminal Sink (`#170`)** ya reconciliado en el candidato: acceso literal en vez de
  `$(variable)`, que evita el cuelgue de 300 s.

### Excluido

- Cualquier cambio de comportamiento **no presente ya en la instancia de STG**. Este contrato
  acredita lo que corre, no introduce nada.
- PROD, en cualquier forma.
- La reconciliación o replay de las aplicaciones de descuento `1`, `34`, `67`, `100`, `133`.
- El modelo de transformaciones del builder: **sigue siendo declarativo**. Este contrato NO acepta
  «recomponer desde el vivo» como mecanismo, porque invertiría la autoridad entre repo e instancia.

## 2. Premisas del contrato `@1.1.0`

| premisa | fichero | valor |
|---|---|---|
| `plan` | `docs/plan-stg-operational-dual-main-v1.1.0.md` | por calcular al congelar |
| **`authorization`** *(sustituye a `review`)* | `docs/authorization-stg-operational-dual-main-v1.1.0.md` | por calcular al congelar |
| `source` | `workflows/s1/main-candidato.json` | **`132d069894651b3a3ff90bd86b33a0e0a4d92590c1c9037f5fe939a2a522ab98`** |
| `prodReference` | `workflows/WhatsApp Insurance Quotation Bot.json` | **sin cambio**: `7add8969…` |

`source` ya está verificado por el Arquitecto sobre `origin/stg` = `8b3a558`.

## 3. Invariante que este contrato añade

**Re-aprobar la fuente deja de ser un valor inmutable y pasa a ser un acto registrado.** El builder
debe admitir una reposición explícita que exija, y deje escrito en el manifiesto: **quién** la
autoriza, **cuándo**, **contra qué referencia** se comparó y **qué delta** se aceptó.

Motivo, en corto: un generador que siempre está en rojo deja de avisar el día que hay algo que
avisar. Un expediente debe poder actualizarse; un candado, no. Hoy es un candado.

## 4. Evidencia que respalda este contrato

Medido por el Arquitecto sobre los artefactos, no de segunda mano:

**Fuente aprobada (`fb98f24`) → fuente de hoy (`origin/stg`):**

| | |
|---|---|
| nodos | 154 → **256** (+102) |
| nodos eliminados | **0** |
| nodos con `parameters` distintos | **18** |
| nodos con `type` distinto | **0** |
| conexiones | distintas |

**Fuente de hoy → instancia viva** (medido por el Agente n8n y aceptado):

| | |
|---|---|
| nodos solo en uno de los dos | ninguno |
| nodos que difieren solo en posición | 121, por píxeles |
| claves solo en el candidato | 239, todas metadatos `c1*` |
| **campos donde ambos tienen valor y discrepan** | **0** |

Las dos mediciones juntas dicen lo que hace falta: **la fuente describe fielmente lo desplegado**, y
**lo que cambió desde la última revisión es el módulo de Descuentos entero**. La primera hace posible
firmar; la segunda es lo que se firma.

## 5. Criterios de aceptación

1. El builder genera sin `*_DRIFT` con las cuatro premisas de §2 fijadas.
2. El artefacto resultante conserva **1 solo `scheduleTrigger`** y el recuento de nodos de la
   proyección.
3. El detector de referencias de PROD sigue en verde: **ninguna** referencia de producción en el
   operativo de STG.
4. El manifiesto registra las cuatro premisas **y** los datos de la reposición (§3).
5. La suite del builder pasa entera. **Un fallo de entorno no cuenta como verde**: si un fichero no
   carga, se dice cuántas pruebas no se ejecutaron.

## 6. Lo que este contrato NO autoriza

Promoción a PROD · reactivación de workers · ejecución de SQL vivo · import o activación de
workflows en ninguna instancia · reconciliación de aplicaciones históricas · modificar el candidato
para que encaje con el operativo.

## 7. Deuda que este contrato no resuelve, y hay que decirlo

**La captura del vivo lleva rota desde el 10 de agosto.** El upgrade de n8n a 2.28.7 rompió
`detect-drift` (apareció `nodeGroups`, desapareció `description`) y su job estaba desarmado, así que
los espejos dejaron de seguir a la instancia. **Esa es la causa de que la fuente envejeciera hasta
romper el contrato**, y el propio `59b12e0` ya avisaba: *«van dos veces que nuestro fichero es más
viejo que la instancia»*.

Este contrato arregla el expediente. **Si la captura no se restaura, en unas semanas habrá otro
`SOURCE_DRIFT` y otro contrato.** La lista blanca ya está portada a `stg`; falta decidir desde dónde
corre el job y reponer su credencial, en ese orden.
