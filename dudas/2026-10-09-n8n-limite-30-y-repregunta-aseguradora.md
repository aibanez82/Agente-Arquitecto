# Duda n8n · límite de 30 días en el grafo + repregunta de la aseguradora (paquete de firmas, STG)

**Origen.** Prueba real de Alberto en STG (exec 83637, bot `94e85a8c`), sobre el paquete de
`handoffs/2026-10-09-firmas-paquete-prompt-stg.md`. Encargo del Arquitecto por mensaje directo (9 oct):
medir STG contra PROD y proponer aquí **un solo diseño** para la repregunta y para la fuga del cálculo.
Antes de tocar STG hace falta un handoff, porque por mensaje directo no se ordena.

Evidencia: rama `fix/firmas-paquete-prompt-stg` de Agente-n8n, commit `8b6186ec`, `scripts/firmas/c1/`
(arnés sin envíos, resultados, candidatos y comprobaciones).

## 1. Medición (arnés sin envíos, sesión `greeting` sin historial, entrada literal de Alberto)

`hola\nya tengo un seguro con otra aseguradora que vence el 25 de octubre`

| brazo | N | repregunta «¿con nosotros o con otra aseguradora?» | fuga del cálculo de 30 días |
|---|---|---|---|
| prompt STG `94e85a8c`, cot 2982 | 5 | 0/5 | 5/5 |
| prompt PROD `9c813fc3` (grafo STG, solo cambian los 2 `systemMessage`), cot 2982 | 5 | 0/5 | 5/5 |
| prompt STG `94e85a8c`, cot **2900** (la de Alberto) | 20 | **1/20** (pasada 6) | **20/20** |

- **Repregunta: defecto previo, no regresión.** La regla DISAMBIGUACIÓN es byte-idéntica en STG y PROD.
  El diff de la sección RENOVACIÓN solo toca CASO B (#543) y el 5537511678. Su frecuencia es baja
  (1/20); con N=5 no se distingue STG de PROD.
- **Fuga: defecto previo y sistemático.** Pasa con los dos prompts y en todas las pasadas: la salida
  empieza con el razonamiento del límite («El 25 de octubre está a 16 días de hoy (9 de octubre), dentro
  del límite de 30 días…», «El cliente menciona una póliza con otra aseguradora… Procedo con CASO A»).
  Lo medí en el Email Fidelity Guard. Los patrones META_551 del Outbound Leak Guard **no** cubren estas
  formas, así que saldría al cliente. Lo provoca el texto del prompt «calcula la diferencia en días contra
  fecha_actual ANTES de seguir». En la prueba real de Alberto no apareció porque la ejecución fue por la
  rama de la repregunta.
- Corrección de etiqueta (ya aceptada): con otra aseguradora y fecha va el **texto de CASO A**, no c1.

## 2. Diseño propuesto (uno solo, tres piezas, orden: la que protege primero)

**P1 · Red en el Outbound Leak Guard (protege).** Se borran las líneas que cumplan alguna de estas
condiciones, con el mismo mecanismo que el B2 del #551 (si la limpieza vaciara el mensaje, sale el
original):
- el modelo habla del cliente en tercera persona al empezar la línea: `el cliente (ya)? menciona|dice|indica|comenta|aclara|tiene|está …ndo`;
- `CASO [A-Z]` en mayúsculas, en cualquier posición (al cliente nunca le sale);
- `30|treinta` **y** un marcador de cuenta (`límite`, `desde/de hoy`, `hoy (`, `desde el N de`,
  `N días desde/entre`) o de primera persona (`así que puedo|podemos|seguimos|continúo|procedo`);
- `está/queda/cae a N días | dentro de (los) (próximos) N días`, `= N días`, `vs N-…`;
- tokens del contexto: `fecha_actual`, `limite30`, `vence=`.

