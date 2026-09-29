# Informe — `#493` pieza 1 en `stg`: la antigüedad de la toma ya se ve y se puede ordenar por ella

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **29 sep 2026**
**Continúa:** `informes/2026-09-29-dashboard-417-y-tomas-sin-soltar-informe.md`

`Dashboard_SeguroAuto@stg` = **`d510f57`** (rama `feat/antiguedad-de-la-toma`, merge `--no-ff`).
Gates: **659 tests, 657 pass, 0 fail** (+12 nuevos) y **`npm run build` de Next en verde** — lo pongo
aparte a propósito: los tests de componente de esta casa son aserciones sobre el *texto* del fichero,
así que el build es lo único que acredita que el JSX compila. Deployment
`dpl_5yuJaKCvPavQj8cnC5fJyED9k6Js` **READY**. Nada a `main`.

## Lo que se ve ahora

1. **La insignia dice desde cuándo:** `👤 Montserrat · hace 11 d`. Neutra el primer día, **ámbar a las
   24 h**, **roja a las 72 h**. Los colores son los pares ya en uso de «Esperando» y «Abandonado»:
   `DESIGN.md` prohíbe paleta nueva y el significado es el mismo — tránsito que se alarga, y tránsito
   que ya se perdió.
2. **Orden «Tomadas hace más»**, junto al recuento. Fechadas de más vieja a más nueva, después las
   tomadas sin fecha legible, y las libres al final. **El orden se aplica después de filtrar**, para
   que el recuento del aviso y el de la lista sigan siendo el mismo dato — hay un test que fija ese
   orden de operaciones, no solo el resultado.
3. **En la conversación abierta**, al lado del botón de liberar: *«Tomada hace 11 d · el bot no puede
   contestar»*. Es el único sitio donde la frase cambia una conducta.

Los umbrales (24 h / 72 h) son **de la bandeja, no del contrato**: moverlos no cambia ningún estado,
solo cuándo se pinta. Están razonados en la cabecera de
`/Users/AIP/claude-projects/Dashboard_SeguroAuto/apps/operacion/lib/s1/antiguedadDeToma.js` y son un
parámetro tuyo si los quieres en otro sitio.

## Dos cosas que dejé fijadas para que no se deshagan por descuido

- **No se rellena `lease_expires_at`**, y el porqué va escrito en el fichero que más se va a leer (la
  cabecera del helper), no solo en este informe: una lease vencida lleva la conversación a
  `transitioning`, donde `canHumanSend` también niega al operador.
- **Si no se puede saber, no se pinta:** sin `claimed_at` legible la insignia se queda como estaba,
  nunca «hace 0 min»; y un `claimed_at` en el futuro —reloj del navegador por detrás del de la base—
  tampoco se dibuja. Con test.

## Lo que no puedo acreditar

**No hay foto.** El Preview de STG exige sesión y no introduzco credenciales, así que lo verificado es
build + tests, no una pantalla. Si quieres la captura antes de que esto viaje a `main`, hace falta que
alguien lo abra con su login.

Y, por lo mismo de siempre: que los 12 tests estén verdes no prueba que un operador vea lo que
queremos que vea. Prueba que el dato se calcula bien y que el componente lo referencia.

## Lo que no entra

Piezas 2 y 3 **sin tocar**, como dijiste. Nada a `main`; el PR #14 sigue esperando a Alberto.

— Agente Dashboard
