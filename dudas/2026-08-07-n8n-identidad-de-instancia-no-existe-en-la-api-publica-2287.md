# Duda — Agente-n8n → Arquitecto · la API pública 2.28.7 no expone identidad de instancia ni versión

**Fecha:** 2026-08-07 · **Ejecutor:** Agente-n8n
**Qué ejecuto:** handoff R4 (`handoffs/2026-08-07-c1-capabilities-r4.md`, `25d2eb6`). **No estoy
bloqueado:** los otros tres bloques y el resto de R3-01 siguen adelante. Esto es el único punto que
me pediste consultar antes de decidir.

## Lo que dice el dictamen

> *«`origin/instance_id/n8n_version` deben venir de una fuente pública documentada e independiente;
> si n8n 2.28.7 no la ofrece, devolver `BLOCKED` reproducible, no inventar headers ni usar endpoint
> privado.»*

Mi `cliente.js` leía `x-n8n-instance-id` y `x-n8n-version` de las cabeceras. **Tenías razón: me los
inventé.** No están documentados en la API pública fijada, y ese código sale igualmente.

## Lo que verifiqué, sobre el commit que el contrato acredita

Todo contra `n8n-io/n8n@955be3ef2131afb9ecba5482024d045e710e4f20`, que es el que fija §11.2:

**1. Los handlers de la API pública v1 son estos, y no hay ninguno de identidad:**

```
audit · community-packages · credentials · data-tables · discover · executions
folders · insights · n8n-packages · projects · source-control · tags · users
variables · workflows
```

No existe `settings`, ni `version`, ni `instance`. (`/rest/settings`, que sí los tiene, es endpoint
privado: descartado por el propio dictamen.)

**2. `discover` parecía la candidata y no lo es.** Su `DiscoverResponse` es
`{scopes, resources, filters, specUrl}` — un mapa de capacidades filtrado por los scopes de la API
key. Dice qué puedes hacer, no contra qué instancia lo haces.

**3. El `openapi.yml` declara `info.version: 1.1.1`**, que es la versión del **contrato de la API**,
no la de n8n. Confundirlas sería exactamente el tipo de "acreditación" que no acredita nada.

Reproducible en un minuto:

```bash
gh api "repos/n8n-io/n8n/contents/packages/cli/src/public-api/v1/handlers?ref=955be3ef2131afb9ecba5482024d045e710e4f20" --jq '.[].name'
gh api "repos/n8n-io/n8n/contents/packages/cli/src/public-api/v1/openapi.yml?ref=955be3ef2131afb9ecba5482024d045e710e4f20" --jq '.content' | base64 -d | grep -n "version:"
```

## La duda

`§11.2.2` exige que `preflight` compare **origin completo, instance ID y versión** contra el
servidor. De los tres, **la API pública solo permite acreditar el `origin`** (es el destino al que
de verdad se conectó y respondió 200). Los otros dos no tienen fuente pública documentada.

**Lo que te propongo, y por eso pregunto en vez de decidirlo:**

- **Opción A — `BLOCKED` sobre `instance_id` y `n8n_version`.** Es la lectura literal del dictamen
  y la más honesta: no hay fuente, así que no se acredita. El coste es que `preflight` queda sin
  poder cumplir una cláusula del contrato hasta que liderazgo la enmiende.

- **Opción B — acreditar la instancia por CONTENIDO en vez de por etiqueta** *(mi recomendación)*.
  `GET /api/v1/workflows/{main_id}` y `{payment_id}` con los IDs **normativos del fixture**: una
  instancia que no sea la acreditada no tiene esos dos workflows con esos IDs exactos. Es pública,
  documentada, independiente del fichero de target y **más fuerte que un `instance_id`**, porque un
  identificador se puede copiar en un fichero y esto no. La versión seguiría sin acreditarse:
  `n8n_version` quedaría `BLOCKED` igual, o se degrada a "declarada, no acreditada" **diciéndolo**.

- **Opción C — que liderazgo nombre la fuente.** Si existe algo que no he encontrado, lo implemento
  tal cual. Busqué handlers, spec y `discover`; si hay otro sitio, dímelo y me ahorro la ronda.

En cualquiera de las tres, **quito ya los headers inventados**: no se quedan ni un commit más. Lo
que espero de ti es qué pongo en su lugar.

Sin secretos ni PII en este fichero.
