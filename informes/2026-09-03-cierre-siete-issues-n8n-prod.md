# Ronda de certificación: los siete issues nuestros que ya estaban en PROD — 3 sep 2026

**Regla aplicada:** ningún issue se cierra por el informe del ejecutor ni por el commit del espejo. Se cierra por medición propia contra el **grafo vivo** de PROD (`bf44e0bb`, leído por la API) y contra la **BD de PROD**.

**Resultado: seis cerrados, uno abierto.**

| Issue | Anclaje vivo verificado | Efecto medido en PROD | Veredicto |
|---|---|---|---|
| `#292` | La cotización como fuente autorizada, en `AI Agent` y `Get Quotation Data` | 1 deflect en 53 respuestas, **legítimo** (ver abajo) | cerrado |
| `#293` | Valla `valor_uno`/`valor_dos` en `AI Agent` + `toolDescription` | **0** cifras inventadas en 45 respuestas (antes 2 de 205) | cerrado |
| `#295` | Copy del PDF en `AI Agent` | **0** envíos al PDF por la suma asegurada en 33 respuestas | cerrado |
| `#297` | Los 6 nodos de la red de reparación | **0 reparaciones — y 0 casos posibles** | **abierto** |
| `#298` | `Validate Quotation Id` · `IF Valid Quotation?` · `Build Typed No-Quotation` (`b06966a4`) | su regresión, el `#302`, ya viajó y está viva | cerrado |
| `#299` | `n8n_cotizacion_sin_poliza(...)` en `Resolve Session` | **40** de 1.082 sesiones vivas protegidas (antes 3) | cerrado |
| `#260` | `(status='active') DESC` en `Resolve Session` y `Resolve Terminal Session` | **0** listas de cinco en 24 respuestas; 5 `active` sobre 1.114 | cerrado |

## Los tres momentos en que casi cierro algo mal

### 1. Una ventana única para siete viajes que no viajaron a la vez

Medí el «después» de los tres issues conversacionales con **un solo corte** —el del `#292`, 19:15Z—, y cada paquete entró a una hora distinta. Con ese corte me salió una respuesta que mandaba al cliente al PDF **después** del arreglo. Con el corte propio del `#295` (21:53Z) resultó ser **anterior** al viaje: era el defecto, no su vuelta.

**La ventana de una medición de efecto es la del cambio que se mide, no la del primero del lote.**

### 2. El deflect que parecía una regresión y era el comportamiento correcto

Un «No conozco esta respuesta» posterior al `#292`. Leído el turno entero: el cliente preguntaba por la diferencia entre dos códigos de tarifa, la KB devolvió un chunk de la cláusula 20ª (contratación telefónica) y el bot declinó. **El defecto era declinar teniendo el chunk que responde**; declinar sin tenerlo es lo que queremos. Dos turnos antes, en la misma sesión, una pregunta de alcance sí se respondió con datos.

### 3. El PDF que sí imprime lo que yo daba por ausente

Una respuesta decía «el porcentaje exacto del deducible viene en el PDF», tres minutos después del import del `#295`. En vez de darla por regresión, abrí el PDF real (`Cotizacion_3528_AR_2020.pdf`):

```
RIESGOS              SUMA ASEGURADA      %DEDUCIBLE      PRIMAS
DAÑOS MATERIALES     VALOR CONVENIDO         5%        $13,651.13
ROBO TOTAL           VALOR CONVENIDO        10 %        $1,663.74
```

**La suma asegurada no está impresa; el porcentaje de deducible sí.** La frase del bot es verdadera. De paso queda acreditado en la fuente el dato del 2 sep (DM 5 %, RT 10 %) y la decisión de Alberto de darle al cliente el porcentaje.

*Mejora apuntada, no ejecutada:* el deducible es constante y está acreditado; el bot podría decirlo en vez de mandar al PDF. Es copy — va por la tubería del Agente Mejoras.

## El que no cierro: `#297`

La red de reparación está viva y es inofensiva, pero **no puede activarse hoy en PROD**:

| Medición (BD de PROD, 3 sep) | |
|---|---|
| Reparaciones ejecutadas (`source='window_repair_297'`) | 0 |
| Sesiones cuya fila 120 desde el final es `tool` | 0 |
| Sesiones con ≥120 mensajes | **0** de 487 |
| Mensajes de la sesión más larga | **85** |

El guard mira la fila 120 y **ninguna sesión llega**. Eso choca de frente con la cifra que justificó el viaje —«desbrickea las 323/483 de PROD ya minadas»—, y las dos no pueden ser verdad sobre la misma tabla. Pedido en el issue: la consulta exacta con la que salió esa cifra, con su ámbito.

**El motivo de no cerrar, en una frase: un remedio que no puede activarse es indistinguible de uno que funciona — los dos dan cero reparaciones.**

---

*Ámbito: grafo vivo de PROD (`bf44e0bb`) y BD de PROD, medido el 3 sep 2026. Ventanas de efecto: ~19 h desde cada viaje, entre 24 y 53 respuestas del bot según el corte. Poco volumen: acreditan ausencia en su ventana, no una tasa.*

Agente: Arquitecto-IA-Qualitas
