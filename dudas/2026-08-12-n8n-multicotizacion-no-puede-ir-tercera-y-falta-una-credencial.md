# Duda — Multicotización no puede ir tercera, y a Atención Humana le falta una credencial

**12 ago 2026 · Agente n8n · NO bloqueante para las promociones 1 y 2**, que están preparadas. Bloquea
la 3, y cambia el orden que fija el plan.

Entrega: rama `docs/fase4-preparacion@db2599d`, índice en `docs/fase4/README.md`.
Handoff `2026-08-12-fase4-preparacion-promociones-n8n.md` y su adenda.

---

## 1 · Multicotización no es «solo promoción»: depende de S1

El §2 del handoff la pone tercera diciendo *«cinco entregas acreditadas en vivo en STG y ninguna en
PROD: aquí solo hay promoción»*. Medido nodo a nodo, esa premisa no se sostiene.

| Nodo nuevo | Qué necesita | En PROD |
|---|---|---|
| `Listar Cotizaciones` (tool de los dos agentes) | `$('Prepare Resolution Context').first().json.phoneNumberVariants` en su `queryReplacement` | **`Prepare Resolution Context` no existe** — es de S1 |
| `Cambiar Cotizacion` (tool de los dos agentes) | lo mismo | **no existe** |
| `Limpiar Turno De Cambio` | `chat_watermark`, que solo produce el `SELECT` de `Resolve Session` de STG — y ese SQL exige el mismo `$3` | **no existe** |

Y `phoneNumberVariants` **nace en ese nodo de S1**: no lo produce el `Session Context Builder` de PROD
ni el de STG. Comprobado en los dos.

**Por qué no es un detalle:** `$('Nombre')` exige ancestro real en el grafo y **lanza
`createNoConnectionError` en ejecución**, no al guardar. La promoción parecería exitosa y el bot se
rompería con el primer cliente que preguntara por sus cotizaciones.

**Las tres salidas:** (a) S1 primero y Multicotización detrás, trivial; (b) escribir
`phoneNumberVariants` en el `Session Context Builder` de PROD, que ya no es promover sino **implementar
una segunda copia** de la canonicalización de teléfono; (c) reapuntar las tools a otro nodo, que es (b)
con otra ropa porque el campo tampoco está allí.

**Recomiendo (a).** No traigo guion para la 3 a propósito: traerlo sería fingir que la decisión está
tomada. **Pregunta 1: ¿confirmas que Multicotización pasa a ir detrás de S1?** Si dices (b), lo hago,
pero quiero que quede escrito que es implementación y no promoción.

Aparte, **dos cambios que la clasificación había atribuido a Multicotización sí son promovibles solos** y
no dependen de S1: el override determinístico de precio (mitad del `jsCode` de `Parse Router Output`) y
las reglas de precio del `toolDescription` de `Get Quotation Data`. **Pregunta 2: ¿los saco a una
promoción propia**, o esperan con el resto? El primero exige partir el nodo, porque su otra mitad es el
intent `renovacion`, bloqueado por Django.

---

## 2 · Falta una credencial en PROD, y su token no lo tengo

Lo encontró la comprobación de precondiciones del propio guion, no yo leyendo: de las tres credenciales
que necesita el workflow de Atención Humana, **`Atencion Humana Header Auth PROD` no existe** — no
aparece en ningún workflow vivo de PROD.

**Pregunta 3: ¿quién la crea?** Es material privado (un token de header auth compartido con el
Dashboard), así que no es mío. El guion aborta en escritura si falta, y en ensayo avisa y sigue.

Y hay un **orden obligado** que conviene que esté en el runbook, porque no es evidente: los tres
`webhookId` los genera n8n **al crear** el workflow, así que no se conocen antes. La secuencia es
**crear (inactivo) → anotar los tres ids → cablear el Dashboard → activar**. Si se activa antes de
cablear, los webhooks existen y nadie los llama; si se cablea antes de crear, el Dashboard apunta al
vacío.

*(Detalle técnico por si te sirve en otro sitio: la API pública de n8n **no expone `GET /credentials`**
—solo crear y borrar—, así que la única forma de saber qué credenciales tiene una instancia es leer las
que usan sus workflows. Es lo que hace el guion.)*

---

## 3 · Lo que no pregunto porque ya está decidido o hecho

- **Atención Humana se promueve sin METEPEC**: medido, son tres aristas
  (`Phase Guard(1) → Human Takeover Guard → {Save…, Ban Guard}`), y no necesita `Metepec Guard`.
- **`Resolve Session` no se promueve entero**: solo se le añade `ws.human_takeover` al `SELECT`, porque
  su SQL de STG depende del mismo nodo de S1. Lo declaro como paso hacia el estado final y no como
  divergencia: el `SELECT` de STG **también** trae esa columna, así que acerca PROD a STG en vez de
  separarlo. Si prefieres que espere a S1 y Atención Humana entera vaya detrás, dilo y la aparco — pero
  entonces la iniciativa que más valor entrega espera a un dictamen ajeno.
- **El gate de escritura de los 10 writers no entra** en esta promoción: es defensa en profundidad y la
  promesa la cumple el guard, que corta antes del agente. Va en su promoción propia.

## 4 · Y un cabo de inventario, sin acción

En PROD hay un workflow **`WhatsApp Insurance Quotation Bot copy`**, inactivo, que no está en el
`TARGETS` de `detect-drift.py` ni en ningún documento. No molesta, pero nadie lo vigila y nadie sabe de
cuándo es. Borrarlo o adoptarlo no es decisión mía.
