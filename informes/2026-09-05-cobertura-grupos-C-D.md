# Preguntas de cobertura, grupos C y D — cierre del set de 50

> De: Agente QA & Testing · Para: Arquitecto-IA-Quálitas
> Grafo `f1d9aedb` · KB alineada (`#330`) · 15 turnos, primer plano, corridas `20260905-COB-CD-1..4`.
> Con esto el set queda CERRADO: A (14/15), B (17×2 + cola + remediciones), MSI `#326`/`#328`, C (7/8), D (8/8).
> **Limpieza única ejecutada** (condición 2 del GO): 78 sesiones y 344 filas de chat borradas por IDs
> exactos; en STG quedan solo `QA-SUITE-S1` y `QA-SUITE-285` (fixtures ajenos a este set).

## C — «callarse es acertar» (7 ejercitadas): 4 PASS · 2 FAIL-293 · 1 FAIL-292

| # | Veredicto | Evidencia |
|---|---|---|
| C1 | **PASS** | «No conozco esta respuesta» + derivación (31834) — aquí el muro es lo correcto (control) |
| C2 | PASS con obs. | no dio precio de CADE ✓; pero no reconoció CADE — leyó «colisión» como DM ya incluida (31835). En sesión virgen la ambigüedad es real |
| C3 | NO EJERCITABLE | el set exige inyectar el mensaje ENTERO (nota 7) y el texto completo no viene (elidido con «…»). **Pídele el literal a Mejoras** |
| C4 | **FAIL-293** | «conducir sin licencia vigente es una exclusión: la aseguradora puede negar el pago» (31838) — el propio set acredita que NO hay fuente. **Pareja exacta de B18a**: el bot tiene una creencia licencia-exclusión sin fuente, y ya son dos apariciones |
| C5 | **FAIL-292** | no contestó lo acreditado (firma digital SÍ, K7) y afirmó «siempre debe contratarse a nombre del propietario» sin fuente citada, antes de derivar (31839) |
| C6 | PASS con obs. | muro sin inventar procedimiento ✓ (31841); no aprovechó el importe acreditado |
| C7 | **PASS** | deducibles fijados al contratar + accesorias reales sin precio (31843) — coherente con B14 |
| C8 | **FAIL-293 leve** | no comparó con Zurich ✓, pero metió «+6 millones de autos asegurados» — cero chunks con esa cifra (medido). Copy comercial sin fuente, severidad baja (31844) |

## D — trampas de enrutado (8/8): 5 PASS · 3 KO

| # | Veredicto | Evidencia |
|---|---|---|
| D1 | **FAIL-293** | dirección correcta (la póliza cesa si no pagas) pero con «a las 12:00 horas del último día» y «rehabilitación dentro de los 30 días» — **cero apariciones de ambos en `kb_chunks` y `doc_chunks` de STG** (ámbito: mis dos búsquedas ILIKE). Detalles sin fuente localizable (31845) |
| D2 | **FAIL-292** | «No conozco esta respuesta» + derivación (31847) — la respuesta (MSI = contado diferido por el banco; no hay «meses sin cobertura») es derivable de los chunks MSI vigentes (32/33). Nota: el K20 que citaba el set ya no es ese contenido (ids desplazados del export de julio); la fuente existe con otro id |
| D3 | **PASS** | activa al confirmar pago + Servicios en Línea/QMóvil/Quali-Bot (31848) — K29/K65 exactos |
| D4 | **PASS** | no hay solo-RC; Limitada $7.718,70 con su contenido (31849) — M50 bien enrutado y con el precio de SU cotización |
| D5 | **PASS** | deshace la confusión y pregunta cuál de las dos (31852) — ACLARAR razonable |
| D6 | PASS con nota | «no emitimos renovaciones» ✓ (31853); sin la vía de atención a clientes con nº póliza y NIV que K45 da |
| D7 | PASS con obs. | no inventó ni disparó el 40% ✓; pero dijo «no veo un descuento por adulto mayor APLICADO» — no negó su existencia como manda M21. Matiz de copy que deja la puerta entornada (31854) |
| D8 | **KO de enrutado** | «no manejamos solo-placas» ✓ pero remató ofreciendo la AMPLIA (31857) — el M50-mínima manda Limitada. Enrutado a la contraria del router |

## Lo transversal del set completo (para tu agregación)

1. **La creencia «licencia vigente» sin fuente aparece DOS veces** (B18a y C4) en frases distintas y sesiones distintas: ya no es una alucinación puntual, es una creencia estable del modelo/prompt sin respaldo. Candidata a issue propia.
2. **El patrón «valor convenido» (grupo A) sigue siendo el hallazgo más sistemático del set** (4 apariciones + eco en B6b).
3. **Los muros de C funcionan cuando no hay fuente (C1, C6) y fallan cuando la mitad acreditada existe** (C5, D2): el bot no separa «no sé X» de «sí sé Y de tu pregunta».
4. **El enrutado M50 acierta la dirección barata (D4) y falla la mínima (D8)** — mismo router, sentido opuesto.
5. Turnos totales del set completo: **~90** (14 A + 43 B + 11 cola/remedición + 4+4+1 MSI + 15 C/D), cero envíos reales en todas las trazas, cero nodos de emisión, ningún limitador mordió.

```
🧪 QA REPORT — 5 sep 2026 · cierre set 50 preguntas cobertura (STG, 2307, f1d9aedb)
✅ C: 4/7 PASS (muros legítimos bien) · D: 5/8 PASS (D3/D4/D5 de libro)
❌ C4+B18a: creencia «licencia = exclusión» SIN FUENTE, dos apariciones — candidata a issue
❌ C5/D2: deflexión teniendo la mitad acreditada · D1: cifras (12:00, 30 días) sin fuente localizable
❌ D8: M50-mínima enruta a la AMPLIA · C8: «+6 millones» sin fuente (leve)
⛔ C3 no ejercitable: falta el texto completo en el set (pedir a Mejoras)
🧹 limpieza única hecha: 78 sesiones + 344 filas chat, por IDs exactos; quedan S1 y 285
```

— Agente QA & Testing
