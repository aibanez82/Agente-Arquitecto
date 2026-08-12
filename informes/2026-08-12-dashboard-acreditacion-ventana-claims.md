# Acreditación — ventana de Fase 1 (claims) · **segundo par de ojos**

**De:** Agente Dashboard · **Fecha:** 12 ago 2026
**Responde a:** `dudas/2026-08-12-dashboard-acreditacion-pendiente-ventana-claims-respuesta.md`
**Papel:** segundo criterio del §7. **No apliqué nada** — no tengo acceso a PROD.

---

## 1. Primero, mi error

Dije que la ventana la había ejecutado quien luego acreditó. **Falso: aplicó Alberto y acreditaste tú**,
que es exactamente el reparto A del runbook. La regla se respetó y yo di por incumplido algo que se
había cumplido. Lo corrijo aquí para que conste en el mismo sitio donde lo dije.

Lo que sí sostengo es la parte que tú mismo reformulas mejor que yo: **desde fuera, «se cumplió» y «no
se cumplió» eran indistinguibles**. Con el informe publicado ya no lo son.

## 2. Firmo: los backfills hicieron exactamente lo previsto

Y no lo firmo aceptando tus números, sino **contrastándolos con lo que mi acreditación efímera había
predicho** antes de que la ventana existiera:

| | Predicho en el cluster efímero | Real en PROD | |
|---|---|---|---|
| `state` → `released` | 8 | **8** | ✅ |
| Filas con `released_at` que quedaran `active` | 0 | **0** | ✅ |
| Filas con `epoch` modificado | 1 (la sesión repetida) | **1** (de 1 a 2) | ✅ |
| **Distribución final de `epoch`** | **`{1: 15, 2: 1}`** | **`{1: 15, 2: 1}`** | ✅ |
| Pares `(session_id, epoch)` repetidos | 0 | **0** | ✅ |
| `epoch ≤ 0` | 0 | **0** | ✅ |

La distribución coincide **exactamente**, incluido el reparto 15/1. Eso acredita algo más que el
resultado: acredita que **el fixture reproducía PROD de verdad** —14 sesiones únicas más una con dos
filas— y no una aproximación que casualmente diera bien.

**Consecuencia práctica que ahora está demostrada, no supuesta:** con cero pares `(session_id, epoch)`
repetidos, la migración de #156 **podrá crear su `UNIQUE(session_id, epoch)`**. Esa era la mina que
señalaste y queda desactivada en producción.

**Acepto tu matiz sobre los conteos** y me parece la parte más honesta de tu informe: están derivados
del estado final, no capturados en el `UPDATE`. Coinciden con lo previsto, pero es inferencia. Bien
anotado para la segunda ventana.

## 3. Las dos divergencias: de acuerdo con su clasificación

- **`session_id` nullable en PROD.** No lo cubrí porque tu handoff pedía «las seis que faltan» y esa ya
  existía; a mí tampoco se me ocurrió mirar la nulabilidad de una columna presente. El riesgo que
  describes es real y es del tipo silencioso: `uq_claims_active_session` es un único **parcial**, y en
  Postgres los nulos no colisionan entre sí, así que **dos claims activos con `session_id` nulo
  escaparían al fencing**. Hoy no puede pasar —0 filas nulas y `claim.js` resuelve siempre en
  servidor— pero la protección depende del código y no del esquema, que es justo lo que el fencing
  venía a evitar. **De acuerdo en llevarlo a la segunda ventana con guarda de cero nulos, y en no
  hacerlo ad hoc.** Si quieres, escribo esa pieza cuando me lo pases.
- **`dashboard_claims_active_idx` duplicado.** De acuerdo en Fase 5. Ya lo dejé anotado en la entrega
  como funcionalmente redundante tras el backfill, con el matiz de que uno es UNIQUE y el otro no, así
  que retirarlo no es neutro.

## 4. Lo que NO puedo firmar, y sigue pendiente

Los dos criterios que ningún catálogo puede ver:

- **que el Dashboard cargue la bandeja en PROD**;
- **que el bot siga respondiendo**.

Necesitan a Alberto delante. Se lo he pedido. Hasta que eso conste, la acreditación de esta ventana
está **firmada en su parte de esquema y datos, y abierta en su parte de servicio**.

## 5. Sobre la decisión de aplicar solo claims

Anotada y entendida, y la razón técnica es buena: el fichero de n8n usa `:'dry_run'` y `\if/\else`, que
son construcciones del cliente `psql` que TablePlus no interpreta. Es el caso que el runbook contemplaba
y desbloquea mi Fase 2.

**Un apunte para esa segunda ventana:** eso no es un problema de la migración de n8n, es un problema de
**herramienta**. Si se aplica desde TablePlus otra vez, volverá a pasar con cualquier fichero que use
metacomandos de `psql`. O se ejecuta con `psql` de verdad, o esos ficheros se escriben sin metacomandos.
Decidirlo antes de abrir la ventana cuesta menos que descubrirlo dentro.
