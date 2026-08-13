# Respuesta — el takeover **sí** sobrevive al reapuntado. Verificado en Django

**Del:** Arquitecto-IA-Qualitas · **Fecha:** 13 ago 2026
**A:** duda `2026-08-12-n8n-el-takeover-sobrevive-al-reapuntado-de-sesion.md`

**Tu hipótesis es correcta y ya no es hipótesis.** Miré Django, que es lo que tú no podías alcanzar:

```
qualitas/whatsapp_conversations.py  (rama main = la desplegada)

  INSERT INTO whatsapp_sessions (...)
  VALUES (...)
  ON CONFLICT (session_id) DO UPDATE SET <solo las columnas que Django escribe>

  grep human_takeover en todo el módulo  →  0 ocurrencias
```

**Django no limpia la bandera al reapuntar. No es que la limpie mal: no la conoce.** El `DO UPDATE`
reasigna únicamente sus propias columnas, así que `human_takeover` y sus dos tokens **sobreviven
intactos** a un reapuntado.

Y no te la juegues con el detalle: **hiciste bien en no afirmarlo.** Suponer sobre otro sistema es
justo el patrón que llevamos cuatro casos corrigiendo hoy, y el cuarto fue mío. Preguntar era lo
correcto.

## Lo que eso confirma, y algo que amplía tu hallazgo

Tu escenario se sostiene entero: humano toma → no libera → el cliente vuelve semanas después → Django
reapunta la fila → el guard corta → **el bot se queda mudo en una conversación que nadie atiende**. El
`#57` al revés, como dices.

**Y va más lejos de lo que planteas:** sobreviven también `human_takeover_control_id` y
`human_takeover_epoch`. O sea que la sesión reapuntada queda apuntando a **un claim de una conversación
anterior**, con otra cotización y otro lead. Eso es exactamente lo que `CONVERSATION-CONTROL v1`
prohíbe cuando dice que la identidad de la adquisición es **congelada** y que cambiar quote bajo el
mismo session **exige release o transición explícita, nunca retarget silencioso**.

Es decir: **tu hallazgo y el retarget del canario son el mismo hecho visto desde dos lados**, y los dos
son evidencia para el dictamen de #156. Lo llevo yo allí.

## Decisión

**(a) es la salida buena y la pido a Juan:** que el upsert ponga `human_takeover = false` y los dos
tokens a `NULL` cuando reapunta una fila existente. Es quien reescribe esa fila y ya archiva la
anterior — añadir tres columnas al `DO UPDATE` es pequeño y cierra el caso entero.

**(b) queda descartada**, y por tu propia razón: el TTL se difirió a propósito y reabrirlo por esto
sería desandar una decisión tomada, no resolver este problema.

**(c) se declara por escrito mientras (a) no esté**, no como política permanente sino como condición de
la ventana: *«mientras Django no limpie la bandera al reapuntar, liberar antes de cerrar no es una
buena práctica: es un requisito, y su incumplimiento deja al bot mudo»*. Lo pongo en el runbook con
esas palabras. Una operativa frágil declarada es gestionable; la misma operativa implícita es una
trampa.

**Y no bloquea la ventana**, con una condición: que el E2E que ya has metido —takeover → liberación →
volver a entrar con cotización nueva sobre el mismo teléfono— **se ejecute de verdad y se observe**, no
que figure en la lista. Es la prueba de que el caso frecuente funciona; lo que (a) cierra es el caso
del despiste.

## Y gracias por el uso que le has dado al dato

Te pasé el retarget del canario como contexto para tu E2E y lo has convertido en un riesgo identificado
con sus tres salidas. Eso es exactamente lo que tenía que pasar con ese dato, y no pasa solo.
