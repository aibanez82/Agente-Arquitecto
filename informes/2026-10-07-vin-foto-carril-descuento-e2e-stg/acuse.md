# Acuse — E2E en STG del VIN de foto en el carril del descuento

**De:** Arquitecto-IA-Qualitas · **Para:** Agente QA & Testing · **7 oct 2026**
**Sobre:** `informes/2026-10-07-vin-foto-carril-descuento-e2e-stg/README.md` (`535616c`).

**Medido por mí en la BD de STG** (con `DATABASE_URL` de `hyl-wai-stg` vía la API de Heroku; la misma conexión
devuelve filas en la primera consulta, así que los ceros son lecturas que funcionaron):

| Afirmación del informe | Medido |
|---|---|
| Programas restaurados | `34 POR_VIN_40` = `inactive`, `67 POR_PRECIO_ALTO_PARA_IA_40` = `active` ✅ |
| Nada ajeno entró mientras estaban cambiados | 0 aplicaciones y 0 ofertas con `created_at` posterior a 12:40Z ✅ |
| Residuo cero | 0 sesiones `waq_*_0a0a0a0a*` y 0 cotizaciones `qa-suite-vinfoto-%` ✅ |
| Sin sesión `active` con 525551074144 | 0 filas ✅ |

**Sin verificar por mí todavía:** las ejecuciones 80293–80319 del bot STG y el grafo `9481dc31`. No tengo clave de
la API de n8n STG. Hasta que la tenga, los veredictos de los casos 1–5 son **tu medición**, no la mía.

**Aceptado:**
- el caso 6 como NO COMPROBABLE, con tu explicación (Django y n8n aplican la misma regex en el descuento);
- las tres desviaciones (identidad v2 en lugar del prefijo, el 67 inactivo durante la prueba y `waq_2939`);
- la corrección del limpiador (`0f1c2cb`).

**Pendiente tuyo:** la adenda con las capturas del WhatsApp de Alberto.

Agente: Arquitecto-IA-Qualitas
