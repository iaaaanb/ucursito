# Decisiones de diseño

Notas sobre los cuatro problemas que costaron más y cómo terminaron resueltos.

## Puentear la sesión de Selenium hacia `requests`

**Problema.** U-Cursos abre buena parte de los PDF dentro de un visor lightbox
en JavaScript. Hacer clic no dispara una descarga: monta un visor en la página.
Bajar el archivo requiere pedir la URL directa, pero esa URL está detrás de la
sesión autenticada, y la sesión vive dentro del browser que maneja Selenium.

**Decisión.** `download_file` (`src/scraper.py`) usa dos estrategias según el
archivo. Los que descargan normal se dejan al browser y después se mueven a su
carpeta definitiva. Para los del lightbox se extraen las cookies del driver con
`driver.get_cookies()`, se cargan en una `requests.Session` y se pide la URL
directamente por HTTP, sin pasar por el visor.

**Por qué así.** La alternativa era automatizar el visor —esperar a que monte,
buscar el botón de descarga, manejar su iframe— lo que es más frágil y más
lento. Copiar las cookies convierte un problema de automatización de UI en una
descarga HTTP común, que además permite escribir el archivo en streaming.

## Configurar las descargas por CDP en vez de por preferencias

**Problema.** El directorio de descarga de Chromium se configura con
preferencias al crear el driver. En modo headless esas preferencias no se
respetan y los archivos terminan donde el browser quiera, o no se descargan.

**Decisión.** `get_driver` (`src/auth.py`) registra el comando
`chromium/send_command` en el executor de Selenium y llama al método
`Page.setDownloadBehavior` del Chrome DevTools Protocol, que sí funciona en
headless. Lo mismo se repite en `download_files` (`src/scraper.py`) para apuntar
al directorio temporal de cada corrida.

**Por qué así.** La opción era renunciar al modo headless. Como la herramienta
está pensada para correr desatendida, headless no era negociable.

## Parsear tablas cuya jerarquía está en filas, no en anidamiento

**Problema.** Las tablas de U-Cursos agrupan por categoría, pero no anidan: la
categoría es una fila `tr.separador[data-categoria]` y todo lo que viene después
le pertenece, hasta el siguiente separador. No hay contenedor que recorrer.

**Decisión.** Recorrer los `tbody` en orden manteniendo una variable con la
categoría actual: cuando la fila es un separador se actualiza esa variable, y
cuando es una fila de datos se le asigna el valor vigente. Si aparecen archivos
antes de cualquier separador, caen en `Otros`.

**Por qué así.** Es el mismo patrón aplicado a las tres tablas del sitio
—Material Docente, Tareas y Calendario— y significa que agregar una sección
nueva es reusar el recorrido en vez de escribir un parser distinto.

## Usar el `.ics` anterior como caché de la próxima corrida

**Problema.** Para leer los plazos de una tarea hay que entrar a su página
individual. Con varios ramos son decenas de navegaciones por sincronización, la
mayoría sobre tareas que ya se procesaron y que no van a cambiar.

**Decisión.** Antes de recorrer las tareas se lee el `calendar.ics` generado en
la corrida anterior y se arma el conjunto de las que ya están registradas,
filtrando por el prefijo del UID (`tarea-<código de ramo>-`). Esas se saltan.
Si el archivo no existe o no se puede parsear, se sigue como si no hubiera
caché.

**Por qué así.** El output ya contenía exactamente la información necesaria, así
que no hacía falta un archivo de estado aparte que mantener sincronizado. El
costo es que el "caché" queda acoplado al formato de los UIDs, razón por la que
esos prefijos se conservaron al hacerlos deterministas.

**Detalle relacionado.** Los UID se construyen con un hash estable de (ramo,
tipo, título, timestamp). La primera versión usaba `hash()` de Python, que está
aleatorizado por proceso desde 3.3: cada corrida producía UIDs distintos, así
que reimportar el calendario duplicaba todos los eventos en vez de
actualizarlos.
