# Informe de cierre — Dashboard, 11–12 ago 2026

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Qualitas
**Cubre:** HYL-WAI #156 (los cinco entregables), Fase 0 de la promoción a PROD, y su ventana.
**Estado del código:** nada mergeado, nada desplegado. `stg` y `main` intactos.

Lo que sigue **no está reportado en informes anteriores**: el cableado de E4 y una revisión propia que
encontró dos defectos míos. El resto va como estado consolidado.

---

## 1. Lo nuevo desde la última adenda

### E4 cableado — `49f87a5`

La traducción de reason codes ya **gobierna la UI**: `lib/s1/reasonCopy.js` y los dos componentes
(`InboxTab`, `ConversationWorkspace`). Los componentes **dibujan y no deciden**; antes `InboxTab`
resolvía a mano si algo era conflicto o avería con `res.status === 409 || code === 'claim_already_held'`.

**Tres tipos y no dos**, porque dos no bastan: *bloqueo* (el sistema dice que no, no hay nada que
reportar), *espera* (transición en curso) y *avería* (esto se reporta, y es lo único que enseña el
código técnico al operador).

**Riesgo que hubo que cerrar antes de cablear:** los endpoints devuelven **hoy** códigos que no estaban
catalogados (`conversation_not_open`, `conversation_ambiguous`, `session_unresolved`…). Cablear sin
ellos habría cambiado «La conversación no está abierta» por «Error no reconocido» — o sea **empeorado**
lo que el operador ve. Catalogados los diez vigentes, con test que lo vigila.

`conversation_not_open` queda como **bloqueo y no avería**: es la lección del 10 ago — la conversación
estaba viva y el corte lo produjo un desacuerdo de vocabulario.

### Revisión propia — `d10a991`. Dos defectos míos

Ataqué casos límite que no había cubierto. **Ningún test existente los destapó** y los dos eran reales:

1. **`decidirTake` calculaba `MAX(epoch)+1` sobre todas las filas que le dieran**, sin comprobar que
   fueran de la misma sesión. Tu contrato dice que *el scope de epoch es `session_id`*; mi función
   confiaba en que el llamador lo respetara. Con una consulta mal acotada el epoch habría salido de un
   historial **ajeno** — exactamente lo que el anti-ABA existe para impedir. Ahora la sesión es
   obligatoria y la mezcla se **rechaza, no se filtra**: filtrar habría tapado el bug del llamador.
2. **Una fila del overlay sin `root_quote_id` desaparecía en silencio** al agrupar pero seguía contando
   como lead, así que el factor de inflado salía distorsionado y un dato malformado se perdía.

Lo reporto porque tu contrato dice que *«un `success=true` autorreportado no basta»*, y eso incluye no
presentar como acreditado lo que solo estaba probado en los caminos que a uno se le ocurrieron.

## 2. #156 — estado consolidado

| | Entregable | Estado |
|---|---|---|
| E0 | Metepec | **retirado** — verificado que no había trabajo; corregiste el handoff |
| E1 | Resolver live-only | **hecho** — con la costura única, **asíncrona** desde tu adenda |
| E2 | Claims epoch anti-ABA | **hecho** — migración escrita y no aplicada |
| E3 | Cable Dashboard→n8n | **hecho** — `command_id` derivado, replay vs reutilización de ID |
| E4 | UI y autorización | **hecho y cableado** |
| E5 | Read models | **hecho** — adquisición por root, 3 leads = 1 adquisición |

**Suite 188/188** · **47 gates** de migración + **19** del stub corrupto en PostgreSQL efímero · build OK.

**Lo que sigue sin poder cubrirse, y por qué:**

- **`claim ↔ reserva`**: las reservas de dispatch son ownership de n8n. No es tiempo, es que no me toca.
- **Cableado de E1/E3 a los endpoints**: cambia wire acreditado por Juan. Queda para el paso coordinado.
- **Lista de columnas de `dashboard_lead_continuation_v1`**: el §9 describe el overlay por concepto y no
  publica todos los nombres. Consumo las seis que el fixture acredita, con un test que exige que ambas
  listas coincidan. **No es el SELECT definitivo** y lo digo antes de que lo parezca.

## 3. Fase 0 — aplicada y acreditada

Migración escrita, acreditada con 33 gates sobre las 16 filas reales, **aplicada en PROD el 12 ago** por
Alberto, acreditada por ti y firmada por mí como segundo criterio. Los backfills hicieron exactamente lo
previsto —incluida la distribución `{1:15, 2:1}` que mi cluster efímero había predicho— y **la mina de
#156 queda desactivada**: cero pares `(session_id, epoch)` repetidos.

**Servicio verificado por Alberto:** bandeja de Chats cargando en PROD. Pedí ese segundo clic porque la
primera comprobación era del Resumen, que **no toca** la tabla migrada.

Abierto: el bot (lado n8n), `session_id` sin `NOT NULL` (segunda ventana) y el índice duplicado (Fase 5).

## 4. Dos cosas de proceso que dejo dichas

**Los monitores existen y funcionan.** Portados del Agente n8n y versionados en
`Dashboard:scripts/`. Durante esta jornada cazaron tus respuestas, la corrección del handoff que retiró
E0, y —esto es lo importante— **me trajeron información de conversaciones que no eran mías** y que sí me
afectaban. La decisión de etiquetar las ajenas en vez de filtrarlas fue la correcta.

**La regla de los dos criterios ha demostrado su valor hoy**, y no en abstracto: exigir la acreditación
de la ventana destapó dos divergencias que llevaban ahí desde el primer minuto. Tu frase lo resume mejor
que la mía: *«salió 0 fallos y era verdad, pero comprobé menos de lo que el criterio pedía»*.

---

**Rutas absolutas de lo entregable:**

- `/Users/AIP/claude-projects/Dashboard_SeguroAuto/docs/156/entrega-dashboard.md`
- `/Users/AIP/claude-projects/Dashboard_SeguroAuto/docs/fase0/entrega-claims-paridad.md`
- `/Users/AIP/claude-projects/Dashboard_SeguroAuto/docs/fase0/runbook-ventana-fase1.md` (anexo)
- Ramas: `feature/issue-156-conversation-control-dashboard` · `fix/fase0-claims-paridad-prod`
