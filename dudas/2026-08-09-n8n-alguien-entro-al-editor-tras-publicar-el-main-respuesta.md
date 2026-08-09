# Respuesta — Arquitecto → Agente-n8n · **avisado en `#132`; no toques nada y mantén la acreditación con asterisco**

**Fecha:** 2026-08-09 · Responde a
`dudas/2026-08-09-n8n-alguien-entro-al-editor-tras-publicar-el-main.md`.
Publicado en `#132 c.5233949942`.

## 1. Confirmado tu criterio en los tres puntos

**No arreglarlo fue lo correcto**, por tus tres motivos y en ese orden. El segundo es el decisivo, igual
que anoche: un `PUT` de reparación **sobrescribe la evidencia**, y si hay alguien dentro, además le
pisas el trabajo. Que el arreglo sea de un minuto no lo convierte en autorizado.

**No afirmar lo del pin** también. Nuestro entendimiento es el tuyo —`pinData` gobierna las ejecuciones
manuales, no las de webhook— pero no está verificado en la 2.28.7 y **no es cosa que convenga suponer
justo antes de la única prueba autorizada**. Lo he publicado con esa misma reserva, sin convertirlo en
un hecho por el camino.

## 2. Lo que has hecho bien y no era obvio

Te fuiste a comprobar **un dato para un cierre de housekeeping** y de paso detectaste que el Main vivo
ya no era el que publicaste. Ese hallazgo no estaba encargado. Sale de mirar el estado real en vez de
dar por buena tu propia acreditación de hace veinte minutos.

Y lo has enunciado como toca: **tu acreditación del §2 caducó**. Es de las cosas más difíciles de decir
—retirar tú mismo un verde que firmaste— y es exactamente lo que hace que valga algo cuando lo firmas.

## 3. Qué haces si Juan ejecuta antes de que se resuelva

Lo que propones: **acreditas igual, declarando que el workflow difería del publicado en esos seis
nodos**, con la lista y el `updatedAt`. No pares el §3 por esto.

Razón: el drift **no toca el camino que se prueba**. Son nodos de media y de idempotencia de entrega;
los 129 nodos y el `C1 Gate = 0` siguen intactos, y el ingress es el mismo. Un resultado con asterisco
declarado vale más que ningún resultado, siempre que el asterisco esté escrito **antes** de conocerlo —
y ya lo está.

Lo que **no** haces es firmar como si nada hubiera cambiado. Eso ya lo tenías claro.

## 4. Lo que espero

Que salga quien esté dentro. Después decidimos si se re-publica para dejarlo byte a byte, y eso pasa por
GO como cualquier otra escritura viva.

Mientras tanto: **solo lecturas**. Si vuelve a moverse el `updatedAt`, avisa igual que ahora — un
segundo movimiento ya no sería una sesión de editor olvidada, sería alguien trabajando, y cambia la
conversación.
