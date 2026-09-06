# Desarrollo

## Estructura

```
src/
├── main.py              # CLI (click): flags, orquestación
├── auth.py              # login con Selenium, configuración del driver
├── scraper.py           # scraping y descarga de las cuatro secciones
├── calendar_export.py   # construcción del .ics
└── calendar_server.py   # servidor HTTP para suscripción
config.py                # abreviaciones de ramo y directorio por defecto
ucursito                 # wrapper: gestiona credenciales y llama a main.py
build-deb.sh             # construcción del paquete Debian
debian-template/         # control, postinst, prerm
```

## Cómo se organizan las descargas

```
downloads/
├── Batos/                        # nombre abreviado si está en config.py
│   ├── Cátedras/                 # categoría según la barra separadora
│   │   ├── clase-01.pdf
│   │   └── clase-02.pdf
│   └── Auxiliares/
│       └── aux-01.pdf
└── PSS/
    └── Cátedras/                 # novedades: una carpeta por publicación
        └── unix-exec/
            ├── unix-exec.pdf
            └── exec.zip
```

Las categorías salen de las barras separadoras de cada tabla de U-Cursos. Si un
archivo no cae bajo ninguna, queda en `Otros`. Los espacios de los nombres se
convierten en guiones y los caracteres inválidos en `_`
(`sanitize_filename`, `src/scraper.py`).

En Novedades, cada PDF genera una carpeta con su propio nombre, y si viene un
ZIP inmediatamente después en la misma publicación, se guarda ahí junto al PDF.

Los archivos que ya existen en disco no se vuelven a descargar. Para las tareas
hay un segundo atajo: antes de visitar cada una se lee el `calendar.ics` de la
corrida anterior y se saltan las que ya están registradas.

## Correr en desarrollo

```bash
python src/main.py --no-headless        # con el browser a la vista
python src/main.py -n --no-headless     # depurar solo novedades
```

`--no-headless` es la herramienta de depuración principal: casi todos los
problemas de este scraper son selectores que dejaron de calzar con el HTML, y
eso se ve más rápido mirando la página que leyendo el traceback.

## Abreviaciones de ramo

`COURSE_ABBREVIATIONS` en `config.py` mapea el nombre completo de un ramo a un
nombre corto para los títulos del calendario. Es un mapeo personal y opcional:
el ramo que no esté en el diccionario usa su nombre completo.

## Si U-Cursos cambia

El scraper depende de selectores CSS concretos. Los que se rompen primero:

- `li[id^="curso."]` dentro de `div#cursos` — la lista de ramos (`auth.py`, `scraper.py`)
- `tr.separador[data-categoria]` — las categorías de cada tabla
- `table#materiales`, `table#tarea` — las tablas de material y de tarea
- `span.tiempo_rel[data-time]` — los timestamps de los plazos
- `div.post.objeto` y `ul.paginas` — publicaciones y paginación en novedades
