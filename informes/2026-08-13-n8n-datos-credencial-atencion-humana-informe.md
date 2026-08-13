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

## 2 · Nombre de la cabecera — **no puedo leerlo, y por qué**

**No existe en ningún artefacto versionado.** El nombre de la cabecera vive dentro del campo `data` de
la credencial, y:

- la API pública de n8n **nunca devuelve `data`** (ni con el `PATCH` no documentado: «la API nunca
  devuelve el valor guardado», gotcha #11 del repo);
- y **esta credencial la creó Alberto a mano en la UI de STG**. El código del port #132 solo la
  referenciaba por nombre con un id placeholder — literal:
  `PLACEHOLDER_ATENCION_HUMANA_HEADER_AUTH_STG`
  (`scripts/port-132/steps/lib/header-auth-credential.js`). O sea que **ningún script la creó**, y por eso
  no hay payload del que leer la cabecera.

**Lo que sí tengo es la convención, con evidencia:** la credencial hermana de Retomar se creó con

```python
{"name": CRED_NAME, "type": "httpHeaderAuth",
 "data": {"name": "Authorization", "value": token}}     # scripts/add-stg-auth-retomar-conversacion.py:159
```

o sea cabecera **`Authorization`**. Es lo más probable, **pero es inferencia, no lectura**, y hoy ya nos
ha costado dos correcciones dar por leído lo que era deducido.

**Cómo cerrarlo en 30 segundos y sin adivinar:** abrir `Atencion Humana Header Auth STG` en la UI de
**STG**. n8n enmascara el **valor**, pero **muestra el nombre de la cabecera**. Ese es el dato bueno, y
STG es la referencia porque es donde el par funciona hoy.

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
