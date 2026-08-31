# ⚠️ CARPETA RETIRADA — la red de seguridad de n8n NO está aquí

**Retirada el 23 de agosto de 2026.** La copia viva de los workflows de producción es:

```
aibanez82/Agente-n8n : main : workflows/
```

Ahí están **los cinco** workflows de PROD, y el 23 ago los cinco `versionId` coincidían con los de
`GET /api/v1/workflows` de la instancia:

| Workflow | id de instancia | Nodos |
|---|---|---|
| WhatsApp Insurance Quotation Bot | `BtOaZm7WlZT-24V7hqCnF` | 119 |
| Monitor Qualitas SIO PROD | `3NQfglVIfPSdijm9` | 19 |
| Atencion Humana | `B5ihE5xHg8bjeesl` | 19 |
| Retomar Conversacion | `96XfJZcwvlHnVJLko3G8-` | 12 |
| Payment Confirmation | `disvKr7iVhnNnefuiqJbJ` | 5 |

## Por qué se retiró, y por qué se borraron los JSON

`CLAUDE.md` y `docs/architecture/data-flow.md` llamaban a esta carpeta «la única red de seguridad»
y mandaban re-exportar aquí tras cada cambio en producción. **Llevaba un mes sin ser cierto.** Al
medir contra la instancia el 23 ago:

- tenía **3 de 5** workflows — faltaban `Monitor Qualitas SIO PROD` y `Atencion Humana`;
- el bot estaba en **113 nodos**, congelado desde el **26 de julio**, contra los **119** vivos;
- `Retomar Conversacion` tenía **3 nodos** contra los **12** vivos.

Los tres JSON de la raíz se han **borrado** en lugar de dejarlos con un aviso. Un fichero llamado
`WhatsApp Insurance Quotation Bot.json` en una carpeta que dice ser la red de seguridad **se
importa**, no se lee: reimportar el de 113 nodos sobre el PROD de 119 habría borrado seis nodos de
producción. Un aviso al lado no detiene eso; la ausencia del fichero, sí. Siguen en el historial de
git (`git log -- docs/n8n-workflows/`) para lo que fueron: material de diagnóstico de julio.

**Una red de seguridad falsa es peor que ninguna: invita a tirarse.**

## Lo que sí se queda

Las carpetas fechadas son instantáneas históricas y su nombre ya dice a qué momento pertenecen. No
son la red de seguridad de nada y nadie las va a confundir con el estado vivo:

- `pre-deploy-2026-07-14/` — foto anterior al deploy del 14 jul.
- `staging/` — export de staging del 2 jul.

## Cómo se verifica la copia buena

**Por `versionId` contra la API, nunca por número de nodos** — dos grafos distintos pueden coincidir
en recuento, y ese es justo el error que deja pasar una copia desfasada:

```bash
curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" \
  https://n8n.srv1325340.hstgr.cloud/api/v1/workflows?limit=50
```

---

## Por qué las carpetas se llaman `RETIRADO-…` (31 ago 2026)

El aviso de arriba llevaba desde el 23 de agosto y **no evitó el tropiezo**: el Agente QA entró
directamente al JSON de `staging/`, lo tomó por la fuente viva y dedujo de él que el bot tenía
«~2.087 líneas y 3 nodos Claude» — cuando el bot vivo va por **298 nodos y 5 nodos Anthropic**.

No leyó mal: **entró por el fichero y no por el índice**, que es como entra cualquiera que llega desde
un buscador o desde un `find`.

**Un aviso que solo protege a quien lee en el orden correcto no protege.** Por eso el aviso está ahora
en el **nombre de la carpeta**, que se ve en cualquier listado, y no solo en este README.

**Los JSON se conservan** —son la foto histórica de julio y git ya guarda su contenido—, pero
**ninguno vale como fuente**. La copia viva de los cinco workflows de PROD está en
`aibanez82/Agente-n8n:main/workflows/`, y la verdad última es la API de la instancia.
