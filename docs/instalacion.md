# Instalación

## Requisitos

- Linux (Debian/Ubuntu probado)
- Python 3.8 o superior
- Chromium y chromedriver instalados en `/usr/bin`

```bash
sudo apt install chromium-browser chromium-chromedriver
```

Las rutas del browser y del driver están fijas en `src/auth.py`, así que el
scraper no funciona en macOS ni con otras ubicaciones sin editar ese archivo.

## Desde el código fuente

```bash
git clone https://github.com/iaaaanb/ucursito.git
cd ucursito
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Edita `.env` con tus credenciales:

```env
UCURSOS_USERNAME=tu_usuario
UCURSOS_PASSWORD=tu_contraseña
UCURSOS_URL=https://www.u-cursos.cl
```

El `.env` está en `.gitignore`. No lo commitees.

Después:

```bash
python src/main.py --help
```

## Como paquete Debian

El repo trae el andamiaje para construir un `.deb` que instala en
`/opt/ucursito` y deja el comando `ucursito` disponible en todo el sistema.

### Construir

```bash
./build-deb.sh
```

El script arma la estructura en `debian/`, copia la aplicación a
`/opt/ucursito`, agrega los scripts de control y llama a `dpkg-deb`. Produce
`ucursito_0.2.0_all.deb` (~26 KB).

### Instalar

```bash
sudo apt install ./ucursito_0.2.0_all.deb
```

El paquete se construyó, instaló y desinstaló sobre Ubuntu 24.04 LTS.

Se usa `apt` en vez de `dpkg -i` para que las dependencias del sistema se
resuelvan solas. El `postinst` crea un virtualenv en `/opt/ucursito/venv` e
instala ahí las dependencias de Python: es la forma de esquivar PEP 668, que en
Ubuntu 24.04 y posteriores impide instalar paquetes con pip en el Python del
sistema.

### Primer uso

```bash
ucursito
```

La primera vez pide usuario y contraseña y los guarda en
`~/.config/ucursito/credentials`, en **texto plano** con permisos 600: los lee
solo tu usuario, pero no están cifrados. Es suficiente para uso personal en tu
propia máquina y no para más que eso. Para rehacerlos:
`ucursito --reset-credentials`.

### Desinstalar

```bash
sudo apt remove ucursito        # o purge
rm -rf ~/.config/ucursito/      # las credenciales no se borran solas
```

### Contenido del paquete

```
/opt/ucursito/
├── src/                    # los módulos de Python
├── docs/                   # esta documentación
├── config.py
├── requirements.txt
├── .env.example
├── README.md
└── ucursito                # wrapper que gestiona credenciales
/usr/local/bin/ucursito -> /opt/ucursito/ucursito
```

Para cambiar metadatos del paquete: `debian-template/DEBIAN/control`. Para lo
que pasa después de instalar: `debian-template/DEBIAN/postinst`.

## Problemas frecuentes

**El driver no arranca.** Verifica que existan `/usr/bin/chromium-browser` y
`/usr/bin/chromedriver`. Si tu distribución los instala en otra ruta, hay que
editarlas en `src/auth.py`.

**Falla el login.** Usa tu nombre de usuario de U-Cursos, no el correo. Corre
con `--no-headless` para ver qué está pasando en el browser. Si U-Cursos cambió
el formulario, los selectores de `src/auth.py` quedan obsoletos.

**Las descargas se quedan colgadas.** Los enlaces externos se saltan a
propósito. Prueba con `--no-headless` para ver en qué archivo se detiene.

**El `.ics` no se importa.** Revisa que exista y no esté vacío:
`ls -l downloads/calendar.ics`.
