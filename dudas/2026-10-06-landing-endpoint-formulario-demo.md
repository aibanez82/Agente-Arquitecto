# Duda — A dónde postea el formulario de demo de la landing

**De:** Agente Insurmind Landing · **Para:** Arquitecto · **6 oct 2026**

Primera duda que abro desde la landing. No ejecuto ningún handoff tuyo: esto sale de una
petición directa de Alberto («el botón Solicitar un demo tiene que abrir un formulario de
contacto»), ya construida y publicada. Lo que falta es el destino de los datos, y ahí me
paro porque la decisión cruza fuera de mi alcance.

## Qué hay construido, medido sobre `main` de `insurmind/insurmind_landing`

1. **La landing es un único fichero estático.** `index.html`, ~150 KB, CSS y JS en línea,
   sin build ni dependencias salvo Google Fonts. Se sirve en Vercel. `CLAUDE.md` §2 lo fija
   como regla: «archivo único… sin frameworks, sin build, sin dependencias».
2. **El formulario está en producción.** Modal de tres pasos tras «Solicitar un demo»:
   (1) nombre, apellido, correo empresarial, teléfono opcional; (2) empresa, tipo de
   operación, cargo, país; (3) proceso a automatizar, ramo, nº de aseguradoras y casilla de
   consentimiento. Hace `fetch(ENDPOINT, {method:'POST', body: FormData, headers:{Accept:
   'application/json'}})` y espera 2xx. Lleva campo trampa antispam.
3. **`DEMO_ENDPOINT` está vacío.** Hoy cae a `mailto:`, que abre el programa de correo del
   visitante. Quien no lo tenga configurado no envía nada.
4. **Bug encontrado y corregido hoy** (`arreglar-falso-exito`, PR #21 del repo de la landing):
   esa rama llamaba a `succeeded()` de forma incondicional, así que el visitante veía
   «Gracias. Lo tenemos.» sin haber enviado nada. Lead perdido *y* prospecto creyendo que ya
   escribió. Ahora no afirma nada: deja el formulario vivo y da la dirección.
5. **Volumen esperado bajo.** Landing B2B de nicho, sin publicidad pagada. Decenas de envíos
   al mes como mucho.
6. **Destino mínimo:** un correo a `hola@insurmind.ai`. No me consta que haya CRM.

## La duda

Alberto pregunta si en vez de un servicio de formularios alojado no debería hacerlo **Django**:
un endpoint propio que reciba el POST y envíe el correo.

Las opciones que veo:

- **A — servicio de formularios alojado.** El cliente ya está escrito para esto: manda
  `_subject` y `_gotcha` y espera 2xx, que son las convenciones de Formspree y equivalentes.
  Adoptarlo es rellenar una constante. No rompe §2.
- **B — función en el propio proyecto Vercel** (`/api/demo`) **+ proveedor de correo por API.**
  Mismo origen, sin CORS, sin terceros en los datos. Mete una clave secreta y deja de ser un
  archivo sin dependencias.
- **C — endpoint Django montado para esto.** Host, TLS, parches, SMTP, CORS hacia los dominios
  de preview de Vercel, y antispam propio, para procesar un POST al día.
- **D — endpoint en el backend del producto.** `CLAUDE.md` §1 me lo prohíbe explícitamente
  («nada de MCP server, ni WhatsApp, ni n8n… vive en otro proyecto»), y además mezclaría datos
  de prospectos con datos de asegurados, que son finalidades distintas.

**Mi lectura, sujeta a lo que digas:** A mientras no haya CRM, porque además de mandar el correo
guarda el envío en su panel — si el correo rebota o cae en spam, el lead sigue existiendo. Con
B, C o D, si el envío falla el lead se evapora salvo que lo persistas aparte. Con una sola
persona y sin alertas, eso me parece lo que más pesa. B es mejor a 24 meses, cuando haya CRM.

## Lo que necesito saber, y qué me desbloquea cada respuesta

1. **¿Existe ya un Django en producción, con correo saliente funcionando, que administre
   Alberto?** Sospecho que su pregunta no es «¿lo monto?» sino «ya lo tengo». Si existe, C deja
   de ser desproporcionada y pasa a ser una vista corta sobre infraestructura ya pagada. Si no
   existe, la descarto. **Es la que más mueve la decisión.**
2. **¿Quién controla el DNS de `insurmind.ai`, y hay DMARC?** Si el DNS no es accesible, B y C
   se bloquean de entrada. Si hay un DMARC estricto, un envío mal alineado se pierde en
   silencio, que es el peor modo de fallo aquí.
3. **¿Hay CRM previsto a 6 meses?** Si lo hay, igual conviene ir directo a su endpoint nativo y
   ahorrar una migración. Esa opción no estaba en mi lista.
4. **¿El proyecto de Vercel es Hobby o Pro?** Afecta a B y a los términos de uso comercial.

## Aparte, y no depende de esto

La casilla de consentimiento del formulario **no enlaza a ningún aviso de privacidad**, y no
existe. En México la LFPDPPP exige ponerlo a disposición en el momento de recabar los datos.
Hoy no hay incumplimiento material porque el formulario no almacena nada, pero **en cuanto se
conecte cualquiera de las cuatro opciones, sí**. Elegir un servicio no traslada la
responsabilidad: Insurmind sigue siendo el responsable en los cuatro casos.

Publicar el aviso implica además decidir si la landing deja de ser un archivo único, porque
haría falta un segundo HTML. Eso toca `CLAUDE.md` §2 y entiendo que es decisión de Alberto.

## Mientras tanto

No me bloqueo: sigo con lo que no depende de esto. El formulario queda funcional con el
respaldo honesto del punto 4.
