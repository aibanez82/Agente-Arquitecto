# Borradores S2 pendientes de decisión de Alberto (4 ago 2026)

> Dos textos listos para publicar en el lado de Juan. **Ninguno se publica sin OK de Alberto**
> (convención: no abrir issues/comentarios de fondo en HYL-WAI sin decisión de canal). Los dos
> son legales bajo la metodología (el §8 del contrato S2 invita a citar ambigüedades en `#135`),
> pero publicar antes del freeze es una decisión de estrategia: adelanta el des-riesgo del
> contrato a cambio de mostrar nuestro análisis temprano.

---

## Borrador A — Comentario en `HYL-WAI#135` (ambigüedades pre-freeze del contrato S2)

**Recomendación del Arquitecto: publicar AHORA.** El contrato dice que las ambigüedades se
resuelven antes/durante el freeze; entregarlas hoy evita una ronda post-handoff (el patrón que en
S1 funcionó: nuestras 5 preguntas §12 se resolvieron el mismo día sin coste de ronda). La A5 es
potencialmente **material** — si se descubre después del freeze obliga a versión nueva + revisión
nueva; detectada ahora, Juan puede incorporarla a la reconciliación que de todos modos hará al
cerrar S1 (§6.1.2).

```markdown
## Prep offline S2 (lado @aibanez82) — 10 ambigüedades para la reconciliación pre-freeze

Conforme a §8 del contrato aprobado (`af57580`, sha256 verificado `ff106e89…`) y sin comenzar
implementación alguna: preparación offline autorizada por la enmienda `#140 c.5174994247` §9.
Formato: cláusula → ejemplo mínimo → impacto. Detalle completo con refs de código en
`Agente-Arquitecto:docs/iniciativas/s2-prep-offline.md` y
`Agente-n8n@b104b1f:docs/s2/prep-inventario-hechos.md`.

**Señalamos A5 y A2 como posiblemente materiales; el resto parecen aclaraciones.**

1. **§3.3/§4.2 — hechos en sesiones legacy.** La presentación exige `session_id` "conforme a S1"
   y `lead_id` requerido; una sesión legacy (sin `schema_version=1`, frontera S1 §12.3) puede
   carecer de lead verificable. ¿Los hechos comerciales aplican solo a identidad v1? Impacto:
   cobertura de S2-F1 en conversaciones antiguas.
