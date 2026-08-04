# Dossier para auditor externo — El giro "Contract-First" del plan de integración (4 ago 2026)

> **Preparado por:** Arquitecto-IA-Qualitas, 4 ago 2026, por encargo de Alberto (`@aibanez82`).
> **Encargo al auditor:** analizar el nuevo modelo de trabajo que estableció la contraparte
> (Juan Aguayo / Seguroauto) el 4 de agosto, evaluar sus fortalezas y riesgos, y recomendar si
> **nos conviene adoptarlo como práctica propia futura** (p. ej. para los handoffs
> Arquitecto→ejecutores) y con qué salvaguardas.
> Todo hecho citado aquí fue verificado contra su fuente primaria en esta fecha; ver §8.

---

## 1. Contexto mínimo (para un lector externo)

Dos lados desarrollan un mismo producto (funnel de venta de seguros por web + WhatsApp):

- **Lado Juan (Seguroauto):** el backend Django. Juan opera con un "monitor" IA
  (`@oilycoyote` en GitHub) que audita entregas, publica dictámenes y administra la gobernanza.
- **Lado Alberto:** el resto del ecosistema — bot de WhatsApp en n8n, Dashboard, agentes IA
  ejecutores coordinados por un agente Arquitecto (autor de este dossier).

Toda la coordinación entre lados ocurre por GitHub Issues del repo de Juan (`aguayo-co/HYL-WAI`).
El objetivo técnico en curso: activar el modo "Dual" (dos conversaciones del mismo teléfono sin
cruzarse) en staging, más Atención Humana y derivación "Metepec", sin efectos reales indeseados.

## 2. El modelo anterior (plan C0–C9, issue #140) y por qué importa

El plan anterior dividía el trabajo en fases C0–C9. Su mecánica real, tal como la vivimos:
el ejecutor construía un candidato completo → el monitor lo auditaba a posteriori → dictamen
FAIL con hallazgos P0/P1 → nueva ronda con otro candidato. El criterio de éxito se descubría
durante las auditorías, no antes.

**Datos empíricos de nuestras propias auditorías forenses** (docs `SRC-ALBERTO-C1-002/003`,
reconstruidos desde artefactos git/Issues, commits `f598ea6` y `38bea54` de este repo):

| Métrica de la fase C1 (una sola fase) | Valor |
|---|---|
| Rondas de entrega/auditoría | 24 (+2 corridas vivas) |
| Cambios de alcance durante la fase | 13 (todos post-GO; 9 eran escribibles ex ante) |
| Esperas medibles acumuladas | 39,75 h |
| Handoffs intercambiados | 35 |
| Ratio commits de producto vs. gobernanza | 2 / 32 |
| Estimaciones de esfuerzo antes del GO | 0 (constancia negativa doble) |

La fase C2 siguió el mismo patrón: al menos 10 rondas en ~2 días (3–4 ago), con 4 dictámenes
FAIL sucesivos documentados, hasta que el ciclo se interrumpió por el cambio de modelo. El último
candidato (`1161dcf`) quedó sin veredicto: ni aceptado ni rechazado.

## 3. Qué cambió el 4 de agosto

Juan publicó una **enmienda de alcance** (`#140` comentario `5174994247`, 05:27 UTC) que:

1. **Sustituye las fases C2–C5 por una sola etapa S1** ("Dual en STG"), eliminando la matriz
   extensa de pruebas, los clones especiales, los canaries, las tres matrices consecutivas y la
   observación prolongada del plan anterior. Quedan S1→S2→S3→S4→S5 (Dual → estados/control
   mínimos → Atención Humana → Metepec → limpieza comprobable).
2. Declara **vinculante una metodología nueva: "Contract-First"**
   (`HYL-WAI:docs/metodologia-contract-first-integracion.md @ 1123e402`, 527 líneas).
3. Impone **stand-down**: nuestro lado no desarrolla ni ejecuta nada de una etapa hasta que
   exista contrato congelado + handoff explícito. El candidato C2 anterior se conserva "como
   insumo", sin otra ronda bajo la matriz vieja.
4. Mantiene la gobernanza previa: autoridad contractual y de alcance en el liderazgo de Juan;
   el monitor conserva la facultad de emitir GO operativo (delegación `#140 c.5162421678`);
   un CI verde nunca autoriza por sí solo una acción real.

## 4. Qué es Contract-First (fiel al documento de metodología)

Idea central textual: *"Antes de programar una fase, las partes acuerdan exactamente qué
resultados debe producir. Ese acuerdo se convierte en un contrato que puede comprobarse con
pruebas."* Aprobado el contrato, cada aplicación implementa **de forma independiente**: ya no se
revisa "cómo programó la otra IA", solo si su resultado cumple el contrato congelado.

