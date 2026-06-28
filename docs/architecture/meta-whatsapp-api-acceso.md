# Solicitud de acceso: WhatsApp Business API → Dashboard

## Qué necesito y para qué

Necesito conectar el dashboard de leads al Business Manager de Meta para traer
las estadísticas de los mensajes de WhatsApp que ya enviamos (enviados, entregados,
leídos, respondidos) y cruzarlos con los datos de leads y pólizas.

Hoy el dashboard sabe cuántos leads llegaron y cuántos contestaron al WhatsApp,
pero no sabe cuántos **leyeron** el mensaje sin responder. Con esta conexión
tendríamos el funnel completo:

**Enviado → Leído → Contestó → Datos → Póliza Pagada**

---

## Lo que necesito que hagas en Meta Business Manager

### Paso 1 — Crear un System User

1. Entra a **business.facebook.com**
2. Ve a **Configuración del negocio** (ícono del engranaje)
3. En el menú izquierdo: **Usuarios → Usuarios del sistema**
4. Clic en **Agregar**
5. Nombre: `dashboardqualitasreadonly`
6. Rol: **Empleado** (no Administrador — solo necesitamos lectura)
7. Clic en **Crear usuario del sistema**

---

### Paso 2 — Asignar activos al System User

1. En la misma pantalla del usuario recién creado, clic en **Asignar activos**
2. Selecciona **Cuentas de WhatsApp**
3. Selecciona la cuenta `hyl-wai-production` (o el nombre que tenga la WABA)
4. Activa el permiso: **Analizar** ✅
5. Deja desactivados: Administrar, Desarrollar (solo necesitamos leer)
6. Clic en **Guardar cambios**

---

### Paso 3 — Generar el token de acceso

1. En el perfil del System User (`dashboardqualitasreadonly`)
2. Clic en **Generar token**
3. Selecciona la app asociada a la WABA (si hay varias, pregúntame)
4. Activa estos permisos:
   - ✅ `whatsapp_business_management`
   - ✅ `whatsapp_business_messaging`
   - ✅ `business_management`
5. Expiración: **Nunca** (para que el dashboard no deje de funcionar)
6. Clic en **Generar token**
7. **Copia el token y guárdalo** — Meta solo lo muestra una vez

---

### Paso 4 — Obtener los IDs necesarios

Necesito dos IDs más que están en el Business Manager:

**WABA ID (WhatsApp Business Account ID):**
1. Ve a **Configuración del negocio → Cuentas → Cuentas de WhatsApp**
2. Selecciona la cuenta
3. El número que aparece bajo el nombre es el **WABA ID**

**Phone Number ID:**
1. En la misma sección, clic en la cuenta de WhatsApp
2. Ve a **Números de teléfono**
3. El ID que aparece junto al número es el **Phone Number ID**

---

### Paso 5 — Compartirme los datos de forma segura

Una vez tengas todo, compárteme por un canal seguro (no WhatsApp, no email):

```
META_ACCESS_TOKEN = el token generado en el Paso 3
WABA_ID          = el ID del Paso 4 (WABA)
PHONE_NUMBER_ID  = el ID del Paso 4 (teléfono)
```

Yo los agrego como variables de entorno en Vercel, igual que hicimos con
`DATABASE_URL` y `GOOGLE_PRIVATE_KEY`. Nunca van al código ni al repositorio.

---

## Qué aparecerá en el dashboard una vez conectado

- **Mensajes enviados / entregados / leídos / respondidos** por día
- **Tasa de lectura** — % de leads que abrieron el WhatsApp (hoy no lo sabemos)
- **Costo total** y **costo por lead** en USD
- Todo esto cruzado con los datos de conversión que ya tenemos

---

## Tiempo estimado de implementación

Una vez tengas el token y los IDs: **menos de 1 hora** de desarrollo.
El patrón es idéntico al que ya hicimos con Google Analytics 4.

---

*Documento generado el 23 jun 2026 · Proyecto Dashboard Qualitas / Hylant*
