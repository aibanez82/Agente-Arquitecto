# Funcionalidad: Extracción de datos desde Constancia de Situación Fiscal (CSF) por WhatsApp

## Contexto para el desarrollador

Este documento describe una mejora al flujo conversacional del agente de WhatsApp que actualmente recopila los datos del asegurado preguntando campo por campo (nombre, apellidos, dirección, código postal, etc.).

La mejora consiste en pedirle al cliente que suba su **Constancia de Situación Fiscal (CSF)** — un documento oficial emitido por el SAT (Servicio de Administración Tributaria), que es el equivalente mexicano de la DIAN colombiana. Con ese solo documento, el agente extrae automáticamente todos los datos necesarios para emitir la póliza.

---

## ¿Qué es la Constancia de Situación Fiscal (CSF)?

Es un documento oficial de 3 páginas emitido por el SAT (gobierno federal de México) que certifica la situación fiscal de una persona. Lo tiene cualquier persona física o moral registrada ante el SAT. Se descarga gratuitamente desde el portal del SAT con RFC y contraseña.

**Equivalente colombiano:** similar al RUT (Registro Único Tributario) de la DIAN.

El cliente lo puede tener como:
- PDF descargado del portal del SAT
- Imagen (foto o captura de pantalla del PDF)
- Puede llegar por WhatsApp en cualquiera de esos dos formatos

---

## Datos que contiene la CSF relevantes para la póliza

De la página 1 del documento se extraen todos los datos necesarios:

### Datos del asegurado

| Campo en la CSF | Etiqueta exacta en el documento | Ejemplo |
|---|---|---|
| RFC | `RFC:` | `EIAL9306254M1` |
| CURP | `CURP:` | `EIAL930625MDFSMR07` |
| Nombre(s) | `Nombre (s):` | `LORENA ALICIA` |
| Primer apellido | `Primer Apellido:` | `ESPINOSA` |
| Segundo apellido | `Segundo Apellido:` | `AMAYA` |

### Datos del domicilio

| Campo en la CSF | Etiqueta exacta en el documento | Ejemplo |
|---|---|---|
| Código postal | `Código Postal:` | `14210` |
| Tipo de vialidad | `Tipo de Vialidad:` | `CERRADA (CDA) O PRIVADA (PRIV)` |
| Nombre de la vialidad (calle) | `Nombre de Vialidad:` | `SIERRA DE SASLAYA` |
| Número exterior | `Número Exterior:` | `39` |
| Número interior | `Número Interior:` | *(puede estar vacío)* |
| Colonia | `Nombre de la Colonia:` | `JARDINES EN LA MONTAÑA` |
| Municipio / Alcaldía | `Nombre del Municipio o Demarcación Territorial:` | `TLALPAN` |
| Estado | `Nombre de la Entidad Federativa:` | `CIUDAD DE MEXICO` |

### Mapeo a campos de Django (`qualitas_asegurado`)

| Campo Django | Fuente en la CSF |
|---|---|
| `nombre` | `Nombre (s)` |
| `apellido_paterno` | `Primer Apellido` |
| `apellido_materno` | `Segundo Apellido` |
| `rfc` *(si existe el campo)* | `RFC` |
| `curp` *(si existe el campo)* | `CURP` |

Y el domicilio completo para el campo de dirección de la póliza.

---

## Flujo conversacional propuesto

El agente debe solicitar la CSF **después** de que el cliente confirme la modalidad de pago (momento actual: entre el `greeting` y el `data_capture`), reemplazando el bloque de preguntas manuales de datos personales.

```
Bot: "Para continuar con la emisión de tu póliza necesito algunos datos.
     Para hacerlo más rápido, ¿puedes compartirme tu Constancia de
     Situación Fiscal (CSF)?

     La puedes descargar en sat.gob.mx → 'Genera tu constancia de
     situación fiscal'. Es un PDF de 3 páginas con tu nombre y domicilio
     registrado ante el SAT.

     Si no la tienes a la mano, también puedo pedirte los datos uno por uno."
```

**Si el cliente sube el PDF o imagen:**
1. El agente extrae los campos listados arriba
2. Muestra un resumen para confirmación: "Con tu CSF obtuve estos datos: [resumen]. ¿Son correctos?"
3. Si el cliente confirma → avanza al siguiente bloque (datos del vehículo: placas, VIN)
4. Si hay error en algún campo → permite corregirlo manualmente