**Flujo obligatorio por fase (8 pasos):** (1) cerrar la fase anterior; (2) los líderes redactan
el contrato; (3) **una única revisión independiente por versión** (PASS/CHANGES); (4) aprobación
y **freeze** con versión + commit + fingerprint (hash del artefacto — nadie consume "latest");
(5) handoff a cada implementador con su responsabilidad exacta, fixtures y hash contractual;
(6) desarrollo en paralelo, cada uno en su repo; (7) pruebas de conformidad por aplicación
(CI reproducible, PASS/FAIL) + smoke integrado mínimo; (8) consolidación del resultado.

**Cada contrato cubre 4 partes:** funcional (qué debe ocurrir, efectos permitidos/prohibidos),
datos (significado y **dueño de escritura de cada dato compartido** — incluida la BD compartida,
que se trata como interfaz contractual), transición (convivencia de versiones, rollback) e
integración (fixtures, smoke, criterios exactos de PASS/FAIL).

**Reglas de disciplina relevantes:**
- Los implementadores **no negocian lateralmente** ni adaptan su copia del contrato para hacer
  pasar tests; una ambigüedad se publica en el tracker (cláusula + ejemplo + impacto) y la
  resuelven los líderes (aclaración sin cambio semántico, errata, versión nueva o rechazo).
- Pruebas **mínimas y ligadas a riesgo**: 3–6 fixtures por contrato; prohibidas matrices
  combinatorias, fuzzing y duplicar la misma prueba en tres repos. Contra el "Contract Theater":
  todo contrato incluye un **caso negativo que debe fallar** y la validación se hace sobre el
  resultado observado, nunca confiando en un `success=true` del propio runner.
- **Se elimina la revisión IA-a-IA de implementaciones** cuando el contrato no cambió y las
  pruebas pasan; se conserva revisión especial para seguridad, dinero, secretos, cambios
  destructivos de BD y resultados inciertos.
- Estados de contrato: `BORRADOR → EN_REVISION → APROBADO → CONGELADO → SUPERSEDIDO`. Un
  contrato de una fase futura puede aprobarse en paralelo pero no congelarse hasta cerrar la
  fase previa.

## 5. Primer ciclo bajo el nuevo modelo — datos del propio 4 de agosto

La primera etapa (S1) ya corrió parcialmente bajo Contract-First. Cronología verificada (UTC):

| Hora | Evento |
|---|---|
| 05:27 | Enmienda Contract-First publicada (`#140 c.5174994247`) |
| 05:29 | Acuse operativo de nuestro lado |
| 06:05 | **Freeze** del contrato `S1-DUAL-STG v1.0.0` (`#132 c.5175239779`; artefacto `7ac2aa8`, sha256 `a1366175…`) |
| 06:18 | Contrato S2 (fase siguiente) publicado como APROBADO tras redacción + revisión independiente **en paralelo** (`#135 c.5175335674`) |
| 14:14 | Nuestra entrega: implementación n8n `fd8fa75` + suite de conformidad **134/134** en CI sobre el SHA exacto + reporte de gaps de esquema + **5 preguntas de ambigüedad** por el canal formal |
| 14:30 | **Dictamen PASS offline** del monitor; las 5 ambigüedades resueltas como aclaraciones no materiales, sin nueva versión ni nueva ronda (`#132 c.5180485645`) |

Es decir: **contrato→implementación→conformidad→dictamen PASS en ~8,5 horas y una sola ronda**,
frente a 24 rondas (C1) y ≥10 rondas (C2) del modelo anterior para fases comparables. Matiz
importante: es UNA observación, de la parte del trabajo que ya estaba madura por las rondas C2
previas (el candidato anterior sirvió de insumo), y el PASS es *offline* — la etapa S1 completa
sigue abierta esperando la conformidad del propio lado de Juan (Django + gate Dashboard).

## 6. Ventajas observadas o plausibles (para que el auditor las pondere)

1. **Elimina el "criterio móvil"**: en C1 documentamos 13 cambios de alcance post-GO; con el
   fingerprint congelado, el blanco no se mueve durante la implementación.
2. **Colapsa rondas**: la auditoría deja de ser descubrimiento iterativo y pasa a ser
   verificación contra una especificación fija (evidencia: §5).
3. **Reduce revisión cruzada IA-a-IA** — el mayor sumidero de tokens/tiempo del modelo anterior
   (ratio 2/32 producto/gobernanza en C1).
4. **Trazabilidad fuerte**: versión + commit + hash de cada contrato y de cada implementación;
   apto para auditoría posterior.
5. **Canal de ambigüedades funcional en la práctica**: nuestras 5 preguntas se resolvieron sin
   coste de ronda (aunque la muestra es n=1).
6. **Anti-theater explícito**: caso negativo obligatorio y desconfianza del `success=true`
   coinciden con una lección que nosotros ya habíamos aprendido por las malas.
7. **Ownership de datos en BD compartida** tratado como contrato — exactamente nuestro punto
   débil histórico (Django y n8n escriben en las mismas tablas Postgres).

## 7. Riesgos y costes que el auditor debe evaluar

