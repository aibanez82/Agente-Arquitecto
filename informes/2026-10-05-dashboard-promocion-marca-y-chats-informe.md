# Informe — marca InsurMind y Chats sin duplicados, en PROD

**De:** Agente Dashboard · **Para:** Arquitecto-IA-Quálitas · **5 oct 2026**
**Aprobado por Alberto en mi sesión, literal:** *«1. Marca InsurMind: aprobada, adelante. 2. Un descuento, una fila en Chats (el HONDA): OK»* y *«el 3 tambien OK»*.

| | |
|---|---|
| PR | **#27** (`promocion/marca-cadenas-y-clientes` = `5414531`, `main` + merge de `stg` = `434bd3f`) |
| `main` | `8d6aa83` → **`28e41e5`**; deploy `dpl_4HjNu1218hkmeXG1Reo5Pd7i5Mfi` **READY**, dominio apuntando a él |
| Gates | **808/808**, verificador y `build`; `s1-conformidad` verde sobre `5414531` (run 37400955976) |

## Qué entra (22 ficheros, nada del #495)

1. **Marca InsurMind** (`aaf3b8b`), a partir de la maqueta de Juan: menú lateral con solo las vistas del Dashboard, token `--brand`
   (`#5344DF`) para el chrome, DM Sans, favicon «M» y login. `--qpurple` queda solo para «Póliza emitida». `DESIGN.md` actualizado.
   **En vivo:** el login de PROD ya sirve DM Sans y la marca.
2. **Una cadena de descuento, una fila** (`be994c9`): el lead `continued` no sale si su hoja está en la lista, salvo toma activa o
   enlace directo. Es tu caso HONDA (2865 → 2866). En STG, la bandeja pasa de 157 a 108 filas.
3. **Una fila por cliente** (`d68f773`): se agrupa por teléfono (últimos 10 dígitos) después de filtrar, con «🗂 N cotizaciones» y un
   selector en la conversación. **No se oculta ningún lead** y las tomas siguen siendo por lead. Es tu caso VW (4 leads, 2 tomas).
   En PROD los leads internos se excluyen antes de agrupar.

## Sin ver

Nada de esto lo he visto pintado: sin navegador conectado. Lo tiene que mirar Alberto.

— Agente Dashboard
