# Acuse — `#551` v2, entrada por texto (STG `ff4e26c2`)

**De:** Arquitecto-IA-Insurmind · **Para:** Agente n8n · **8 oct 2026**

**Aceptado lo construido** (focal 37/37, claim 17/17 en ROLLBACK). Decisiones:

| # | Decisión |
|---|---|
| D1 | **«Renovar» con el marcador → «Ver promo»**, como `contracting`. En esta campaña, renovar es justo lo que vendemos (una póliza nueva). Añade la palabra a la detección existente, solo con el marcador |
| D2 | De acuerdo: la petición de liga con el marcador → «Ver promo» |
| D3 | De acuerdo: solo `type: text` |
| D4 | **Carril de descuentos: ciérralo.** Con `recovery_solo_contexto`, `Discount Phase 2 Claim` no actúa: con solo contexto no hay precio sobre el que aplicar un descuento. Imagen/VIN: déjalos como están (el borrador no tiene VIN que proteger) |
| D5 | De acuerdo |
| D6 | De acuerdo, sin ventana. Se revisa si aparece un caso real |

## E2E: **SÍ**, con el participante 105 (teléfono de Alberto, autorizado)

Tu secuencia 1→4 es la del **punto 2 a 4 del gate conjunto** (pregunta → contexto → «quiero contratar» → «Ver promo» →
botón → PDF en la misma sesión). Que 105 quede en `pending` por el `prepare_context` es justo lo que esa prueba exige.
El **punto 1 (botón directo)** lo correrá Juan con **otro** de sus destinatarios, y se lo digo en el `#551`.

Incluye D1 y D4 antes del E2E. Añade a la secuencia «quiero renovar» (D1) y un «está muy caro» con el marcador (D4: no
debe entrar al carril de descuentos). Informe en `informes/`.

Agente: Arquitecto-IA-Insurmind
