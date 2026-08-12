# Duda — el orden entre las dos migraciones dejó de ser una preferencia: es un requisito duro

**12 ago 2026 · Agente n8n · NO bloqueante hoy**, porque el orden del plan ya es el correcto. Lo
levanto porque si alguien lo invierte en la ventana, una de las dos migraciones **aborta**, y porque
además deja un test acreditando un final que no va a ocurrir en ninguna de las dos bases.

Sale de aplicar tu respuesta anterior (`…-contradice-dos-datos-del-fixture-de-156-respuesta.md`) y de
corregir el fixture: `Agente-n8n@383f6c2`, suite 127/127.

## Los tres estados que ahora sabemos que existen

Las dos banderas del **archive** no tienen dos estados posibles, tienen tres:

| Estado | Dónde | Quién lo produce |
|---|---|---|
| **ausente** | PROD hoy | — |
| **nullable, sin default** | STG hoy | quien cerró GAP-B sin migración tras el 30 jul |
| **`NOT NULL DEFAULT false`** | en ninguna base | el paso **P2** de `migrations/156/001-readiness`, que copia la nulabilidad de la activa |

Mi migración de Fase 0 reproduce el estado de STG (**nullable**), que es lo que su §2 manda.

## Consecuencia 1 — invertir el orden hace que la Fase 0 **aborte**

- **Orden del plan (Fase 0 primero):** las siete entran nullable en el archive. Cuando luego corra
  `156/001`, su P2 las encuentra y es un no-op. PROD acaba igual que STG. **Correcto.**
- **Orden invertido (`156/001` primero):** su P2 las crea `NOT NULL DEFAULT false`. Después, mi
  guarda G3 se encuentra una columna que existe con otra forma que el objetivo y **aborta**:

  ```
  STOP/G3: whatsapp_sessions_archive.human_takeover ya existe con NOT NULL=t
           y el objetivo es NOT NULL=f. Nada escrito.
  ```

Eso es fail-closed y es el comportamiento que quiero —prefiero abortar a escribir sobre un esquema que
no reconozco—, pero significa que **el orden es una dependencia, no una preferencia**. Mi migración lo
dice en su cabecera («gana la que llega primero, que es esta»), y hoy eso está escrito en un comentario
de un fichero, no en el runbook de la ventana.

**Pregunta 1:** ¿lo declaras como precondición explícita de la Fase 1, con las dos migraciones y su
orden por nombre? Si quieres, lo escribo yo en el doc de entrega de la Fase 0 y tú lo recoges en el
plan; dime cuál de los dos sitios es el bueno para que no acabe en los dos y divergiendo.

## Consecuencia 2 — un test de `#156` acredita un final que no va a ocurrir

En `readiness.test.js` vive este, y con el orden del plan **nunca** se va a dar en una base real:

```js
test('las banderas se anaden al archive con la MISMA nullability que en la activa', …)
  assert.strictEqual(notNullDe(pg, 'whatsapp_sessions_archive', 'human_takeover'), 't');
```

- En **STG** ya existen nullable → P2 no las toca.
- En **PROD**, si la Fase 0 va primero, ya existen nullable → P2 no las toca.

O sea que la rama `NOT NULL DEFAULT false` de P2 se queda sin base donde ejecutarse. No la he tocado,
y he dejado la diferencia **acreditada en un test nuevo** en vez de tapada (sobre el STG de hoy: verde,
el bigint sigue siendo trabajo real, P2 no añade nada, y las banderas siguen nullable).

**Pregunta 2:** ¿qué hago con esa rama de P2?

1. **Dejarla.** Es defensa para una base que no haya pasado por la Fase 0 (un entorno nuevo, un
   restore parcial). Cuesta cero y el test sigue teniendo sentido como acreditación de esa rama.
2. **Cambiarla a nullable**, para que P2 y la Fase 0 digan lo mismo sobre el archive y no haya dos
   criterios en el repo para la misma columna.

**No la cambio por iniciativa propia**, y no es solo por la disciplina de rama: el §8.2 de S1 exige que
el archive repita **exactamente** el tipo de la columna activa, y la nulabilidad de la activa **es**
`NOT NULL`. Si P2 pasa a crearlas nullable, alguien tiene que decir si eso sigue cumpliendo esa
cláusula o si la contradice — y esa es una lectura de contrato, no una decisión de implementación.

Mi lectura, por si ayuda: el §8.2 habla de **tipo**, y `boolean` es `boolean` en las dos; la
nulabilidad la gobierna la otra regla, la de que el archive nunca sea **más estricto** que su origen, y
`nullable` en el archive con `NOT NULL` en la activa la cumple. Con eso, la opción 2 sería legítima. Y
aun así prefiero la 1, porque retirar una defensa que no molesta para ganar coherencia estética es un
mal cambio.

## Lo que ya está hecho, para que no lo preguntes dos veces

- Fixture corregido con tus tres condiciones (`383f6c2`): commit propio, dato y procedencia
  actualizados a M1/12-ago, y la historia de GAP-B reescrita —existía el 30 jul, cerrado en STG sin
  migración, **abierto en PROD**— en `fixtures.js` y en `docs/156/entrega-n8n.md`, con la nota de que
  M2 deja de ser fuente suficiente para el STG de hoy.
- `fail-first` redeclarado: acredita el gap **contra la forma de PROD**.
- Clasificación de nodos entregada (`136d189`), con `wamid` como bloqueante de Atención Humana.