**Si el cliente no tiene la CSF:**
- El agente vuelve al flujo actual de preguntas campo por campo

---

## Implementación técnica recomendada

### Recepción del documento
WhatsApp Business API entrega el PDF/imagen como media. El agente (n8n) debe:
1. Descargar el archivo desde la URL de media de WhatsApp
2. Pasarlo a un modelo de visión o extractor de texto

### Extracción de datos

**Opción A — Claude API con visión (recomendada):**
```
Enviar el PDF/imagen a Claude claude-sonnet-4-6 con el siguiente prompt:

"Eres un extractor de datos de la Constancia de Situación Fiscal mexicana (CSF).
Extrae exactamente los siguientes campos y devuélvelos en JSON:
{
  'nombre': '',
  'apellido_paterno': '',
  'apellido_materno': '',
  'rfc': '',
  'curp': '',
  'codigo_postal': '',
  'tipo_vialidad': '',
  'nombre_vialidad': '',
  'numero_exterior': '',
  'numero_interior': '',
  'colonia': '',
  'municipio': '',
  'estado': ''
}
Si algún campo no aparece en el documento, devuelve null para ese campo.
Devuelve SOLO el JSON, sin texto adicional."
```

**Opción B — Extracción por texto (pdfplumber / pytesseract):**
- Extraer texto del PDF
- Buscar los patrones de etiquetas exactas (`RFC:`, `Nombre (s):`, etc.)
- Más frágil si el documento viene como imagen o foto

Se recomienda **Opción A** porque funciona tanto con PDF como con fotos del documento, y maneja variaciones de formato.

### Validación básica post-extracción
```python
# RFC mexicano: 4 letras + 6 dígitos (fecha) + 3 alfanuméricos
import re
RFC_PATTERN = r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$'

# CURP: 18 caracteres
CURP_PATTERN = r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$'
```

---

## Datos que la CSF NO reemplaza

Los siguientes datos siguen siendo necesarios preguntarlos por WhatsApp, ya que no están en la CSF:

| Dato | Por qué no está en la CSF |
|---|---|
| Fecha de nacimiento | Está codificada en el CURP (se puede derivar) |
| Género | Está codificado en el CURP (posición 11: H=Hombre, M=Mujer) |
| Número de INE | Documento distinto, no relacionado |
| Placas del vehículo | Dato del vehículo, no del asegurado |
| Número de serie (VIN) | Dato del vehículo, no del asegurado |
| ¿Requiere factura? | Preferencia del cliente |

> **Nota:** La fecha de nacimiento y el género se pueden derivar automáticamente del CURP sin preguntar al cliente. El CURP tiene el formato `XXXXAAMMDDHMMMCC#` donde:
> - Posiciones 5-10: fecha de nacimiento (AAMMDD)
> - Posición 11: sexo (H=Hombre, M=Mujer)

---

## Beneficios esperados

| Métrica | Antes | Después |
|---|---|---|
| Mensajes para capturar datos personales | ~8-12 mensajes | 1-2 mensajes |
| Errores de captura (apellidos mal escritos, CP incorrecto) | Frecuentes | Prácticamente nulos |
| Tiempo hasta `data_capture` completado | ~5-10 min | ~1-2 min |
| Tasa de abandono en bloque de datos personales | Por medir | Esperada reducción |

---

## Ejemplo de extracción esperada

**Documento de entrada:** CSF de Lorena Alicia Espinosa Amaya

**JSON de salida esperado:**
```json
{
  "nombre": "LORENA ALICIA",
  "apellido_paterno": "ESPINOSA",
  "apellido_materno": "AMAYA",
  "rfc": "EIAL9306254M1",
  "curp": "EIAL930625MDFSMR07",
  "fecha_nacimiento_derivada": "1993-06-25",
  "genero_derivado": "M",
  "codigo_postal": "14210",
  "tipo_vialidad": "CERRADA",
  "nombre_vialidad": "SIERRA DE SASLAYA",
  "numero_exterior": "39",
  "numero_interior": null,
  "colonia": "JARDINES EN LA MONTAÑA",
  "municipio": "TLALPAN",
  "estado": "CIUDAD DE MEXICO"
}
```

---

*Documento generado el 22 jun 2026 · Proyecto: Dashboard Leads Qualitas / Hylant*
*Documento de ejemplo utilizado: CSF real anonimizada (SAT México, marzo 2025)*