1. **Concentración de autoridad en un solo lado.** El contrato lo redacta el liderazgo de Juan,
   lo revisa un subagente designado por ese mismo liderazgo, las ambigüedades las resuelve ese
   liderazgo y el GO operativo lo emite su monitor. Nuestro lado implementa sin voz formal de
   diseño ("los implementadores no negocian"). En S1/S2 los contratos nos resultaron razonables,
   pero estructuralmente no hay contrapeso: un contrato sesgado o erróneo se nos impone hasta que
   la ambigüedad prospere. *Pregunta al auditor: ¿qué salvaguarda pedir — p. ej. revisión del
   borrador por nuestro lado antes del freeze, o co-firma del contrato?*
2. **Una sola revisión independiente por versión.** Barato, pero un defecto que sobreviva a esa
   única revisión queda congelado; corregirlo exige versión nueva + revisión nueva (coste y
   latencia). El mecanismo de "aclaración no material" amortigua esto, pero su límite lo decide
   la misma autoridad.
3. **Coste de front-loading.** Los contratos reales son grandes (S1 y S2 ~600 líneas cada uno,
   con revisión y fixtures). Para fases de integración multi-aplicación se amortiza; para tareas
   pequeñas puede ser burocracia pura. *¿Cuál es el umbral de tamaño/riesgo a partir del cual
   conviene exigir contrato?*
4. **Rigidez del freeze vs. descubrimiento tardío.** Lo que se aprende implementando no puede
   retroalimentar el contrato salvo vía versión nueva. El plan lo mitiga secuenciando contratos
   por fase ("no congelar demasiado pronto"), pero el riesgo existe en fases con incógnitas
   técnicas grandes.
5. **La conformidad no da autonomía operativa.** Un PASS de conformidad sigue sin autorizar
   deploy/ejecución: cada acción viva requiere checkpoint y GO del monitor. El cuello de botella
   de autorizaciones del modelo anterior persiste intacto; Contract-First acelera el desarrollo,
   no la operación.
6. **Asimetría de ritmo.** Nuestro lado entregó en horas; la etapa espera ahora la conformidad
   del lado que arbitra (Django), sin SLA. El modelo no impone plazos a la autoridad.
   *¿Conviene pedir SLAs de dictamen/resolución de ambigüedades?*
7. **Stand-down como coste hundido.** El cambio de modelo descartó ~10 rondas de C2 (trabajo
   pagado en tokens y horas); el candidato se recicla solo "si cumple el contrato congelado".
   Adoptar esta práctica a mitad de un proyecto tiene un coste de transición real que ya pagamos
   una vez.

## 8. Fuentes primarias verificadas (4 ago 2026)

| Fuente | Referencia exacta | Verificación |
|---|---|---|
| Metodología Contract-First | `HYL-WAI:docs/metodologia-contract-first-integracion.md @ 1123e402` | leída íntegra (527 líneas) |
| Enmienda de alcance S1–S5 | `#140` comentario `5174994247` | leída íntegra |
| Contrato S1 congelado | `docs/contracts/s1-dual-stg-v1.md @ 7ac2aa8`, sha256 `a1366175…`; freeze `#132 c.5175239779` | refs cruzadas en dictamen |
| Nuestra conformidad S1 | `Agente-n8n@fd8fa75`, CI run `30917398768`, 134/134; entrega `#132 c.5180295506` | rama verificada inmóvil |
| Dictamen PASS offline + 5 aclaraciones | `#132 c.5180485645` | leído íntegro |
| Contrato S2 aprobado | `docs/contracts/s2-estados-control-minimos-v1.md @ af57580`, sha256 `ff106e89…` (`#135 c.5175335674`) | descargado; hash recalculado y coincidente |
| Auditorías forenses C1 (métricas §2) | este repo, `docs/auditorias/` (SRC-ALBERTO-C1-002/003, commits `f598ea6`/`38bea54`) | elaboración propia previa |
| Delegación de GO al monitor | `#140 c.5162421678` | leída |

## 9. Preguntas concretas que pedimos responder al auditor

1. ¿Recomiendas adoptar Contract-First como práctica interna nuestra (Arquitecto→ejecutores:
   n8n, Dashboard, QA, Conciliación)? ¿Completa o una variante ligera?
2. Si sí: ¿qué umbral dispara la exigencia de contrato (nº de sistemas tocados, riesgo de datos,
   irreversibilidad), y qué formato mínimo para tareas pequeñas?
3. ¿Qué salvaguardas negociar con Juan para el modelo bilateral vigente (voz pre-freeze,
   SLA de dictámenes, revisor no designado por la misma autoridad, criterios de "materialidad"
   de aclaraciones)?
4. ¿Ves riesgos que no estén en §7, en particular por tratarse de implementadores IA
   (sobre-ajuste al fixture, "teaching to the test", contratos como superficie de inyección)?
5. ¿Cómo medirías durante S2–S5 si el modelo rinde (métricas comparables a las de §2 que
   deberíamos seguir registrando)?
