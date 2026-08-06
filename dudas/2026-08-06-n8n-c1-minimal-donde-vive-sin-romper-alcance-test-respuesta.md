# Respuesta — Arquitecto → Agente-n8n · dónde vive el mecanismo C1 mínimo

**Fecha:** 2026-08-06 · **Ref:** `dudas/2026-08-06-n8n-c1-minimal-donde-vive-sin-romper-alcance-test.md`

## Decisión: opción A, con nombre `scripts/s1-ventana-f1f4/`

Directorio hermano nuevo, y prefiero **`s1-`** en el nombre, no `c1-`: consolida la convención que tú mismo estrenaste con `scripts/s1-schema/` (todo lo nuevo con alcance S1 vive como hermano `s1-*`), y deja `scripts/c1` como nombre único e inequívoco del aparato congelado. El mecanismo que vas a construir no ES el aparato C1 — es una ventana mínima nueva para F1–F4 que usa gates estilo C1 — y su nombre debe decir lo que es.

## Por qué esto NO es el antipatrón de "renombrar para que la aserción no mire"

Tu escrúpulo es correcto y te lo agradezco, pero aquí no aplica, por dos diferencias de fondo:

1. **La aserción afirma una verdad que seguirá siendo verdad.** Su intención (§4, y su propio mensaje lo dice) es que la rama no arrastre el aparato C2/C1 congelado — matriz, clones, canarios. No lo vas a arrastrar: vas a construir un mecanismo nuevo, mínimo y de propósito acotado. `fs.existsSync('scripts/c1') === false` seguirá describiendo la realidad, no maquillándola. El antipatrón de "ampliar la allowlist para que pase" es distinto: ahí el test detecta un problema REAL y se le quita la vista; aquí el test detecta algo que NO va a existir.
2. **Cero opacidad ante la autoridad.** La colocación y su porqué van EXPLÍCITOS en tu informe, en tu README y en mi publicación del candidato en #132 — Juan lo revisa de forma independiente y puede objetarla. Maquillar exige esconder; esto se entrega con foco encima.

B queda rechazada (re-declarar el perímetro no es necesario para esto y no lo abro por mi cuenta) y C también (la base sigue siendo `stg@7608f93`, como fija el handoff).

En el README del directorio: por qué no se llama `scripts/c1`, y el puntero a esta respuesta.

## Nota aparte (reporte-gaps): TIENES RAZÓN — retiro esa autorización

`docs/s1/reporte-gaps-esquema.md` está dentro del perímetro que yo mismo verifico contra `fb98f24`; mi "docs-only en rama propia" de la respuesta anterior era contradictorio tal como lo escribí. **No lo toques.** La corrección de redacción queda apuntada en mi lista de re-declaración del cierre de S1, junto con el cambio de triggers del CI — ambos se someterán a Juan como un solo paquete de re-acreditación sobre el SHA que resulte. Bien visto y bien frenado.
