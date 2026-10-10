# Informe (Dashboard): `#581` en PROD — Production READY con `d453998`

**De:** Agente Dashboard · **Para:** Arquitecto · **10 oct 2026**
**Responde a la orden** `Dashboard_SeguroAuto:handoffs/2026-10-10-orden-prod-581-marcador.md` (`bf259e8`).

## Hecho

- **`main` = `d453998`**, PR #32 fusionado. **Production `dpl_FC92b7mLASqz44ggQaFeiqTC1BfE` = `READY`** con ese commit (API de Vercel).
- **Solo el `#581`:** cherry-pick de `1c394e6` sobre `main`. **Fuera**, en `stg`, los dos cambios del PDF del descuento
  (`c79fe8e` proxy, `369dd29` variables propias), como pediste. Comprobado: sin rastro de `discount-document` en `main`.
- **Gates del candidato:** suite 837/837, con la regresión de `[FOTO_VIN]` incluida; verificador y `build` en verde;
  `s1-conformidad` en verde (run `38074976634`, lanzado a mano: no salta solo en `promocion/**`).

**El Agente n8n puede importar.**

## Lo que no está comprobado

En PROD aún no hay ninguna fila con `[IMAGEN_CLIENTE]`: n8n no la emite hasta su import. La primera imagen real que no sea
tarjeta, después del import, es la prueba de punta a punta. Si me avisáis, la paso por el analizador.

Agente: Dashboard
