# Informe F4 — el bot de 229 nodos y su red de error están en PRODUCCIÓN

> Agente n8n · 24 ago 2026 · Handoff `2026-08-24-f4-import-en-n8n-de-produccion.md` (GO `034c498`) +
> respuesta a la duda de las URLs (`cdc7c44`).
> **Resultado: COMPLETA.** Los 5 pasos en su orden, verificación leída de la instancia, exports
> sincronizados a `stg` y `main`.

## Horas e ids (UTC)

| Paso | Hora | Resultado |
|---|---|---|
| 1 · Error Handler PROD | 01:32:49 | **`oTZ86TYMitK2bSur`**, 7 nodos, activo. Credencial **`vQRRtc5qegPhKvCd`** (`n8n API PROD (Error Handler)`) — **la instaló Alberto en su shell** (dato de auditoría; mi arnés no me deja manejar la key). Telegram → `HjpZPCiP7NgG5dMs` (chatId 357953725, el del Monitor); WhatsApp → `PbzXr53disA74eew`; self-call → `https://n8n.srv1325340.hstgr.cloud`; rótulo «n8n PROD». |
| 2 · Issue Policy Guard PROD | 01:33:50 | **`SEKpp6E4gggaHj11`**, 5 nodos, activo. URL (leída de la instancia): `https://seguroautoqualitas.com/api/emitir-externo/`. `errorWorkflow` → Error Handler; timezone CDMX. |
| — · Duda URLs Django | 01:45–02:00 | Parada del paso 3, duda `e064598`, aprobada en `cdc7c44`. |
| 3 · Regeneración | ~02:05 | `stg@89a65df` (rama `fix/f4-fila-django-url-y-workflow-refs`). **sha256 del candidato PROD nuevo: `9674ced29c1bf7b9fd29ac17ce14532693aeeb0c53538d8d2b22213be52d00cf`**. El candidato STG conserva su sha firmado `45b9c183…` intacto (las filas nuevas son no-op para STG). Suite **300/300**; `--check` determinista ×2. |
| 4 · errorWorkflow en los 4 auxiliares | 02:07:18–02:15 | Monitor, Atencion Humana, Retomar, Payment: settings leídos enteros, solo `errorWorkflow` añadido, verificados los 4 leídos de la instancia. |
| 5 · El bot | **02:24:45** | PUT del candidato regenerado. Un primer intento (02:23:41) fue **rechazado entero con 400** (clave `binaryMode` fuera del esquema re-introducida por el merge de settings) — nada escrito; corregido el filtrado y en verde al segundo. `versionId` nuevo: **`98f4d995-2e98-4330-8e81-2acf1251a055`**. |

## Verificación del bot — leída de la instancia, no del fichero

| Comprobación | Resultado |
|---|---|
| Nodos | **229** ✓ |
| `active` | `true` (igual que antes) ✓ |
| `errorWorkflow` | `oTZ86TYMitK2bSur` ✓ |
| `timezone` | `America/Mexico_City` (decisión de Juan, #210) ✓ |
| webhookIds | **6/6 intactos**, incluido el crítico `18c1b498-024e-4803-8088-56ccf9812f33` del trigger ✓ |
| `Issue Policy` | invoca `SEKpp6E4gggaHj11` (PROD), cero rastro de `PuogahK4qv9YOiF4` ✓ |
| `Phone Number ID Guard` | presente, con el teléfono de PROD ✓ |
| `phoneNumberId` | `1028815256982638` en sus portadores; cero apariciones del de STG ✓ |
| Hosts | cero `hyl-wai-stg`/`herokuapp`; 7 llamadas a `seguroautoqualitas.com/api/` ✓ |
| Credenciales | 7/7 de PROD presentes ✓ |
| Los 5 previos | ninguno borrado ni desactivado; los 4 auxiliares con `errorWorkflow` puesto y nodos/active intactos ✓ |

## Los hallazgos de esta fase, nombrados

1. **La fila que faltaba** (duda `e064598`, tu dictamen `cdc7c44`): 7 nodos del candidato PROD
   llamaban al Django de STG — 2 regresiones + 5 del carril de descuentos. Entraron
   `DJANGO_BASE_URL` (con portadores declarados y aborte si el host aparece en otro sitio),
   `WORKFLOW_REFS` y `ERROR_WORKFLOW.prod` a la tabla, y el test **F4(G)** de **ausencia de lo
   ajeno** en las dos direcciones (cero hosts de staging en PROD; cero `/api/` de PROD en STG;
   inventario cerrado de hosts). *Un test de paridad entre dos artefactos no detecta lo que los dos
   tienen mal igual: lo que no tiene fila en la tabla es invisible para la comparación.*
2. **Inventario de superficie sin fila (tu añadido B): no hay cuarta.** Barridas refs de workflow
   (solo `Issue Policy`), tokens literales (cero), números largos compartidos (ordinales del fence
   y teléfonos de ejemplo en prompts: versión), webhookIds (los 3 compartidos por historia + el
   sintético del `Wait Before Discount Offer`, interno del nodo, sin registro en Meta — no
   colisiona entre instancias).
3. **La mención al sitio público** (`https://seguroautoqualitas.com/` sin `/api/`) en el prompt del
   AI Agent es texto para el cliente, legítima en ambos entornos; la verificación de ausencia se
   escribe sobre `/api/` por eso.
4. **§13 del alcance ganó su excepción nombrada**: `entornos.js` es el portador sancionado de
   destinos por entorno — no tenerlos ahí fue el defecto. La contención real (sin cliente HTTP en
   la suite) queda intacta.
5. **El carril CI de conformidad ya no existe** (retirado en `#179` paso 9): el 3.bis del arranque
   quedó obsoleto. La cobertura de este movimiento de `stg` es la suite local (300/300).
6. **Medido: el PUT de solo-settings NO cambia el `versionId`** (igual en los 4 auxiliares). Tu
   expectativa era que cambiara; el hecho es que los anclas de marcha atrás siguen siendo los del
   handoff, lo que a efectos de rollback es mejor. El del bot sí cambió (PUT con nodos).
7. **`binaryMode` vive fuera del esquema del PUT** (400 si lo envías) **pero la instancia lo
   conserva si no lo envías** — verificado en Retomar, Payment y el bot. Gotcha nuevo documentable:
   familia de #4/#30.

## Sincronización a git

Los 7 exports refrescados desde la instancia y commiteados+pusheados **a `stg` y a `main`** (14
commits `sync(F4)`, hasta `origin/stg@86ad188` y `origin/main@25b95a4`): el bot (119→229), los 2
nuevos (`Error Handler.json`, `Issue Policy Guard.json`) y los 4 auxiliares con su `errorWorkflow`.

## Límites — cumplidos

Ningún flag encendido (los módulos llegan apagados por diseño; F5 es otra fase). Ninguna variable
de entorno en ningún sitio. Nada en STG (solo lecturas de verificación). Nada de base de datos.
Ninguno de los 5 workflows previos borrado ni desactivado.

## Marcha atrás vigente

Snapshot pre-import del bot en el scratchpad de la sesión y export previo en git; `versionId`
anterior `c22e1052-47f8-4392-8af1-82e0afd5e606`. Los 4 auxiliares conservan sus `versionId` del
handoff.

F5 (flags) y F6 (smoke E2E) quedan para sus órdenes.
