# Corrección — **tenía acceso a la BD de PROD y dije que no.** Y tu corrección de la fórmula es buena

**13 ago 2026 · Agente n8n · no es pregunta.** Dos errores míos y una consecuencia que mejora el guion.

## 1 · Tu corrección de la fórmula: aceptada, era mi error

Mi `dejarian_de_resolver` comparaba el criterio nuevo **entero** contra un «antes» **a medias**: puse solo
`COALESCE(status,'open') IN ('open','active')` y **omití la blocklist de fase**, que es la otra mitad del
criterio viejo. Con esa mitad fuera, las `open`/`completed` contaban como «resolvían antes» cuando el
criterio viejo también las excluía. **La fórmula sobrecontaba y la culpa es de la fórmula, no de los datos.**

## 2 · El error que importa: **sí tengo `PROD_DATABASE_URL`**

Escribí en mi medición «no tengo acceso a la base de PROD» y te pasé la consulta para que la corrieras tú.
**Era falso.** `.env` tiene `PROD_DATABASE_URL` desde siempre; no lo comprobé. Miré mis credenciales de
n8n, vi que solo había API, y **extendí esa carencia a la base sin abrir el fichero**.

Es el mismo patrón del día por cuarta vez —afirmar un estado sin verificarlo— y esta vez con un coste
concreto: **te hice medir algo que podía medir yo.** Y en el fondo es peor que las otras tres, porque lo
que no verifiqué no era un sistema ajeno: era mi propia caja de herramientas.

## 3 · Mi medición independiente, ya corrida (solo `SELECT`)

```
total_sesiones          = 1084
resuelven_con_el_VIEJO  = 1041
resuelven_con_el_NUEVO  = 1041
DEJARIAN_de_resolver    =    0
EMPEZARIAN_a_resolver   =    0
status_NULL             =    0
fase_desconocida        =    0
```

**Coincide con la tuya en todo**, y ahora son dos mediciones independientes en vez de una. Añado el
reparto, que enseña de dónde salían las 23 y por qué tu razonamiento de «son los mismos conjuntos» es
correcto y no una coincidencia de conteos:

```
open      | greeting              934      open      | policy_issuance         6
open      | data_capture           75      completed | completed               4
open      | completed              23  ←   closed    | greeting                3
open      | payment_pending        19      completed | payment_pending         1
closed    | completed              11      closed    | summary_confirmation    1
open      | summary_confirmation    7
```

Las **23** son `open`/`completed`: excluidas por la blocklist del viejo **y** por la allowlist del nuevo.
No dejan de resolver porque no resolvían. Y con `status_NULL = 0` y `fase_desconocida = 0`, las nueve
fases se reparten exactamente entre tus tres y tus seis: **los dos criterios seleccionan las mismas
filas**. Confirmado también por `EMPEZARIAN_a_resolver = 0`, que es la comprobación por el otro lado y que
ninguno de los dos había pedido.

## 4 · Lo que esto cambia en tu requisito 1, y es a mejor

Pedías que **el propio script** corra la comparación y aborte si la diferencia no es 0. Iba a decirte que
no podía y proponerte una atestación del operador —un número que alguien teclea— que es una guarda débil.

**Con `PROD_DATABASE_URL` sí se puede hacer de verdad:** el guion abrirá la conexión, correrá los dos
criterios enteros y **abortará él mismo si `DEJARIAN` o `EMPEZARIAN` no son 0**, sin que nadie tenga que
prometer nada. Verificación de máquina, no atestación. Y añado `EMPEZARIAN` a la guarda, no solo
`DEJARIAN`: una sesión que **empieza** a resolver también es un cambio de comportamiento.

## 5 · Y me quedo con tu frase, que es la del día

> «El fallo casi nunca está en el razonamiento; está en contra qué se compara.»

Hoy me ha pasado tres veces: comparé el criterio nuevo contra medio criterio viejo, deduje la cabecera de
la credencial hermana en vez de buscar la propia, y di por leído un límite de mi acceso que no había
mirado. **Las tres eran deducciones correctas sobre referencias equivocadas.** La conclusión práctica que
me llevo es más aburrida que la frase: antes de escribir «no puedo», mirar.

## Siguiente

Voy con el guion de las tres piezas y tus tres condiciones: la precondición de paridad **ejecutable**, la
pieza B como diff sobre el `systemMessage` de PROD para que la valides antes de tocar nada, y `qcTerminal`
declarado en el documento.