2. **§3.3 — autenticación de productor.** Hoy n8n→Django autentica los GET con `N8N_TOKEN`
   compartido (rotación = autoridad exclusiva de #130), y el único conducto de ESCRITURA
   (`POST /api/emitir-externo/`) no envía credencial alguna (verificado en el export STG; la
   emisión E2E del 28 jul funcionó así). ¿Basta la credencial compartida como identidad de
   productor o se exige credencial por productor? Impacto: dependencia cruzada con #130 y el
   conducto físico del adaptador de hechos nacería incumpliendo §3.3.
3. **§4.3.1 — transporte de la consulta de control para n8n.** n8n lee Postgres directo por
   arquitectura. ¿Una consulta SQL versionada sobre las tablas del dominio Dashboard cuenta como
   "resolución canónica" si implementa exactamente su semántica (incl. fail-closed), o debe pasar
   por una interfaz servida por el Dashboard? Impacto: latencia/disponibilidad del gate por turno
   y el modo de fallo de S2-F6.
4. **§4.3.6/S2-F6 — alcance del fail-closed en S2.** "Consultar control antes de IA/efectos
   cuando S3/S4 lo autoricen": ¿la conformidad S2 del gate se acredita solo offline (suite),
   quedando el bot sin consultar en vivo hasta S3, o S2 ya exige el gate activo en STG? Impacto:
   con gate activo y fuente caída, el bot deja de responder a todos — ese trade-off debe
   decidirse, no heredarse.
5. **§4.3.4 — fencing en transferencia.** ¿El `epoch` del destino continúa la secuencia
   monotónica de la sesión (implementación acreditada: `MAX(epoch)+1` por sesión) o reinicia por
   control? Pedimos confirmar que la primera vale como "garantía equivalente" también para
   METEPEC.
6. **§4.2/§4.1 — significado de "persistido y validado".** Hoy los writers de bloques toman
   valores del agente con fallback `'N/A'` sin capa de validación; una fila `nombre='N/A'` es
   indistinguible de una real. ¿"Validado" exige validación en n8n antes de persistir, o basta la
   fila y Django revalida al aceptar el hecho? Impacto: define el tamaño real del adaptador.
7. **§3.3 vs §1.3 — `fact_id` estable sin outbox (posible material).** Un retry debe reutilizar
   el mismo `fact_id`, pero §1.3 excluye el outbox n8n→Django: persistir el `fact_id` es un
   outbox mínimo con otro nombre, y derivarlo del contenido convierte cualquier cambio de
   contenido en hecho nuevo (rompe `duplicate=true`). Tal como está redactado no vemos opción
   limpia; pedimos definir el mecanismo mínimo aceptado.
8. **§4.3/§4.4 — efectos deterministas fuera del agente.** Dos rutas del Main producen efecto
   externo sin pasar por la cadena del agente (entrega de PDF por quick-reply; respuesta fija a
   sesión `completed`). ¿"Antes de IA/efectos" las incluye? Impacto: el gate necesitaría dos
   puntos de inserción, no uno.
9. **§4.1/§7.2 — mapeo del "primer bloque de emisión" (S2-F1).** ¿Cuál de nuestros bloques
   persistidos (`grupo1/2/3`, `policy_data`) constituye el hecho de S2-F1? Sin ese mapeo el
   fixture no es comprobable desde el productor.
10. **§4.3.1/§5.3 — dirección de los mirrors (MATERIAL).** El contrato trata `human_takeover` y
    `metepec_derived` como derivados del canónico del dominio Dashboard con fallo cerrado ante
    contradicción. En la realidad acreditada la dirección es la inversa: esos flags los escriben
    los workflows n8n de Atención Humana/Metepec y el dominio Dashboard (cuya verdad es
    `dashboard_conversation_claims`) no consume esas escrituras. Con el uso operativo actual, la
    contradicción mirror↔canónico sería el estado normal y el fail-closed literal dejaría al bot
    sin responder de forma permanente. Pedimos decidir pre-freeze: (a) n8n deja de escribir los
    mirrors (afecta el flujo operativo vivo), (b) definir una sincronización canónico→mirror, o
    (c) otra resolución de la autoridad. Ninguna la elegimos nosotros.

Sin acción viva, sin cambios de código; `fd8fa75` sigue inmóvil. Quedamos a disposición para la
reconciliación.
```

---

## Borrador B — Hallazgo de seguridad: `POST /api/emitir-externo/` acepta escritura sin credencial

**Hecho verificado (4 ago, Arquitecto):** en `Agente-n8n@origin/stg:workflows/Issue Policy
Guard_stg.json`, el nodo `Call Issue Policy Real` llama `POST /api/emitir-externo/` sin
`authentication`, sin `nodeCredentialType` y sin headers de credencial; los conductos de LECTURA
(`Get Quotation Data`, `Fetch Quotation Document`) sí usan `httpHeaderAuth` (`Django N8N_TOKEN
STG`). La emisión E2E del 28 jul (pólizas reales en STG) funcionó así → el endpoint de EMISIÓN
acepta escrituras no autenticadas, al menos en STG. No hemos probado PROD (ninguna llamada viva).

**Ruteo según la regla vigente:** el fix es coordinado (Django exige credencial + n8n la envía)
→ canónico en `aguayo-co/HYL-WAI`. Ya existe el #119 sobre este mismo endpoint (400 sin causa).
**Opciones para Alberto:**
1. Comentario en `HYL-WAI#119` añadiendo el hallazgo de autenticación (comentar en issues
   existentes está permitido por nuestras convenciones; tema relacionado pero distinto).
2. Issue nuevo en HYL-WAI (requiere tu OK explícito por convención).
3. Aparcar hasta S2: la ambigüedad #2 del Borrador A ya lo menciona de pasada — si publicamos el
   Borrador A, Juan queda informado por esa vía y el issue formal puede esperar su decisión.

**Recomendación del Arquitecto:** opción 1 (comentario en #119), y que el texto sea el párrafo
"Hecho verificado" de arriba, con una línea final: "Lo dejamos aquí para que decidas si el
endpoint debe exigir la misma credencial que los GET; nuestro lado añadiría el header en el nodo
cuando definas el requisito (coordinado, por el freeze vigente no tocamos workflows ahora)."
