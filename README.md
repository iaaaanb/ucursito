# ucursito

CLI que descarga el material de tus ramos en U-Cursos y exporta los controles y
los plazos de tareas a un calendario `.ics`.

Cada semana hay que entrar ramo por ramo, revisar Material Docente y Novedades a
mano, bajar los PDF sueltos y anotar las fechas de control en alguna parte.
`ucursito` hace las dos cosas de una pasada: deja los archivos ordenados en
`Curso/Categoría/` y genera un calendario que puedes suscribir desde
Thunderbird, Google Calendar o Apple Calendar.

**Stack:** Python 3.8+ · Selenium sobre Chromium · icalendar · click · empaquetado `.deb`

## Instalación

```bash
git clone https://github.com/iaaaanb/ucursito.git
cd ucursito
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env      # completa UCURSOS_USERNAME y UCURSOS_PASSWORD
```

Requiere Linux con Chromium y chromedriver en `/usr/bin`. También se puede
construir e instalar como paquete Debian, que deja el comando `ucursito` en el
`PATH`: ver [docs/instalacion.md](docs/instalacion.md).

## Uso

```bash
python src/main.py                     # sincroniza todas las secciones
python src/main.py -m                  # solo material docente
python src/main.py -mt                 # material docente y tareas
python src/main.py -c                  # solo el calendario
python src/main.py --serve-calendar    # sirve el .ics para suscribirse
```

Los flags de sección se combinan: `-c` calendario, `-m` material docente, `-n`
novedades, `-t` tareas. `--course "Bases"` filtra por ramo, `--output` cambia el
destino y `--no-headless` muestra el browser.

## Estado y limitaciones

Herramienta de uso personal, escrita contra U-Cursos tal como estaba en el
semestre Primavera 2025. Vale la pena ser explícito sobre qué no cubre:

- **Depende del HTML de U-Cursos.** Todo el scraping son selectores CSS contra
  la estructura actual del sitio. Si cambia el markup, las secciones afectadas
  dejan de encontrar datos y hay que actualizar los selectores. Los más frágiles
  están listados en [docs/desarrollo.md](docs/desarrollo.md).
- **Solo Linux.** Por defecto busca Chromium y su driver en `/usr/bin`; con
  `CHROMIUM_PATH` y `CHROMEDRIVER_PATH` se apunta a otra ubicación, como la del
  snap. No hay valores por defecto para Windows ni macOS.
- **El filtro de enlaces externos no está verificado.** Las secciones Novedades y
  Tareas descartan los enlaces cuyo `href` es una URL absoluta, asumiendo que los
  archivos internos vienen con rutas relativas. No lo he comprobado contra el
  sitio real, y si Selenium resuelve esos `href` a absolutos, el filtro estaría
  descartando también archivos internos.
- **Sin tests automatizados.** La verificación fue manual, corriendo con
  `--no-headless` contra mi propia cuenta.
- **Las credenciales se guardan en texto plano** en
  `~/.config/ucursito/credentials` con permisos 600. Suficiente para uso
  personal en la propia máquina, no para nada más.

## Documentación

- [Decisiones de diseño](docs/decisiones.md)
- [Instalación y paquete `.deb`](docs/instalacion.md)
- [Calendario y suscripción](docs/calendario.md)
- [Desarrollo y organización de archivos](docs/desarrollo.md)

---

Proyecto personal, sin afiliación con U-Cursos ni la Universidad de Chile.
Licencia MIT.
