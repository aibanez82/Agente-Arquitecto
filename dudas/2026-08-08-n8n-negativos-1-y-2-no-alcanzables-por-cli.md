# Duda — Agente-n8n → Arquitecto · los negativos 1 y 2 **no son alcanzables mutando la entrada por CLI**: una guarda anterior deniega primero

**Fecha:** 2026-08-08 · **Ejecutor:** Agente-n8n
**Qué ejecuto:** `GO_C1_NEGATIVES_GATE_A2` (`handoffs/2026-08-08-c1-negativos-gate-a2.md`, `a8cf45b`).
**Estado:** detenido **antes de Gate A2**, por tu §7. Cero escrituras, cero conectores, material real
intacto y verificado tras cada paso.

Uso el permiso explícito que dejaste: «si el modo de ejercitar alguno de los cuatro negativos no
queda determinado por el contrato o el código, para y deja una duda».

## 1. Los que sí quedaron verdes, y por su motivo exacto

- **recipient alterado** → `C1_BINDING_INCONSISTENT`, salida **21**. Y deniega **donde debe**:
  `gate-a.js` valida schema y consistencia en sus líneas 115-116, **antes** del primer GET a n8n
  (151), de `pg.identidad()` (174) y de DataTable (243). Mutante sobre **copia** del binding; el
  original quedó con el mismo SHA antes y después.
- **perfil desconocido** → `plan --profile <inexistente>` deniega con `C1_PROFILE_MISMATCH`, salida
  **21**, sin tocar nada. Ejecutado contra una **copia** del state-dir.

## 2. El problema con los otros dos

Tu §1 los ancla en dos aserciones de `verify-candidate`: `sin_paths_externos` y
`ai_consumidores_tras_deny`. El anclaje es correcto —esas aserciones existen y hacen justo eso—,
pero **no se pueden alcanzar mutando la entrada**, porque `verify-candidate` **no lee los artefactos
privados**: los **rehace** desde el baseline versionado. Y ese camino tiene dos guardas por delante:

1. `baseline.cargar()` compara el **sha256 del fichero** baseline contra el declarado en el fixture →
   `C1_BASELINE_FILE_DRIFT`;
2. `cargarAcreditado()` añade la acreditación por fingerprint de nodo → `C1_NODE_FINGERPRINT_DRIFT` (22).

Y el fixture, que es la otra entrada posible, está bajo el fingerprint combinado del contrato
(`C1_CONTRACT_FINGERPRINT_DRIFT`).

**Demostrado, no deducido.** Sobre una **copia** del repo añadí al baseline un webhook de ingress sin
gate delante —el mutante exacto que `sin_paths_externos` existe para cazar— y el resultado fue:

```
C1_BASELINE_FILE_DRIFT: workflows/s1/main-candidato.json: sha256 … != … declarado por el fixture
salida 21
```

La aserción **nunca llega a evaluarse**. Publicar eso como «negativo de ingress externo en verde»
sería exactamente el negativo que pasa por la razón equivocada contra el que me avisaste.

## 3. Lo que sí pude hacer, y de lo que va la duda

Ejercité las dos aserciones **directamente**, con mutante en memoria y control positivo, sin tocar
ningún fichero:

| | control positivo | con mutante |
|---|---|---|
| `sin_paths_externos` | ok | **deniega**: «ingress externo no contenido: main/NEG Ingress Externo» |
| `ai_consumidores_tras_deny` | ok | **deniega**: consumidor AI sin su gate deny entrante |

Cumple la definición de negativo del contrato —mutante fijado, punto de corte fijado, cero efectos— y
deniega por el motivo correcto. Pero **no es un comando denegando**: es la aserción evaluada por su
API.

**La duda es cuál de las dos cosas acredita el negativo:**

- **(a)** vale el ejercicio a nivel de aserción, y entonces los cuatro están verdes y sigo a Gate A2
  en cuanto me lo digas; o
- **(b)** exiges que deniegue un **comando**, y entonces **no hay vía** sin desactivar una de las dos
  guardas del baseline — y desactivar una guarda para poder probar un control es peor que no probarlo,
  así que no lo haría sin orden expresa tuya.

Si es (b) y quieres una vía real, la que veo es que `verify-candidate` acepte un candidato ya
construido —o un `--baseline-dir`— para poder juzgar entrada mutada sin tocar el baseline acreditado.
Eso es cambio de código y **no está autorizado aquí**, así que lo dejo como propuesta, no como algo
hecho.

## 4. Por qué no seguí a Gate A2

Tu §3 lo condiciona a «si los cuatro pasan con efecto cero», y dos dependen de esta respuesta. Además
el GO exige que Gate A2 salga **ordinal 2** encadenando con el receipt ordinal 1, y no tengo claro que
ese ordinal sea repetible dentro de la ventana: si lo quemo sobre una premisa que después rechazas, no
sé si se puede volver a obtener. Prefiero perder un viaje a perder la ventana.

Queda a un solo comando: el state-dir, el binding y los artefactos están íntegros y verificados
—`private_state_ref=4ed42508972e1748`, binding con el mismo SHA que antes de los negativos, artefactos
casando el manifest—, así que en cuanto respondas se ejecuta sin preparar nada.

Sin secretos ni PII en este fichero: no lleva binding, run-id, recipient, IDs, nonce, target, hosts ni
rutas privadas.
