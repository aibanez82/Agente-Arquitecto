# Informe — SESIÓN A · mensaje de emisión determinista en STG (punto c)

**De:** Agente n8n · A · **Para:** Arquitecto · **15 oct 2026**
**Orden:**
- `Agente-n8n:handoffs/2026-10-14-A-firmas-orden-prod-591-y-cola.md`, fila c;
- el diseño `dudas/2026-10-10-n8n-A-mensaje-emision-determinista.md` (`9f67aaa`) y su respuesta `dudas/2026-10-10-n8n-A-emision-y-resumen-respuesta.md`.

**Textos de la bandeja, literales:**
- la base de contado, que es la plantilla del prompt;
- `emision-fraccionado`;
- `emision-sin-link`, variante **b1**.

**PROD:** nada. Necesita orden aparte de Alberto, porque toca la emisión.

## Import (uno, solo el bot)

| Workflow STG | Antes → después | Nodos |
|---|---|---|
| Bot `dNqtM20ij6ecZYAX` | `387fee41` → **`820c08d4`** | 5 nuevos: `IF Componer Emision?`, `Lee Poliza Emitida`, `IF Hay Poliza Del Turno?`, `Pide Liga Emision`, `Compone Mensaje Emision`. 1 tocado: `URL Fidelity Guard` |

- **Verificación:** hojas y `connections` iguales al candidato; el bot sigue activo; el export, sincronizado a `stg`.
- **Respaldo:** `backups/emision/`.
- **Código:** rama `fix/firmas-paquete-prompt-stg`, en `6e64fd37` y `af233ce4`. Fuente única: `scripts/emision/emision.js` (batería 24/24).

## Qué hace

**Cableado:** `Apply Guardrail Result` (#591) → `IF Componer Emision?`. La condición es que `exists_real` y `afirmaEmision` sean los dos ciertos; si no, se va a `Strip Guardrail Marker` como hoy.

1. **`Lee Poliza Emitida` (solo lectura).**
   - Busca la fila de `qualitas_polizaemitida` de la cotización **cuyo número aparece en un mensaje `tool` de ESTE turno**, es decir, posterior a la marca de agua.
   - Esa condición es la que implementa tu punto 3: «solo cuando narra la emisión», y además en el turno en que se emitió. Una pregunta posterior («¿ya quedó emitida?») no recompone el mensaje.
   - Si encuentra varias filas, prefiere la del número que afirma el mensaje.
2. **`IF Hay Poliza Del Turno?`.** Sin fila → el texto del modelo, ya validado por el #591.
3. **`Pide Liga Emision`.** Llama a la **misma** API y con la **misma** credencial que la tool `Ensure Payment Link` (`POST /api/n8n/payment-link/ensure/`), con timeout de 10 s y `continueRegularOutput`.
   - Es fail-closed, con el mismo criterio que la tool: la liga solo vale con `200` + `status=available` + `payment_url` HTTPS.
4. **`Compone Mensaje Emision`.** Usa la plantilla firmada, con «emitida exitosamente» literal.
   - **Fraccionado** solo si están las tres cifras: primer pago, subsecuente > 0 y número de pagos. Si falta alguna, va el texto de contado.
   - **Sin liga:** el final se sustituye por b1.
   - **No compone, y sale el texto del modelo,** si falta el número, el vehículo o el monto total, o si la cobertura no está en la tabla de valores amigables. En la tabla solo están el `1` y el `3`, igual que en `Rebuild Summary`; PROD tiene 1 póliza con paquete `2` de 86.
   - **Sin nombre:** «¡Listo! 🎉».
5. **`URL Fidelity Guard`.** Admite como fuente del grafo la liga que pidió `Pide Liga Emision`, y solo esa.

## Aceptación (arnés)

**Montaje:**
- Guard temporal con la emisión **simulada**, devolviendo la póliza que **ya existe** en STG para la cotización: 3005, contado, `7620104155`; 5539, mensual, `7620104236`. Así el #591 valida igual que con una emisión real.
- La liga se simula por sufijo de sesión, salvo en el caso «API REAL».
- Para emular la emisión **a mitad de turno**, la variante `--poliza-a-mitad` vacía la fuente de póliza de `Resolve Session`.

| Caso | N=5 | Póliza a mitad, N=2 | Vivo `820c08d4`, N=1 |
|---|---|---|---|
| Contado con liga = plantilla firmada exacta | 5/5 | 2/2 | 1/1 |
| Mensual con liga = fraccionado firmado exacto (primer pago $2,197.89 + 11 de $1,304.70) | 5/5 | 2/2 | 1/1 |
| Contado, liga 503 → final b1 | 5/5 | 2/2 | 1/1 |
| Mensual, liga 202 → fraccionado + b1 | 5/5 | 2/2 | 1/1 |
| **API REAL** de STG (3005) → sin liga | 5/5 | 2/2 | 1/1 |
| Control: pregunta después de emitir → no recompone | 5/5 | 2/2 | 1/1 |

En el caso de la API real, la respuesta fue **`503 temporarily_unavailable`**, no `already_paid` aunque la póliza está pagada. Funciona igual porque todo lo que no es `available` cuenta como sin liga. Lo que devuelva la API en PROD justo después de emitir **no lo he ejercitado**.

**Controles de admisión (#179):**
- **`URL Fidelity Guard` sin tocar:** 0/4. El mensaje entero pasa a «Ese dato no lo tengo aquí a la mano…» porque la liga del grafo no está en `URL Sources`. **Entra.**
- **`Figure Fidelity Guard`:** había previsto ampliarlo con las cifras de la fila del turno. Sin esa ampliación pasa 4/4, también con la póliza a mitad de turno. Como no puedo nombrar el defecto que atraparía, **no entra**.

**Regresión sobre el vivo `820c08d4`:** el #543 da 7/7, incluido su caso de respaldo del #591. Además, el respaldo técnico del #591 no cambia: con la narración sin validar, la rama falsa del IF va directa a `Strip`.

## No ejercitado
- Una emisión **real** contra Quálitas QA. El arnés simula `Call Issue Policy Real`.
- Con Sonnet 5.5: no medido (el bot de STG va con Sonnet 5).
- La respuesta de la API de liga en PROD justo después de emitir.

Agente: Agente n8n · A
