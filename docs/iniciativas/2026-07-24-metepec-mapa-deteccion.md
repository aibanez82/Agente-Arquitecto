# METEPEC — mapa de detección de las 11 categorías (24 jul 2026)

> Autor: Arquitecto-IA-Qualitas · 24 jul 2026.
> Complementa [2026-07-24-metepec-redefinicion-alcance.md](2026-07-24-metepec-redefinicion-alcance.md)
> (alcance + arquitectura Forma 2). Este doc = cómo el bot detecta cada categoría en la
> conversación. **Borrador de diseño — varias filas tienen preguntas abiertas para Alberto.**

## Principio rector: dos niveles de detección con stakes muy distintos

1. **Detección GRUESA (Haiku Intent Router → `no_cotizable`)** — CRÍTICA. Es lo único que
   protege el flujo del 90%. Haiku solo decide: "¿esto es un auto particular normal para uso
   personal, o algo que NO cotizamos?" No distingue las 11 — solo levanta la bandera.
2. **Clasificación FINA (dentro del `METEPEC Agent` → `motivo_entrega`)** — BARATA. Confundir dos
   categorías METEPEC entre sí solo cambia la etiqueta y la plantilla de correo; el lead va a
   METEPEC igual. No hay que sobre-optimizar esto.

**Consecuencia de diseño:** invertir el esfuerzo en que Haiku no tenga falsos negativos (que no
se le escape un caso no-cotizable y lo cotice como auto normal) ni falsos positivos graves (que
mande a METEPEC un auto particular legítimo). La precisión de la etiqueta fina es secundaria.

## Reto transversal: el reveal llega a media conversación

El cliente cotizó un auto normal en la landing (Versa/Yaris) y la verdad sale después, de pasada,
en WhatsApp ("ah, es que es salvamento" / "en realidad es una Tacoma de carga"). Haiku corre por
turno, así que PUEDE re-rutear en el turno donde aparece la señal — pero la señal suele venir
mezclada con otra intención (dando datos, preguntando precio). Por eso la bandera gruesa debe
dispararse ante **mención**, no solo ante petición explícita.

## Tabla de detección

Leyenda **Tipo**: T1 = vehículo cotizado ES el real (solo cambia uso/estatus → `get_quotation_data`
sirve). T2 = vehículo cotizado es señuelo (el real es otro → hay que capturar vehículo real).

| # | Categoría | Señales positivas (frases del cliente) | Tipo | Nota de captura / ambigüedad |
|---|---|---|---|---|
| 9 | **Plataforma** (pasajeros) | "Uber", "Didi", "Indriver", "plataforma", "hago viajes", "manejo app" | T1 | ✅ Cerrada. Solo VIN. Reparto NO (→ moto si es en moto). |
| 1 | **Pickups de Carga** | "uso la camioneta/pickup para carga", "transporto mercancía/material", "es de trabajo", "flete", "reparto en camioneta" | T2? | ⚠️ El disparador es el USO de carga, NO el pickup. Pickup personal = se queda con el bot. "Camioneta" es ambiguo (SUV vs pickup). |
| 2 | **Camiones** | "camión", "torton", "rabón", "tractocamión", "trailer", "3.5 toneladas", "camión de carga" | T2 | "Camión" de pasajeros (bus) → Servicio Público, no aquí. Distinguir carga vs pasajeros. |
| 3 | **Servicio Público de Pasajeros** | "taxi", "combi", "microbús", "autobús", "ruta", "sitio", "transporte de pasajeros" | T1/T2 | Taxi sedán = T1; combi/bus = T2. Distinto de Plataforma (app). |
| 4 | **Fronterizos y Regularizados** (legalizados) | "fronterizo", "legalizado", "regularizado", "auto americano/importado", "placas de frontera", "chocolate", "lo legalicé" | T1/T2 | Estatus permanente (ya legalizado). El modelo importado a veces no está en catálogo → confirmar vehículo real. Distinto de Turista (temporal). |
| 5 | **Turistas** | "placas americanas/extranjeras", "soy turista", "auto de EE.UU. temporal", "permiso de importación temporal", "estoy de visita" | T2 | Vehículo extranjero, temporal, NO regularizado. Distinto de Fronterizo (permanente). |
| 6 | **Motocicletas** | "moto", "motocicleta", "scooter", "mi moto de [marca/cc]" | T2 | Reparto en moto (Uber Eats/Rappi) cae AQUÍ, no en Plataforma. |
| 10 | **Salvamento** | "salvamento", "recuperado", "reconstruido", "fue pérdida total y lo repararon", "título de salvamento", "siniestrado recuperado" | T1 | Mismo vehículo cotizado, solo cambia el estatus. |
| 11 | **Flotillas** | "varios autos", "una flotilla", "asegurar mi flota", "N vehículos de la empresa" | — | 🔴 Estructuralmente distinto: NO es un vehículo → no hay un VIN único. La captura difiere (ver abajo). |
| 7 | **Seguro Básico Estandarizado** | "seguro básico estandarizado", "solo el de ley", "el obligatorio mínimo" | n/a | ⚠️ Alta ambigüedad: "quiero el más barato" NO es esto necesariamente. Solo disparar ante mención clara del producto. Baja frecuencia. |
| 8 | **Seguro RC Profesional para Agentes** | "responsabilidad civil para agentes de seguros", "soy agente y quiero mi RC profesional" | n/a | 🔴 No es seguro de auto. Casi nunca llega por este funnel. Incluido por completitud. |

