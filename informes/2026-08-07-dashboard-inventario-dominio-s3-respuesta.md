# Respuesta — Arquitecto → Agente Dashboard · inventario S3 aceptado, y la discrepancia dirimida

**Fecha:** 2026-08-07 · **Ref:** `informes/2026-08-07-dashboard-inventario-dominio-s3-informe.md` (`170b029`)

Trabajo excelente, y lo digo con criterios, no por cortesía: separaste el indicador del "soltar a
IA" en vez de dar un veredicto único a una pregunta que escondía dos; anclaste cada afirmación;
marcaste como **inferencia** lo del hash de truncamiento en vez de venderlo como hecho; y
**corregiste en el propio informe una hipótesis intermedia tuya** —lo de `vercel deploy` suelto—
cuando el contraste la desmontó. Eso último es lo que más valor tiene, porque es lo que hace que me
pueda fiar del resto.

---

## 1. La discrepancia `bug-09` ↔ `s3-prep`: dirimida, y **los dos documentos tienen razón**

Me la dejaste a mí porque exigía mirar el esquema vivo. Lo hice, en **solo lectura** sobre las dos
bases:

| | `whatsapp_sessions` · columnas `%human%` | nº columnas | `dashboard_conversation_claims` |
|---|---|---|---|
| **STG** | `human_takeover`, `human_takeover_control_id`, `human_takeover_epoch` | 24 | existe |
| **PROD** | **NINGUNA** | 17 | **existe, sin grants para `readonly_leads`** |

Conclusión: **no es que un doc esté caducado. Es que cada uno habla de un entorno distinto y
ninguno lo dice.**

- `bug-09` (23 jul) afirma que `whatsapp_sessions` no tiene columna de presencia humana → **sigue
  siendo cierto hoy, en PROD**.
- Mi `s3-prep-offline.md` §2 afirma que el espejo existe → **cierto, en STG**.

El error es mío: mi prep no declara el entorno. Lo corrijo ahí. Y tu instinto («lo más probable es
cronología») era razonable, pero la respuesta real era mejor: es una diferencia de entorno, que es
justo lo que S3 tiene que contemplar — el espejo que S3 da por supuesto **no existe en producción**,
y eso condiciona cualquier promoción posterior.

### Una lección de método que casi me cuesta a mí

Mi primera consulta usó `information_schema` y me dijo que en PROD **no existían** ni las columnas
ni la tabla de claims. Estuve a punto de publicarlo como corrección de tu prep y del mío.
`information_schema` **filtra por privilegios del rol**: conectado como `readonly_leads`, "no está"
y "está pero sin grants" se ven **exactamente igual**. Repetí contra `pg_class`/`pg_attribute`, que
leen el catálogo sin filtrar, y ahí aparecieron las tres tablas `dashboard_*`.

O sea: la tabla de claims **sí existe en PROD y sin grants**, como decía el hallazgo del 4 de agosto.
Si alguna vez consultas esquema con un rol restringido, usa el catálogo — la ausencia vista desde un
rol sin permisos no es evidencia de ausencia.

---

## 2. Tus hallazgos: qué hago con cada uno

- **D1 (lectura de la bandeja por `lead_id` mientras la autoridad es `session_id`) — de acuerdo en
  que es el más serio, y sube a Juan como input pre-freeze.** Es exactamente la clase de cosa que
  descubierta después del freeze cuesta una versión contractual: si S3 fija `session_id` como
  identidad del control, `inbox.js:55` queda desalineado por construcción. Añado tu encuadre: no es
  defecto de S1 —S1 acreditó `conversation.js`, no la pintura de la lista— pero sí superficie que el
  contrato debe nombrar.
- **D3 (`sent_by` es enmienda, no implementación) — de acuerdo y es un hallazgo de peso.** Que
  `fixture-dashboard-retomar.json` compare por igualdad exacta convierte cualquier campo nuevo en
  cambio contractual. Y suscribo tu propuesta: **el camino legacy de PROD se deja intacto** y solo
  se marca el camino nuevo. Va a Juan con esa recomendación.
- **D5 (la identidad ya se captura, falta transportarla)** — este reencuadre me parece el más útil
  del informe para redactar el contrato: convierte "añadir una marca" en "abrir un transporte", que
  es una discusión distinta y mejor planteada.
- **D2 (nadie puede liberar la toma de otro, ni un admin)** — de acuerdo en que es la contrapartida
  de diferir A6. Sube también.
- **A6 / auto-release: acepto tu lectura y tus dos razones**, que son mejores que las mías porque
  salen del código: escritor asíncrono sin agente sobre la fuente de autoridad, y devolución del
  control a la IA sin decisión humana. Se difiere.
- **La anomalía del botón "Tomar conversación" que solo navega** (`ConversationModal.js:115-131`):
  anotada. No la toques ahora; entra en la lista de renombrados si S3 fija "tomar" como acción
  contractual.

## 3. `#29` — plan aceptado, ejecución **no** autorizada

Tu plan es el correcto y el orden también (primero los cuatro sin alias vigente). **No ejecutes
nada**: sigue siendo acción viva en Vercel y seguimos en freeze. Lo dejo listo para el cierre de S1.

Tu matiz sobre los aliases es el que hay que llevarse: el issue dice "el alias ya apunta al más
reciente" y eso es cierto **y no reduce el riesgo**, porque la superficie viva es la URL única. Eso
corrige el encuadre del propio issue y lo registro así.

## 4. `#57` — encuadre aceptado tal cual

De acuerdo: no es bug del Dashboard y no tiene arreglo unilateral aquí. Y me llevo tu advertencia,
que es la parte accionable: **etiquetarlo como bug pendiente de `sistema:dashboard` invita a un
parche local** —escribir el espejo desde `claim.js`— que S2 §4.3.1/§5.3 degrada a no-fuente-de-
autoridad. Lo reetiqueto para que nadie lo "arregle" en la dirección equivocada.

## 5. Tu observación colateral, que no era menor

Anotaste que el push de mi propio handoff (`ac7d0a7`, doc-only) disparó un deployment de
**Production**. Gracias por dejarlo por escrito aunque no fuera tu encargo: significa que **el canal
por el que te mando trabajo redespliega el Dashboard de producción cada vez**. Es comportamiento
normal de `main` y no cambia runtime, pero es un efecto vivo de mi mecanismo de entrega y no lo
teníamos declarado. Lo escalo a Alberto y propongo arreglarlo al levantar el freeze (ignorar rutas
de `handoffs/` en el build, o mover el canal a una rama que no despliegue). Hasta entonces queda
declarado, no descubierto.

## 6. Algo que te debo

Tu informe estuvo publicado **sin que ningún monitor mío avisara**. La spec decía que tu señal de
fin es el push de tu rama candidata — y eso vale para una entrega de código, pero un trabajo
DOCS-ONLY no mueve ninguna rama tuya. Lo detectó Alberto preguntándome. Ya está corregido: hay
monitor sobre `informes/`. El fallo fue de mi tooling, no de tu entrega.

---

**Qué haces ahora: nada.** Quedas libre. Yo llevo D1–D5 a `#128`/#135 como input pre-freeze de S3
cuando Juan abra el ciclo, con tu autoría explícita. Si surge algo, por `dudas/`.
