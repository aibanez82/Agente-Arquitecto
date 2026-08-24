# Acuse — F1 cerrada. **Verificado contando, y el informe dice la verdad en todo**

> Arquitecto, 24 ago 2026. Acusa `informes/2026-08-24-n8n-f1-capa-s1-aplicada-en-prod.md` (`524ceff`).

## Lo que medí yo contra PROD, sin leer tus recuentos primero

```
funciones n8n_*   45 nombres (47 filas con overloads)   [objetivo 45]  ✅
vistas de la capa 7 de 7                                                ✅
  conversation_control_v1 · dashboard_discount_application_v1
  dashboard_discount_terminal_notification_v1
  discount_conversation_activation_evidence_v1
  discount_history_inheritance_evidence_v1
  n8n_discount_application_handoff_v1 · n8n_discount_offer_sent_v1
trg_n8n_chat_histories_advisory_lock   ausente                          ✅
funciones del port-132                 2 de 2                           ✅
```

Coincide con lo tuyo en todo. **F1 cerrada.**

Y quiero subrayar la comprobación que más valor tiene y que es la que más fácil se omite: **el
trigger ausente**. Un recuento de funciones correcto con el trigger puesto habría sido un falso
verde, y lo acreditaste tú además con «0 triggers no internos en la tabla», que es mejor que
comprobar solo su nombre.

## La desviación de orden: correcta, y bien documentada

Aplicaste la `163/001` antes de la `156/020`. **Fui a comprobarlo y la desviación la dicta el propio
artefacto, no tu criterio:**

```
156/020 línea 38:  -- ORDEN. Va DESPUÉS de `migrations/163/001`, cuya cirugía este cuerpo ya incluye
156/020 línea 83:  RAISE EXCEPTION 'STOP/PRE/156-020: falta la cirugía de la 163 … Aplica
                    migrations/163/001 primero. Nada escrito.'
```

**El orden equivocado era el de mi handoff**, que decía «`156` → `161` → `163`» por numeración en
lugar de por dependencia. Segunda cosa que el handoff pedía mal —después del `48`—, y las dos las
absorbió el artefacto porque sus guardas están bien hechas.

Que lo documentaras en vez de aplicarlo callando es lo que hace la diferencia: una desviación
silenciosa habría sido indistinguible de un error.

## El residuo de STG: confirmado, y no se toca hoy

Repetí el diff de firmas y sale exactamente lo que dices:

```
solo en STG:  n8n_discount_conversation_handoff_claim(p_now timestamptz)
solo en PROD: ninguna
```

Y la `156/012` se llama `retira-sobrecarga-handoff-claim`: su cabecera explica que la `010` y la
`011` crearon dos firmas del mismo nombre porque el `CREATE OR REPLACE` no sustituyó nada, y su línea
113 hace el `DROP`. **PROD quedó más limpio que STG**, no al revés.

**No lo limpies.** Razones, en orden:

1. STG es hoy la referencia contra la que se valida F4. Moverla mientras se compara es cambiar el
   metro a mitad de medición.
2. Merece saber **por qué** la `012` no dejó el estado que declara — si no corrió, o si algo recreó
   la sobrecarga después. Borrar el síntoma sin esa respuesta pierde el hallazgo.

Queda como tarjeta, con la del CI y la de la guarda de catálogo. Las abro cuando Alberto lo diga.

## Estado

**F4 desbloqueada por el lado de la base.** Su camino crítico son ahora los dos auxiliares de PROD
—`Error Handler` e `Issue Policy Guard`—, que no dependen de nada más. Sin el segundo, la emisión de
pólizas de producción llamaría al guard de staging.

No arranques nada de eso: F4 es otra fase y llegará con su handoff y su GO.

Buen trabajo hoy, y lo digo por algo concreto: **paraste dos veces** —en la vista inesperada y en la
`003`— y las dos veces el motivo era real. La segunda evitó que el hueco del port-132 se descubriera
en F4, con el bot ya importado y clientes dentro.

— Arquitecto
