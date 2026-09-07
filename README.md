# ucursito

CLI que descarga el material de tus ramos en U-Cursos y exporta los controles y
los plazos de tareas a un calendario `.ics`.

Cada semana hay que entrar ramo por ramo, revisar Material Docente y Novedades a
mano, bajar los PDF sueltos y anotar las fechas de control en alguna parte.
`ucursito` hace las dos cosas de una pasada: deja los archivos ordenados en
`Curso/Categoría/` y genera un calendario que puedes suscribir desde
Thunderbird, Google Calendar o Apple Calendar.

> **El login dejó de funcionar** desde que U-Cursos migró la autenticación a
> Cuenta Uchile. Lee [Estado y limitaciones](#estado-y-limitaciones) antes de
> instalar nada.

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

Herramienta de uso personal, escrita y usada durante el semestre Primavera 2025.

**El login ya no funciona.** Comprobado el 6 de septiembre de 2026: U-Cursos
migró la autenticación a Cuenta Uchile, el portal ya no expone un formulario de
usuario y contraseña, y el flujo pasa por OAuth2 en `oauth2.uchile.cl` detrás de
Cloudflare Turnstile. El login por formulario de `src/auth.py` corresponde al
sitio anterior y hoy termina en timeout.

Intenté revivirlo con un login asistido —abrir el browser, iniciar sesión a
mano, reutilizar la sesión desde un perfil persistente— y **no funciona**, por
dos razones que comprobé: Turnstile rechaza el browser aunque el desafío lo
resuelva una persona, porque lo que detecta es el browser automatizado y no al
usuario; y la cookie de sesión de U-Cursos (`PHPSESSID`) no es persistente, así
que aunque se pasara, la sesión moriría al cerrar el browser y habría que
repetir el trámite en cada corrida.

Rodear esa detección es posible, y no es el camino: es la medida
antiautomatización que la universidad puso a propósito. El detalle está en
[docs/decisiones.md](docs/decisiones.md).

Lo demás sigue en pie como descripción de lo que hace el código:

- **Depende del HTML de U-Cursos.** Todo el scraping son selectores CSS contra
  la estructura del sitio. El login fue el primero en romperse; el resto de las
  secciones no las he podido volver a verificar desde entonces. Los selectores
  más frágiles están listados en [docs/desarrollo.md](docs/desarrollo.md).
- **Solo Linux.** Por defecto busca Chromium y su driver en `/usr/bin`; con
  `CHROMIUM_PATH` y `CHROMEDRIVER_PATH` se apunta a otra ubicación, como la del
  snap. No hay valores por defecto para Windows ni macOS.
- **El filtro de enlaces externos no está verificado.** Las secciones Novedades y
  Tareas descartan los enlaces cuyo `href` es una URL absoluta, asumiendo que los
  archivos internos vienen con rutas relativas. No lo he comprobado contra el
  sitio real, y si Selenium resuelve esos `href` a absolutos, el filtro estaría
  descartando también archivos internos.
- **Sin tests automatizados.** La verificación fue manual, corriendo con
  `--no-headless` contra mi propia cuenta mientras el login funcionaba.
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
