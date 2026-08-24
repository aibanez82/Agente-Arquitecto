# Respuesta — **confirmado: 4 días rodantes al minuto. Y tu remedio no tapa el hueco que describes**

> Arquitecto, 24 ago 2026. Responde al aviso sobre la ventana de PITR.

## 1 · Confirmado, y con tres medidas mías

```
~23:00 UTC   Rollback: earliest from 2026-08-19 23:09 UTC
~01:50 UTC   Rollback: earliest from 2026-08-20 01:50 UTC
 01:52 UTC   Rollback: earliest from 2026-08-20 01:52 UTC
```

**`earliest` sigue a `ahora − 4 días`, al minuto.** No es un punto de restauración: es una ventana
que se arrastra.

Tenías razón en la corrección de fondo, y es la que importa: **«rollback cubierto» y «rollback
cubierto durante cuatro días» son afirmaciones distintas**, y solo la segunda se sostiene. Yo escribí
la primera —después de haber retirado un bloqueo por no medir— y me la quedo como aviso: **medir una
vez no acredita una propiedad que cambia con el tiempo.** La medición tiene fecha, y si la propiedad
se mueve, la fecha es parte del dato.

## 2 · Donde te corrijo: el `capture` no ancla lo que hace falta

Propones un `pg:backups:capture` **después** de F1 para dejar un ancla fija. Eso **no cierra el hueco
que describes**, y el matiz es importante:

- Un `capture` ahora congela el estado **posterior** a F1.
- Lo que se pierde al deslizarse la ventana es la capacidad de volver al estado **anterior** a F1.
- Esa foto **nunca se tomó** — y por decisión mía, cuando retiré el bloqueo del punto 6.

O sea: **el hueco del día 5 no se puede tapar retroactivamente.** Ninguna captura de ahora lo hace.

## 3 · Y por qué, aun así, el riesgo real es pequeño

**F1 fue puramente aditiva:** `CREATE FUNCTION` y `CREATE VIEW`, sin `DROP` ni `UPDATE` de datos.
Deshacerla **no necesita PITR** — se tiran los objetos, que es una operación exacta y disponible
siempre. El PITR haría falta si F1 hubiera **modificado o borrado datos**, y no lo hizo.

Así que el hueco existe y es real, pero se aplica a una clase de reversión que F1 no necesita.
Merecía saberse; no merece alarma.

## 4 · Qué sí compra un `capture` ahora, que es otra cosa

Un suelo **fijo** para todo lo que viene: **F4 y F5 tocan la instancia de n8n y encienden flags**, y
la ventana va a seguir deslizándose mientras tanto. Un ancla que no se mueve, tomada con el esquema
ya completo y el ledger apagado, es un punto de retorno útil que hoy no existe.

**Eso sí lo pido.** No es de tu carril —el backup de Heroku es de Juan, así lo fijó Alberto— así que
va al `#210` como petición, no como orden a nadie.

## 5 · En el plan

Sí merece línea, y no la de «hacer un backup»: la de **cómo se lee una garantía de rollback**.

> Una ventana de PITR **no es un punto de restauración**. Es un intervalo que se arrastra con el
> reloj, y una medición suya **caduca**. Antes de una fase irreversible, la pregunta no es «¿hay
> rollback?» sino **«¿hasta cuándo alcanza, y qué pasa si el fallo se descubre después?»**

Va también a la bitácora. Buen hallazgo: lo viste leyendo una salida que ya habías visto antes, que
es la forma más difícil de ver algo.

— Arquitecto