Medido: **30/30** fugas cubiertas (las 10 del N=5 y las 20 del N=20). Sobre las 1062 respuestas `ai` de
STG marca **1** línea, que es la fuga ya conocida del #551 (verdadero positivo). Marca **0** de los textos
firmados con fechas y plazos (aviso de 30 días, CASO A, c1, b1, «¿sigue vigente o ya venció?») y 0 de dos
frases legítimas de control. Las 30 respuestas quedan limpias y empiezan por el mensaje al cliente.
**El falso positivo sobre los mensajes de PROD está SIN MEDIR:** la lectura de la BD de PROD me la denegó
el clasificador de permisos de esta sesión, y no la he rodeado. Hace falta que Alberto la autorice (o que
la mida otro con acceso) antes de que la red viaje a PROD.

**P2 · El grafo hace la cuenta.** En `Merge Session Data` (Code), junto a `polizaAnterior`, va un nuevo
`venceCtx(chatInput, fecha_actual)`. Solo lee el turno si habla de vencimiento, póliza o seguro, y solo con
**una** fecha clara («25 de octubre», «octubre 25», «25/10», con año o sin él). Si la fecha no trae año y
ya pasó hace más de 60 días, toma la del año siguiente. Si la fecha es ambigua, imposible o ajena al seguro,
devuelve `null` y no se añade nada. El `text` del AI Agent añade al `[CTX:]`
`vence=25/10/2026 | dias=16 | limite30=dentro | fecha_max=08/11/2026`. El RAG no lleva la regla de los
30 días y no se toca. Probado offline en 11 casos (`vence-ctx.candidato.js`).

**P3 · Prompt (`systemMessage` del AI Agent), dos hunks de instrucción interna, sin copy nuevo:**
- *LÍMITE DE 30 DÍAS*: donde ahora dice «Usa fecha_actual… calcula la diferencia en días contra
  fecha_actual ANTES de seguir», pasaría a decir que **la cuenta la hace el sistema**: usar `limite30` del
  `[CTX:]`, y NUNCA hacer la cuenta ni escribir nada sobre ella (días, «dentro del límite», «hoy es…», qué
  caso se aplica). Con `limite30=dentro` se sigue el caso. Con `fuera` se usa el texto firmado actual,
  cambiando el marcador `[fecha_actual + 30 días…]` por `[fecha_max del CTX]`. Si no hay `vence=` aunque el
  cliente diera una fecha, se usa la pregunta que ya existe en CASO A, «¿Qué día exacto vence tu seguro
  actual?».
- *DISAMBIGUACIÓN*: añadir «Si el cliente YA dijo con quién es, en este mensaje o antes (“otra
  aseguradora”, el nombre de otra compañía, “con ustedes”, “Quálitas”), NO hagas esta pregunta: ve directo
  a CASO A o CASO B».

Viaje a PROD: P3 es `systemMessage`, así que **necesita la firma expresa de Alberto** (no entra en la
autorización permanente). P1 y P2 son grafo.

## 3. Lo que necesito que decidas

1. **¿Diseño aprobado tal cual?** Si sí, necesito el handoff para aplicarlo en STG.
2. **`limite30=vencida`, con otra aseguradora** (la fecha ya pasó; hoy el prompt la trataría como «30 días
   o menos» y CASO A diría «que inicie justo el [fecha pasada]», que sería una `fecha_inicio` en el pasado).
   ¿Qué toca? (a) reutilizar b1 («Como tu póliza anterior ya venció… póliza nueva que empieza hoy»), que es
   copy firmado pero escrito para Quálitas; (b) copy nuevo, que firmaría Alberto; (c) fuera de alcance.
3. **Solo el día («el 25»)** como respuesta a «¿Qué día exacto vence?»: ahora da `null`, y el bot volvería a
   pedir la fecha. ¿Lo leo como la próxima vez que llegue ese día del mes, o se queda así?
4. **El falso positivo de P1 sobre PROD**: ¿lo pido a Alberto como permiso de lectura o lo mide otro?

## 4. Aceptación (la tuya) y cómo la mediría

N=20 sin envíos con cot 2900: **0/20 de fuga** (medida en el Outbound Leak Guard y también **antes** de él,
para que P2+P3 se acrediten sin la red) y **0/20 de repregunta** con la frase de Alberto y con su variante
de Quálitas. Más la regresión de CASO A (`fuera`, sin `vence=`), renov, K3 y L1. El control fail-first ya
está: 1/20 de repregunta y 20/20 de fuga sobre el `94e85a8c` actual.
