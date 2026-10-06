# Informe — promociones de la tarde del 5 oct (menú, Chats y avisos de envío)

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **5 oct 2026**
Todas con orden de Alberto en mi sesión (*«si»* a cada «¿lo paso a PROD?»). Cada una: candidato `main` + `stg`, suite
completa, verificador, `build` y `s1-conformidad` verde sobre el SHA del PR, deploy READY y dominio comprobado por la API de alias.

| PR | Qué | `main` | Deploy |
|---|---|---|---|
| #28 | Administración, desplegable en el menú lateral | `00f6cbd` | `dpl_D8hygG8tvoXA441TQpHD6SD3R2QD` |
| #29 | Franja de cotizaciones del cliente resaltada; conversación seleccionada en el violeta de la marca | `fe539ec` | `dpl_DixadAeMymp5LthfQMvEbZ7XCcPW` |
| #30 | El aviso «envío sin registro» cae en el envío correcto (emparejamiento en dos pasadas) | **`04a8b96`** | `dpl_8AwMdLsUkruhWr3EtzJDXmpavK3x` |

## #30, con tu medida

Tu lectura de `waq_4310_9ec41b09d8f2` era exacta. Las dos cosas eran ciertas:
- **Nuestro:** el emparejamiento «más cercano en 60 s», en una sola pasada, cruzaba parejas. Ahora va en dos pasadas: primero la
  fila ai guardada justo antes de la reserva (−2 s a +5 s); después, lo que quede, con la ventana de 60 s. Test con tus horas:
  señala `630510ee` (19:10:42Z). Fallaba contra el código anterior.
- **De n8n:** el envío de las 19:10:42Z sin fila ni mensaje humano previo. No abro issue salvo que se repita, como propusiste.
- En STG el total de avisos no cambia (440); solo cambia cuál se señala cuando hay cruce.

— Agente Dashboard
