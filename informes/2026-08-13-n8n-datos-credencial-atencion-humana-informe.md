# Datos exactos de la credencial de Atención Humana — leídos del export, no de memoria

**13 ago 2026 · Agente n8n.** Respuesta a `handoffs/2026-08-13-datos-exactos-credencial-atencion-humana.md`.

Todo lo de abajo sale de `Agente-n8n:origin/stg:workflows/Atencion Humana_stg.json`, salvo el punto 2,
que **no se puede leer de ningún sitio** y lo digo como lo que es.

## 1 · Nombre de la credencial

| | |
|---|---|
| En STG, tal como la referencia el workflow | `Atencion Humana Header Auth STG` (id `TyxFAIYtKfgHt9cv`) |
| **En PROD tiene que llamarse** | **`Atencion Humana Header Auth PROD`** |

**Ese nombre no es una preferencia: es el que mi guion le asigna al crear el workflow en PROD**
(`scripts/fase4/promover-atencion-humana.py`, mapa `CREDENCIALES`). Si Alberto la crea con otro nombre,
el guion **aborta** en las precondiciones y lo dice — no falla en silencio.

**Lo que NO se copia de STG:** el sufijo `STG` del nombre (obvio pero es justo lo que preguntas) y el
**id**, que PROD genera por su cuenta y no hay que reproducir.

## 2 · Nombre de la cabecera — **`X-Operator-Auth`**, leído. **Mi inferencia era FALSA**

> ### ⚠️ CORRECCIÓN inmediata a lo que decía este informe
>
> Escribí que el nombre de la cabecera «no se puede leer de ningún sitio» y ofrecí `Authorization` como
> **inferencia**, deducida de la credencial hermana de Retomar. **Es falso, y en los dos sentidos:**
>
> 1. **El valor real es `X-Operator-Auth`.** Lo leyó Alberto en la UI de STG.
> 2. **Y sí estaba escrito**, en evidencia versionada que no encontré:
>    `Agente-n8n@6f1d394:docs/2026-07-29-fase6-5-reporte-port-issue-132.md` §(g), punto 1 —
>    *«Credencial `httpHeaderAuth` "Atencion Humana Header Auth STG" (a mano; header
>    **`X-Operator-Auth`**) + secreto al Dashboard»*. Busqué en los scripts, que es donde suelen estar
>    los payloads, y no en los reportes de fase.
>
> Etiquetarla como inferencia sirvió —Alberto fue a leerla en vez de copiarla— pero el fallo de fondo es
> mío: **deduje de la credencial hermana en vez de buscar la propia**, y la propia estaba documentada.
> Es el mismo patrón del día por tercera vez: una deducción razonable sobre lo que no verifiqué.

**El dato bueno:**

| Campo de la credencial | Valor |
|---|---|
| nombre de la cabecera (`data.name`) | **`X-Operator-Auth`** |
| valor (`data.value`) | el secreto, **sin prefijo `Bearer`** — ver abajo |

**Y esto arrastra otra corrección mía, esta con consecuencia operativa.** Le había dicho a Alberto que el
`Value` tenía que llevar `Bearer <token>`, razonando desde el código vivo del proactivo
(`Dashboard:apps/operacion/pages/api/n8n-proactive-message.js:98`, `Authorization: Bearer ${token}`).
**Ese razonamiento vale para el par de Retomar y NO para este:** `Bearer` es un esquema de
`Authorization`, y `X-Operator-Auth` es una cabecera propia que lleva el secreto **crudo**. El reporte de
Fase 6.5 lo llama «secreto», no token bearer.

La invariante, que es lo único que no cambia: **lo que el Dashboard mande en `X-Operator-Auth` tiene que
ser byte a byte lo que haya en el `Value`.** Y ojo — **este par nunca se ha ejercitado**: los webhooks de
Atención Humana tienen **0 ejecuciones** en STG, así que ni siquiera el par de STG está validado contra un
llamador real. La convención la fijamos ahora, y lo simple es el secreto crudo.

### Y de paso, los nombres que el Dashboard tendría que usar

El mismo reporte los deja escritos, y **el Dashboard no los tiene todavía** (comprobado en su repo):

```
N8N_OPERATOR_WEBHOOK_BASE_URL     -> el host de PROD; el Dashboard construye  <base>/webhook/atencion-humana-*
N8N_OPERATOR_WEBHOOK_SECRET       -> el valor que va en X-Operator-Auth
```

Encaja con mi §4.bis: los `path` son conocidos y estables, así que lo único que cambia por entorno es la
base. Si su agente prefiere otros nombres, es su decisión — pero estos son los del diseño original y
conviene que la elección sea explícita y no por omisión.

## 3 · Qué nodos la usan, y en qué `path` escucha cada uno

| Nodo | `path` | Método | `authentication` |
|---|---|---|---|
| `Iniciar Atencion Trigger` | **`atencion-humana-iniciar`** | `POST` | `headerAuth` |
| `Liberar Atencion Trigger` | `atencion-humana-liberar` | `POST` | `headerAuth` |
| `Enviar Mensaje Trigger` | `atencion-humana-enviar` | `POST` | `headerAuth` |

> **Corrección a tu petición:** escribes `atencion-humana-tomar` como uno de los paths. **No existe**; el
> real es **`atencion-humana-iniciar`**. Si el Dashboard cablea `-tomar`, el síntoma será un **404** que
> nadie relacionará con un nombre mal copiado.

Y las URLs de producción, que salen del `path` y no del `webhookId` (ver mi corrección `4729dc5`):

```
POST https://n8n.srv1325340.hstgr.cloud/webhook/atencion-humana-iniciar
POST https://n8n.srv1325340.hstgr.cloud/webhook/atencion-humana-liberar
POST https://n8n.srv1325340.hstgr.cloud/webhook/atencion-humana-enviar
```

## 4 · ¿Comparten credencial? **Sí, y una sola**

Los tres webhooks referencian **exactamente la misma** (`TyxFAIYtKfgHt9cv`). Ningún otro nodo del
workflow usa `httpHeaderAuth` — los demás son `postgres` y `whatsAppApi`.

## 5 · Un dato que no preguntas y conviene saber antes de nombrarla

**En STG esa credencial NO es solo de Atención Humana:** la comparte `Metepec Liberar_stg`, en su webhook
`metepec-liberar`. Está por diseño — «misma superficie de operador (el Dashboard), un solo secreto que
provisionar», dice el comentario del propio `header-auth-credential.js`.

Hoy no cambia nada, porque **METEPEC no viaja** y en PROD la usarán solo los tres webhooks de Atención
Humana. Lo digo por dos razones: que el nombre `Atencion Humana Header Auth PROD` describe a su **usuario
actual** y no a su **alcance de diseño**, y que si algún día METEPEC viaja, **reutiliza esta misma
credencial** en vez de crear otra.

## 6 · Y confirmo tu lectura de la comprobación

**Nadie va a poder verificar por API que quedó bien creada** — no hay `GET /credentials`. La primera
comprobación real será el `401` o su ausencia en el primer intento del Dashboard. Con una salvedad que
ayuda: **mi guion sí detecta si la credencial no existe** (la resuelve leyendo las que usan los workflows
vivos de PROD) y **aborta antes de escribir**. Lo que no puede ver es si el **nombre de la cabecera** o el
**valor** son los correctos: eso solo lo dice el primer `POST` real.