## Reglas de desambiguación (los pares que se confunden)

Estas son las únicas confusiones que importan, y varias importan poco (ambos lados van a METEPEC):

1. **"Camioneta" = SUV personal (bot) vs pickup de carga (METEPEC):** el disparador NO es la
   palabra "camioneta" sino el **uso de carga/comercial**. Una SUV o pickup de uso personal se
   queda con el bot. → Si dice "camioneta" sin señal de carga, NO levantar `no_cotizable`.
2. **Pickup personal (bot) vs Pickup de Carga (METEPEC):** misma regla — el uso, no el vehículo.
3. **"Camión": carga (Camiones) vs pasajeros/bus (Servicio Público):** ambos METEPEC → confusión
   barata, no perder tiempo. Etiquetar por lo que diga; si dice pasajeros → servicio público.
4. **Plataforma (app) vs Servicio Público (taxi/combi tradicional):** ambos pasajeros, ambos
   METEPEC → confusión barata. Uber/Didi/Indriver = plataforma; taxi/combi/sitio = servicio
   público.
5. **Fronterizo/Regularizado (permanente, legalizado) vs Turista (temporal, placas extranjeras):**
   ambos METEPEC → confusión barata. "Ya lo legalicé/regularicé" = fronterizo; "estoy de
   paso/turista/permiso temporal" = turista.
6. **"El más barato" ≠ Seguro Básico Estandarizado:** peligro de falso positivo. Un cliente que
   pide precio bajo sigue siendo un auto normal cotizable. Solo tratar como categoría 7 si
   menciona explícitamente el producto básico/de-ley, no por "barato".

## Caso especial de captura: Flotillas (#11)

No encaja en el molde de plataforma porque no hay un solo vehículo/VIN. Opciones a decidir con
Alberto cuando lleguemos a esta categoría:
- (a) Captura mínima: solo detectar "es flotilla" + datos de contacto → METEPEC llama y arma
  todo por teléfono (más simple, coherente con Opción B de plataforma).
- (b) Captura de cuántos vehículos / tipo → más info en el correo.
Probablemente (a), pero se define al diseñar esa categoría.

## Preguntas abiertas para Alberto (por categoría)

Ninguna bloquea el diseño de detección gruesa; son para afinar la fina y la captura:

1. **Pickups de Carga vs Personales:** ¿el bot debe intentar distinguir uso personal vs carga, o
   ante cualquier pickup que "haga ruido" prefieres mandarlo a METEPEC y que ellos filtren? (Ojo:
   "Autos y **Pickups Personales**" es explícitamente lo que SÍ cotiza el bot — no quiero mandar
   a METEPEC pickups personales legítimos.)
2. **Seguro Básico Estandarizado (#7):** ¿esto llega de verdad por el bot, o casi nunca? Define
   cuánto esfuerzo vale la pena.
3. **RC Profesional para Agentes (#8):** ¿alguna vez ha llegado por WhatsApp? Si es 0%, lo
   dejamos como fila muerta (el bot lo trataría como `out_of_scope` normal, sin carril METEPEC).
4. **Reparto (Uber Eats/Rappi/Didi Food):** confirmado que NO es plataforma. Si es en auto (no
   moto), ¿a qué categoría va — carga/comercial, o se cotiza normal? (En moto ya quedó → Motos.)

## Frecuencia esperada (hipótesis, para priorizar)

Sin datos duros todavía, hipótesis de qué categorías mueven volumen real (para no gastar diseño
fino en las raras): **Plataforma, Salvamento, Fronterizos/Regularizados, Pickups de Carga y
Camiones** probablemente concentran la mayoría. Turistas, Servicio Público, Motos, Flotillas =
medio. Seguro Básico y RC Agentes = casi nunca. **Confirmar con Alberto / con los datos de
`leads_metepec` una vez que empiece a llenarse.**
