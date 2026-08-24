# Adenda F7 — el criterio en su versión final (dictamen del Arquitecto, 24 ago)

> Completa `2026-08-24-n8n-f7-medicion-closed-y-criterio.md`. Sigue sin ejecutarse nada: la
> escritura la autoriza Alberto.

**La fila «anómala» no era un writer roto — era la semántica bien puesta.** El Arquitecto midió las
144 sesiones con mensaje posterior a `last_activity`: todos son SALIENTES del bot (entrega de
documento, seguimientos proactivos). Que no actualicen `last_activity` es correcto: ese campo mide
actividad del CLIENTE; si un seguimiento la actualizara, el sistema de seguimiento reiniciaría su
propio reloj y ningún lead volvería a estancarse. **No se abre issue.**

**Consecuencia sobre el criterio — la tercera condición cambia a `message->>'type'='human'`:** tal
como estaba, un mensaje del propio bot protegía la sesión de cerrarse, y con los seguimientos vivos
(171/30 días) la condición se degradaba sola con el tiempo. Corregida, mide lo que dice medir.

**Criterio v2 (el que se propone a Alberto):** `status IN ('open','active')` **y** >30 días sin
actividad **y** sin póliza emitida **y** sin mensaje `human` en `n8n_chat_histories` en 30 días.
Recuentos de hoy: **827** cerrables (vs 826 de la v1; la diferencia es exactamente la fila que
destapó esto). Encuadre que queda escrito: la protección de verdad son las dos primeras condiciones
— antigüedad y póliza —; la tercera es un cinturón contra un `last_activity` rezagado, no un
detector de conversación viva.

**Dimensión del contexto que se pierde: 598 de las cerrables no tienen ni un solo mensaje humano en
toda su historia** — leads que jamás contestaron; ahí el contexto perdido es ninguno.

**Mecánica de escritura** (validada por el Arquitecto, pendiente de Alberto): `status='closed'` +
`closed_at=now()`, sin tocar `conversation_phase`, WHERE recalculado en el momento de ejecutar, por
lotes con recuento antes y después.

Congelados y aprobados, esperando orden de merge: `fix/f8-censo-cero-activos` (`1ed53e9`) y
`chore/igualar-detect-drift-main` (`72670d4`).
