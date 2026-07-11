# Bug #8 — `_generar_bloque_492` no incluye teléfono celular en XML SOAP a Quálitas

**Sistema:** Django · **Estado:** ✅ Resuelto (verificado 10 jul)

## Fila de la tabla original

| 8 | ~~`_generar_bloque_492` no incluye teléfono celular en XML SOAP a Quálitas~~ | Django | ✅ Resuelto — ver detalle abajo |

## Detalle Bug #8 (RESUELTO — verificado 10 jul)

**Detalle Bug #8 (RESUELTO — verificado 10 jul):**
- Trazabilidad original: el dato llegaba correctamente hasta `_generar_bloque_492` en `qualitas/services.py` pero el método no llamaba a `d.get('telefono')` — campo nunca se añadía al XML.
- **Fix aplicado por Juan** (commit `eaa48bb`, "fix: enviar celular del asegurado a qualitas", 2 jul): `_generar_bloque_492` ahora normaliza el teléfono (`telefono_digitos`, quita prefijo `52`/`521` si viene con 12-13 dígitos) y agrega `<ConsideracionesAdicionalesDA NoConsideracion="40"><TipoRegla>86</TipoRegla><ValorRegla>{telefono_digitos}</ValorRegla></ConsideracionesAdicionalesDA>` cuando el resultado son exactamente 10 dígitos.
- **Verificado por el Arquitecto (10 jul):** commit confirmado ancestro directo de lo desplegado en producción ahora mismo (`65e313d`, release Heroku 313 del 10 jul) — el fix lleva más de una semana en vivo. Issue `aguayo-co/HYL-WAI#70` cerrado el mismo 2 jul.
