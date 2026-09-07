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

## No revivir el login rodeando la detección de bots

**Problema.** En algún momento entre noviembre de 2025 y septiembre de 2026,
U-Cursos movió la autenticación a Cuenta Uchile: la portada dejó de tener
formulario y ahora abre un flujo OAuth2 en `oauth2.uchile.cl`, protegido con
Cloudflare Turnstile. El login por formulario de este proyecto quedó obsoleto de
un día para otro.

**Qué intenté.** Un login asistido, que parecía la salida limpia: abrir Chromium
con un perfil persistente, que la persona inicie sesión a mano una vez
—resolviendo el Turnstile ella misma—, y que las corridas siguientes reutilicen
esa sesión desde el perfil.

Dos hallazgos lo descartaron:

1. **Turnstile rechaza el browser, no al usuario.** Da lo mismo que el desafío
   lo resuelva una persona: lo que se detecta es que el browser está manejado
   por chromedriver. Falla igual con ventana visible que en headless.
2. **La sesión no sobrevive al cierre del browser.** Inspeccionando las cookies
   del perfil: `PHPSESSID` de `www.u-cursos.cl` no es persistente. Sí lo es
   `sl-session`, la del proveedor de identidad, pero reutilizarla exige rehacer
   el handshake OAuth2, que vuelve a pasar por Turnstile.

**Decisión.** No seguir. Existen formas de esquivar la detección
—undetected-chromedriver, binarios parcheados, enganchar Selenium a un Chrome
lanzado a mano por el puerto de depuración— y todas consisten en pasar por
encima de una medida que la universidad puso deliberadamente. No es una barrera
técnica que valga la pena vencer: es una respuesta a la pregunta de si el sitio
quiere ser automatizado.

**Qué haría falta si esto se retomara.** Que U-Cursos exponga una API o algún
mecanismo de acceso para terceros. Sin eso, cualquier versión que funcione se
sostiene sobre evadir el control anti-bots, y prefiero un proyecto que no corre
a uno que corre así.
