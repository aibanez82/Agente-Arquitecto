# Informe — `#493`: una conversación tomada se ve siempre, sea cual sea el periodo

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **30 sep 2026**
**Responde a:** `handoffs/2026-09-30-493-las-tomadas-se-ven-siempre.md` (`20070ba`)

| | |
|---|---|
| Rama | `fix/493-tomadas-siempre-visibles` = **`c33c593`** |
| `stg` | **`13be33d`** (merge `--no-ff`), desplegado READY |
| Suite · verificador · `build` | **702 tests, 700 pass, 0 fail** · OK · verde |
| `main` | sin tocar — el viaje es aparte y lo firma Alberto |

## El cambio

Solo `apps/operacion/lib/inboxPeriodo.js` y su test. `inboxDelPeriodo` deja pasar **siempre** los leads con toma
activa; todo lo demás se filtra por periodo como hasta ahora.

**«Toma activa» — el criterio que ya existía, no uno nuevo:** `claim_agent_id != null`.
- **Dónde se calcula:** `pages/api/inbox.js:60` (`u.id AS claim_agent_id`), con
  `LEFT JOIN dashboard_conversation_claims cl ON cl.lead_id = l.id AND cl.state = 'active'` y
  `LEFT JOIN dashboard_users u ON u.id = cl.agent_id` (líneas 96-97).
- **Quién más lo usa:** el filtro «Tomadas», `components/InboxView.js:55`, con la misma expresión literal.
- Una toma **liberada** no entra en ese join, así que llega con `claim_agent_id` nulo y se filtra como cualquier
  otra. Hay un test que fija que el periodo y el filtro «Tomadas» usan la misma expresión.

## Aceptación

**1 · Test que falla primero.** Contra el código anterior fallaban los tres que tenían que fallar: la toma activa
fuera del periodo, la mezcla y el criterio común. Los dos de «no sale» —sin toma, y toma liberada— **ya pasaban y
siguen pasando**: son la guarda contra pasarse de largo.

**2 · Suite, verificador y `build`:** en verde.

**3 · En el preview de STG — hecho por la API, NO mirando la pantalla, y lo digo así:** no inicio sesión en un
navegador sobre un host remoto (no introduzco contraseñas en formularios), así que la prueba la hice con la sesión
de pruebas **por la API y sobre los datos reales que recibe la página**:

- Tomé el lead **1190** (`waq_2543`, teléfono de pruebas): toma 232, `applied`.
- `GET /api/inbox` en STG lo devolvió con **`claim_agent_id: 2`** y último movimiento el **16 sep**
  (`last_activity`; `last_message_at` nulo).
- Esa **misma fila real**, con el periodo «Hoy» (30 sep):
  - con `inboxDelPeriodo` **de `main` (antes)**: **OCULTA**;
  - con `inboxDelPeriodo` **desplegado en `stg`**: **SE VE**;
  - y cumple el criterio de «Tomadas».
- Después **liberé la toma a mano**, porque el reloj del `#495` está apagado: `released`, y la vista en
  `stable_automation` con `human_takeover = false`.

**Lo que esto no acredita** es el píxel: que el componente pinte la fila. Acredita que la página recibe el lead y
que el recorte ya no lo quita, y el componente pinta lo que recibe. Si quieres la pantalla, hace falta que alguien
con sesión mire **«Tomadas» con «Hoy»** en el preview de STG después de tomar una conversación vieja.

**4 · SHA:** rama `c33c593`, `stg` `13be33d`.

## Lo que esto arregla en PROD cuando viaje

Los leads **2125** y **2208**, que mediste con toma activa desde el 18 y el 25 sep, saldrán en «Tomadas» con
cualquier periodo, incluido «Hoy». Con esto la pieza 2 cumple al fin lo que prometí: *una conversación tomada se ve
hasta que alguien la suelte*, ahora también en la pantalla.

— Agente Dashboard
