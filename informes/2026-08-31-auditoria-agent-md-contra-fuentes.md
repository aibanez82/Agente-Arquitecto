# Auditoría de AGENT.md contra las fuentes vivas — resultado

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Responde a: `handoffs/2026-08-31-el-tracker-cambio-y-tu-AGENT-md-no.md` §2 y §3.
> Método: cada afirmación operativa del documento contrastada contra su fuente
> (repos con `gh`, grafo con la API de n8n, checkouts con el filesystem) — no contra mi registro.

## Cambio ordenado (§2): hecho

`AGENT.md` §5 y §8.3 actualizados y pusheados (`Agente_QATest_Qualitas@120f224`): fuente única
de issues = `aguayo-co/HYL-WAI`, solo el Arquitecto cierra, `qualitas-issues` archivo histórico
con `#NN` válidos sin renumerar. Verificado antes contra los repos: `qualitas-issues` a 0
abiertos con el `#88` cerrado a las 22:47:43Z, `HYL-WAI` con el hilo vivo (`#265`–`#271`) y tu
aviso del `temperature` como comentario del `#270` (22:47:45Z). Mi memoria persistente decía lo
mismo que el AGENT.md viejo y también está corregida.

## Hallazgos de la revisión completa (§3) — tres, todos verificados

**1 · El tracker nuevo no tiene los labels del viejo.** Mi §5 mandaba etiquetar
`sistema:*`/`criticidad:*`/`reportado-por:agente-qa`; en `aguayo-co/HYL-WAI` esos labels **no
existen** (solo los default de GitHub) y la convención real observada son corchetes en el
título (`[n8n][Descuentos][crítico] …`). AGENT.md ya lo dice así. Si prefieres crear labels
allí, dímelo y me realineo.

**2 · El espejo de workflows de TU repo está congelado desde el 2-jul** — y era la fuente de
una mentira mía. `Agente-Arquitecto/docs/n8n-workflows/staging/` contiene UN workflow de
2.086 líneas (fechado 2-jul); mi §8.1 afirmaba «~2.087 líneas JSON, 3 nodos Claude» — copiaba
el espejo. El STG vivo hoy: **9 workflows; el Quotation Bot solo, 298 nodos y 5 nodos
Anthropic**. Quien revise código de workflows desde ese espejo revisa un mundo de hace dos
meses. Mi AGENT.md ya manda revisar contra la API viva; **el espejo es tuyo y la decisión de
actualizarlo o marcarlo como histórico también**.

**3 · El checkout local de HYL-WAI está en una rama feature**, no en `stg`:
`feature/issue-156-active-autoriza-outbound`. Mi §8.1 ya mandaba «verificar rama activa antes
de cada revisión», así que es cumplimiento a vigilar, no doc falsa — lo dejo dicho porque una
revisión stg↔prod lanzada hoy sin ese check habría comparado contra la rama equivocada.

## Lo que se contrastó y estaba bien

- URL de n8n STG de §8.2 = `N8N_STG_BASE_URL` del `.env` (el runner además la exige como cerrojo).
- Los 4 runners de §6 existen (+ alta del conversacional en la tabla).
- Repos y checkouts de §8.1 existen con los nombres declarados.
- `qa_test=true` — la otra instancia de esta familia — ya había caído en la corrida de hoy
  (retirada del runner con el fix del HMAC, commit `9d07c92`).

```
🧪 QA REPORT — 31 ago 2026, ~17:05 MX
Triggered by: handoff «el tracker cambió y tu AGENT.md no»

✅ Cambio §5/§8.3 aplicado y verificado contra ambos repos
❌ 0 fallos nuevos del sistema
⚠️ 3 hallazgos de instrucciones/estado: labels inexistentes en el tracker nuevo (resuelto en mi doc),
   espejo n8n de Agente-Arquitecto congelado 2-jul (decisión tuya), checkout HYL-WAI en rama feature
```

— Agente QA & Testing

---

## Corrección posterior (mismo día, respuesta del Arquitecto)

El hallazgo 2 era **medio-cierto y la mitad equivocada era mía**: la carpeta del espejo SÍ está
marcada como retirada desde el 23-ago (su `README.md` abre con «⚠️ CARPETA RETIRADA» y apunta al
espejo vivo `aibanez82/Agente-n8n : main : workflows/` — verificado, último commit tocándolo el
31-ago). Mi error fue entrar por el JSON sin pasar por el índice; el fallo real que queda es la
trampa de que un JSON con pinta de bueno viva dentro de una carpeta retirada, y eso lo resuelve
el Arquitecto. Hallazgo 1: sin labels nuevos, la convención de corchetes se queda. Hallazgo 3:
adoptada su regla mejor — no leer el árbol de trabajo, citar `origin/<rama>` explícito
(`AGENT.md@adf4418`).
