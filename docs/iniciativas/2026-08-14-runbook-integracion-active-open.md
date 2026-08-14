# Runbook — integración coordinada `open|active` y E2E de Descuentos

**14 ago 2026 · Arquitecto · Aplica: Alberto.**
**Autorización:** GO ya publicado por Juan en `#156`. *«No hace falta volver por otro GO antes del
merge/deploy a STG si todos esos gates están verdes.»*

**Lo que hace peligroso este runbook:** el merge a `stg` de `HYL-WAI` **dispara el deploy automático de
Heroku STG**. Es la única acción del día que se ejecuta sola después de un `git merge`.

---

## 0. Los dos gates que autorizan a empezar

| Lado | Estado | Evidencia |
|---|---|---|
| **Django** | ✅ **verde** | Juan, `#156`: boundary **35 passed** en PostgreSQL 17 desechable · manifiesto **88** · suite global **1049 passed, 63 skipped** · `check`, `makemigrations --check`, black, compileall, `diff --check` verdes · contrato Discounts PASS |
| **n8n** | ⏳ **pendiente** | rama `feature/issue-156-active-autoriza-vista` (`8b8b8d2`) con la `013`, las 7 pruebas y 2 contrapuntos — **falta su entrega con cifras** |

**No se empieza hasta que n8n publique su acreditación.** El GO de Juan es explícito: *con ambos lados
verdes*.

## 1. Orden de integración, y por qué este

**Primero n8n, después Django.** No es indiferente:

- el merge de n8n a su `stg` **no despliega nada** — sus workflows se importan a mano y el SQL se
  aplica aparte;
- el merge de Django a `stg` **sí dispara Heroku**.

Así que el que tiene efecto automático va **el último**, cuando todo lo demás ya está en su sitio.

```
1) Agente-n8n:  feature/issue-156-active-autoriza-vista  →  stg     (sin efectos)
2) HYL-WAI:     feature/issue-156-active-autoriza-outbound → stg    (⚠ dispara deploy Heroku STG)
```

**Gitflow que fija la decisión:** nada directo sobre `stg`, merge desde feature branch, árbol limpio,
SHAs publicados.

## 2. Tras el merge de Django: comprobar el SHA **desplegado**, no el mergeado

Es la lección del 13 de agosto, la que ya nos costó una vuelta: **una promoción se acredita contra el
entorno de destino, no contra su artefacto.**

```
heroku releases -a hyl-wai-stg -n 3
```

Tiene que aparecer un release nuevo con el SHA del merge. Si el release no aparece o falla, **para
aquí**: el resto del runbook asume que el consumidor nuevo está corriendo.

## 3. El SQL de la vista, en su propia ventana

La `013` **no se aplica sola**: es una migración y va con el mismo cuidado que las doce de esta mañana.

- ejecutar **`013-conversation-control-v1-1-active-autoriza.sql`** — trae envoltura transaccional
  propia, que la `002` no tenía;
- **adaptarla a TablePlus** si vuelve a traer los meta-comandos de psql (`\if :dry_run`), como el resto;
- verificar después, contra la BD:

```sql
-- la vista publica 'active' TAL CUAL y lo marca elegible
SELECT session_id, session_status, automation_gate, automation_reason_code
FROM public.conversation_control_v1
WHERE session_status = 'active';
```

**Lo que tiene que salir:** `session_status = 'active'` (**no** `open` — si sale `open`, la vista está
normalizando y eso es exactamente lo que la decisión prohíbe) y `automation_gate = 'eligible'`.

## 4. La prueba que de verdad cierra esto

**Escríbele «hola» al bot.** Es la Barrera 1, y hoy ha demostrado que vale: el fallo aparece con el bot
en la mano, no seis horas después leyendo código.

Si contesta, el camino está vivo por primera vez desde que empezó todo esto.

## 5. Y entonces sí, el E2E de Descuentos

El caso está escrito en `2026-08-14-caso-prueba-e2e-descuentos-stg.md`. Recordatorio de lo único
contraintuitivo: llegar a `data_capture`, **no dar los datos personales**, y esperar al **follow-up 2**,
que es el que trae la oferta del 35 %.

## 6. Si algo sale mal

| Dónde | Vuelta atrás |
|---|---|
| Deploy de Django | `heroku releases:rollback -a hyl-wai-stg` al release anterior |
| Vista `013` | la `002` sigue en el repo: republicarla devuelve la semántica anterior |
| Workflows | `workflows/vivo-stg-2026-08-14/` y los duplicados archivados |
| Módulo de Descuentos | el `UPDATE` de apagado del caso de prueba |

**Nada de esto es irreversible**, y esa es la razón de que el orden sea el que es.
