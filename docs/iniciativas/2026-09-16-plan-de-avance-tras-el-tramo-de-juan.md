# Plan de avance — 16 sep 2026

> Encargado por Alberto: «revisa qué ha hecho Juan, haz match con nuestros pendientes y hazme un plan».
> Todo lo de aquí está medido contra la fuente el 16 sep 2026. **Las cifras caducan.**

---

## 1. Qué ha hecho Juan

**117 commits a `main`** desde el 10 sep, y **123 más esperando en `stg`**. En el mismo periodo cerró
**21 issues**, de los cuales **9 estaban asignados a nosotros**.

Lo que llegó a PROD: el `#281` completo (ledger y recuperación de ligas), el `#363` (historial acotado
del CRM) y tres arreglos de ligas de pago. Lo que espera en `stg`: `#377`, `#378`, `#379`, `#380`,
`#390`, `#394` y `#395` — el aparato entero de campañas de recuperación.

**Los cierres de issues nuestros están bien fundados.** Verifiqué cuatro (`#275`, `#277`, `#279`,
`#297`): cada uno cita contra qué se comprobó y dónde queda el riesgo residual. No son cierres en falso.

**Y los cuatro convergen en el mismo sitio: `#307`.**

## 2. El contraste que manda en este plan

| | Juan | Nosotros |
|---|---|---|
| Commits a producción (10–16 sep) | **117** | 0 |
| Último cambio en el grafo n8n de PROD | — | **8 sep** (bot, 330 nodos) |
| Ejecutores con trabajo propio esta semana | — | **ninguno** |

Medido en la API de n8n de PROD: el bot no se toca desde el 8 sep. Nuestros cinco ejecutores llevan
entre 1 y 12 días sin empujar trabajo propio; lo único que se ha movido en sus repos son mis handoffs.

**No es un problema de capacidad, es de asignación.** Mejoras Conversación y QA no están bloqueados:
están sin encargo.

---

## 3. Plan, por orden de ataque

### P1 · `#307` — el nudo que Juan nos devolvió

`[bug, sistema:n8n, area:emision]`, crítico en el título. **Cuatro críticos cerrados apuntan aquí.**

La barrera determinista que protege el estado de la póliza solo corre si un clasificador probabilístico
decide que corra: `IF Policy Status Intent?` exige `routedIntent === 'policy_status'` **AND**
`cotizacion_sin_poliza === false`. El segundo es un hecho duro del mismo item; el primero es salida de
Haiku que, si no parsea, cae a `contracting`. Medido en STG el 3 sep: **2 de 4 turnos se saltaron el
carril**.

Juan pide decisión de enfoque y candidato offline, y nombra la trampa: quitar el `AND` sin más haría que
cualquier pregunta de un cliente con póliza secuestrara el turno.

**Siguiente paso:** diagnóstico mío contra el grafo vivo y propuesta de enfoque, antes de encargar nada
al Agente n8n. **Pendiente del visto bueno de Alberto.**

### P2 · `#207` — dictamen con el caso real, mañana

Juan espera `CLOSE` o `BLOCKED` desde el 14. La evidencia ya está publicada: la cuota 3 de la póliza
`7620098887` vence **el 17 de septiembre** por **$672,20**, y el generador la tomará sola.

**Recomendación: no cerrar hoy.** Observar mañana la conversación real y cerrar con esa evidencia.
Cerrar ahora sería cerrar por ausencia de caso cuando el caso llega en 24 h.

**Riesgo conocido:** si `#365` no está aplicado para entonces, la liga nace a las 23:15 con ~1 h de su
día. Tendríamos el caso bueno medido en condiciones malas.

### P3 · Dashboard — el merge lleva dos días parado

`origin/stg@8d43117` → `origin/main@d89e295`, 20 commits, autorizado por Alberto el 14 y con suite
verificada (460/0, más las 11 del contrato con `HYL_WAI_REPO`). El handoff está publicado (`920ae10`) y
pregunté por el estado esta madrugada, sin respuesta.

**Siguiente paso:** si sigue sin moverse, reasignar o ejecutarlo por otra vía. No es trabajo pendiente:
es trabajo aprobado que no se ha soltado.

### P4 · Payment Confirmation sigue sin promover, y toca dinero

Medido hoy en la API de n8n de PROD: **5 nodos**, sin tocar desde el 24 ago. En STG tiene **16** — los
11 de más son el aparato S1 (`S1 Payment Request Guard`, `Freeze/Claim/Stash/Restore/Settle`,
`S1 Observable`). El `#132` está cerrado desde el 26 ago y ese aparato nunca viajó.

**Toca dinero**, así que no entra por la autorización permanente: exige orden explícita de Alberto.

### P5 · Los dos ejecutores sin encargo

**Agente QA (parado desde el 5 sep):** validar en STG lo que Juan acaba de desplegar — `#394` (oferta
personalizada), `#396` (recordatorios 6+6) y el `#395`. Es exactamente su oficio y hay material fresco.
**Cautela obligatoria:** STG manda WhatsApp de verdad (`WHATSAPP_PAYMENT_REMINDERS_ENABLED=true`,
`DRY_RUN_DEFAULT=false`), y el botón de prueba de campaña está *fail-closed* por el esquema v3.

**Agente Mejoras Conversación (parado desde el 4 sep):** la cola de conversación acumulada —`#325`
(una pregunta sobre el deducible revienta `Detect Jailbreak`), `#327` (el RAG entrega respuesta sin
pregunta), `#338` (el presupuesto de KB se gasta en turnos que no la consultan), `#245`, `#262`.

**Antes de encargar: verificar cuáles siguen vigentes.** Son del 4–5 sep y el bot se tocó el 6 y el 8;
proponer trabajo ya hecho es peor que no proponerlo.

### P6 · Cobranza Vencida — bloqueada donde no depende de nosotros

`#357`/`#359` esperan las tres plantillas del `#385`, que es de Juan. Del lado nuestro, la fase 1 del
`#359` está construida y entra en el merge de P3.

**Cuando `#390` y `#394` lleguen a un entorno que usemos**, salen dos encargos:
- **Dashboard:** mandar `discount_program_code` en `crearCampana` y poblar el selector desde
  `GET /api/v1/recovery/discount-programs`.
- **Agente n8n:** consumir `_source_context.recovery_offer`, **insertando los importes por nodo y no
  por prompt** — un modelo no garantiza fidelidad de dígito, y aquí son precios reales.

---

## 4. Decisiones que dependen de Alberto

1. **¿Diagnostico el `#307`?** Es el nudo y Juan espera respuesta.
2. **¿Se envía `recovery_quote_promotion`** cuando con el 40 % la póliza sale igual o más cara, o se
   excluye al participante? Es negocio, no arquitectura.
3. **¿Encargo a QA y a Mejoras?** Llevan 11 y 12 días sin trabajo.
4. **¿Promovemos Payment Confirmation** (5→16 nodos)? Toca dinero.
5. **Token de solo lectura de Vercel** en el `.env.local`. Hoy no puedo acreditar despliegues ni
   variables de entorno por mi cuenta, y dependo de que me lo cuente el ejecutor — que es la segunda
   mano que mis propias reglas me prohíben usar para dictaminar.

---

## 5. Lo que NO propongo, y por qué

- **Tocar el cron del `#365` nosotros.** Es infraestructura de la app de Juan y ya está en su tejado.
- **Cerrar el `#207` hoy.** El caso real llega mañana.
- **Encargar el lado n8n del `#394`** todavía: el contrato aún se movía esta mañana.
- **Reabrir los nueve issues que cerró Juan.** Los verifiqué y están bien cerrados.
